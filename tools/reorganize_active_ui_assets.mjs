#!/usr/bin/env node

/**
 * Move the currently referenced runtime UI assets into the approved
 * interfaces/components/shared taxonomy.
 *
 * The move map is the human-auditable source of truth. This script is a dry
 * run unless --apply is passed. It moves PNG import sidecars together with
 * their images, rewrites exact res:// references, and rolls back on failure.
 */

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const EXPECTED_ROWS = 235;
const PROJECT_ROOT = process.cwd();
const APPLY = process.argv.includes("--apply");
const MAP_PATH = path.join(
  PROJECT_ROOT,
  "docs/assets/ui_runtime_asset_move_map_2026-08-20.csv",
);
const REPORT_PATH = path.join(
  PROJECT_ROOT,
  "docs/assets/ui_runtime_asset_reorganization_report_2026-08-20.json",
);

function fail(message) {
  throw new Error(message);
}

function normalizeRelative(value) {
  return String(value ?? "")
    .trim()
    .replace(/^\uFEFF/, "")
    .replaceAll("\\", "/")
    .replace(/^\.\//, "");
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = "";
  let quoted = false;
  for (let index = 0; index < text.length; index += 1) {
    const char = text[index];
    if (quoted) {
      if (char === '"' && text[index + 1] === '"') {
        field += '"';
        index += 1;
      } else if (char === '"') {
        quoted = false;
      } else {
        field += char;
      }
      continue;
    }
    if (char === '"') {
      quoted = true;
    } else if (char === ",") {
      row.push(field);
      field = "";
    } else if (char === "\n") {
      row.push(field.replace(/\r$/, ""));
      rows.push(row);
      row = [];
      field = "";
    } else {
      field += char;
    }
  }
  if (quoted) fail("Move-map CSV contains an unterminated quoted field.");
  if (field.length > 0 || row.length > 0) {
    row.push(field.replace(/\r$/, ""));
    rows.push(row);
  }
  return rows.filter((columns) => columns.some((value) => value !== ""));
}

function loadMoveMap() {
  if (!fs.existsSync(MAP_PATH)) fail(`Move map is missing: ${MAP_PATH}`);
  const table = parseCsv(fs.readFileSync(MAP_PATH, "utf8"));
  if (table.length < 2) fail("Move-map CSV has no data rows.");
  const headers = table[0].map((value) => value.replace(/^\uFEFF/, "").trim());
  const oldIndex = headers.indexOf("old_path");
  const newIndex = headers.indexOf("new_path");
  if (oldIndex < 0 || newIndex < 0) {
    fail("Move-map CSV must contain old_path and new_path columns.");
  }
  const rows = table.slice(1).map((columns, index) => {
    const details = Object.fromEntries(
      headers.map((header, columnIndex) => [header, columns[columnIndex] ?? ""]),
    );
    return {
      rowNumber: index + 2,
      oldPath: normalizeRelative(columns[oldIndex]),
      newPath: normalizeRelative(columns[newIndex]),
      details,
    };
  });
  if (rows.length !== EXPECTED_ROWS) {
    fail(`Expected ${EXPECTED_ROWS} move rows, found ${rows.length}.`);
  }
  return rows;
}

function absolute(relativePath) {
  const resolved = path.resolve(PROJECT_ROOT, relativePath);
  const rootWithSeparator = PROJECT_ROOT.endsWith(path.sep)
    ? PROJECT_ROOT
    : `${PROJECT_ROOT}${path.sep}`;
  if (resolved !== PROJECT_ROOT && !resolved.startsWith(rootWithSeparator)) {
    fail(`Path escapes project root: ${relativePath}`);
  }
  return resolved;
}

function sha256(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function listFiles(rootPath) {
  if (!fs.existsSync(rootPath)) return [];
  const output = [];
  const stack = [rootPath];
  while (stack.length > 0) {
    const current = stack.pop();
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const fullPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        if ([".git", ".godot", "build", "builds", "library", "temp", ".tmp"].includes(entry.name)) {
          continue;
        }
        stack.push(fullPath);
      } else if (entry.isFile()) {
        output.push(fullPath);
      }
    }
  }
  return output;
}

function validateRows(rows) {
  const oldPaths = new Set();
  const newPaths = new Set();
  const hashes = [];
  for (const row of rows) {
    if (!row.oldPath.startsWith("assets/runtime/")) {
      fail(`Row ${row.rowNumber}: old_path is outside assets/runtime: ${row.oldPath}`);
    }
    if (!/^assets\/runtime\/ui\/(interfaces|components|shared)\//.test(row.newPath)) {
      fail(`Row ${row.rowNumber}: new_path is outside the approved UI taxonomy: ${row.newPath}`);
    }
    if (row.oldPath === row.newPath) {
      fail(`Row ${row.rowNumber}: source and destination are identical.`);
    }
    if (oldPaths.has(row.oldPath)) fail(`Duplicate old_path: ${row.oldPath}`);
    if (newPaths.has(row.newPath)) fail(`Duplicate new_path: ${row.newPath}`);
    oldPaths.add(row.oldPath);
    newPaths.add(row.newPath);

    const oldAbsolute = absolute(row.oldPath);
    const newAbsolute = absolute(row.newPath);
    if (!fs.existsSync(oldAbsolute)) fail(`Missing source: ${row.oldPath}`);
    if (!fs.statSync(oldAbsolute).isFile()) fail(`Source is not a file: ${row.oldPath}`);
    if (fs.existsSync(newAbsolute)) fail(`Destination already exists: ${row.newPath}`);
    if (row.oldPath.toLowerCase().endsWith(".png")) {
      const importPath = `${oldAbsolute}.import`;
      if (!fs.existsSync(importPath)) fail(`PNG import sidecar is missing: ${row.oldPath}.import`);
    }
    hashes.push({ old_path: row.oldPath, new_path: row.newPath, sha256: sha256(oldAbsolute) });
  }
  return hashes;
}

function candidateTextFiles() {
  const directFiles = [path.join(PROJECT_ROOT, "project.godot")];
  const roots = ["scripts", "scenes", "tests", "tools", "assets/runtime/ui", "art/production"]
    .map((relativePath) => path.join(PROJECT_ROOT, relativePath));
  const allowed = new Set([
    ".gd", ".tscn", ".tres", ".gdshader", ".godot", ".ps1", ".py",
    ".mjs", ".json", ".md", ".csv", ".import",
  ]);
  return [...new Set([
    ...directFiles.filter((filePath) => fs.existsSync(filePath)),
    ...roots.flatMap(listFiles).filter((filePath) => allowed.has(path.extname(filePath).toLowerCase())),
  ])];
}

function rewriteExactReferences(rows) {
  const replacements = rows
    .map((row) => [`res://${row.oldPath}`, `res://${row.newPath}`])
    .sort((left, right) => right[0].length - left[0].length);
  const changed = [];
  for (const filePath of candidateTextFiles()) {
    let before;
    try {
      before = fs.readFileSync(filePath, "utf8");
    } catch {
      continue;
    }
    let after = before;
    let replacementCount = 0;
    for (const [from, to] of replacements) {
      if (!after.includes(from)) continue;
      const parts = after.split(from);
      replacementCount += parts.length - 1;
      after = parts.join(to);
    }
    if (after === before) continue;
    fs.writeFileSync(filePath, after, "utf8");
    changed.push({ filePath, before, replacementCount });
  }
  return changed;
}

function removeEmptyParents(startPath, stopPath) {
  let current = startPath;
  const stop = path.resolve(stopPath);
  while (current.startsWith(stop) && current !== stop && fs.existsSync(current)) {
    if (fs.readdirSync(current).length > 0) break;
    fs.rmdirSync(current);
    current = path.dirname(current);
  }
}

function execute(rows, hashes) {
  const moved = [];
  const changedTextFiles = [];
  try {
    for (const row of rows) {
      const oldAbsolute = absolute(row.oldPath);
      const newAbsolute = absolute(row.newPath);
      fs.mkdirSync(path.dirname(newAbsolute), { recursive: true });
      fs.renameSync(oldAbsolute, newAbsolute);
      moved.push({ from: oldAbsolute, to: newAbsolute });
      if (row.oldPath.toLowerCase().endsWith(".png")) {
        fs.renameSync(`${oldAbsolute}.import`, `${newAbsolute}.import`);
        moved.push({ from: `${oldAbsolute}.import`, to: `${newAbsolute}.import` });
      }
    }

    changedTextFiles.push(...rewriteExactReferences(rows));

    // Binary art must be byte-identical after a path-only reorganization.
    // AtlasTexture TRES files legitimately change because their ext_resource
    // path is rewritten to the relocated atlas sheet.
    for (const item of hashes.filter((entry) => entry.new_path.endsWith(".png"))) {
      const newAbsolute = absolute(item.new_path);
      const after = sha256(newAbsolute);
      if (after !== item.sha256) fail(`Hash changed during move: ${item.new_path}`);
    }

    for (const row of rows) {
      removeEmptyParents(path.dirname(absolute(row.oldPath)), path.join(PROJECT_ROOT, "assets/runtime"));
    }
  } catch (error) {
    for (const changed of changedTextFiles.reverse()) {
      fs.writeFileSync(changed.filePath, changed.before, "utf8");
    }
    for (const item of moved.reverse()) {
      if (!fs.existsSync(item.to)) continue;
      fs.mkdirSync(path.dirname(item.from), { recursive: true });
      fs.renameSync(item.to, item.from);
    }
    throw error;
  }
  return changedTextFiles.map((entry) => ({
    path: path.relative(PROJECT_ROOT, entry.filePath).replaceAll("\\", "/"),
    replacements: entry.replacementCount,
  }));
}

function summarize(rows) {
  const byOwnership = {};
  const byDestination = {};
  for (const row of rows) {
    const ownership = row.details.ownership_type || row.newPath.split("/")[3];
    const destination = row.details.interface_or_component || row.newPath.split("/")[4];
    byOwnership[ownership] = (byOwnership[ownership] ?? 0) + 1;
    byDestination[destination] = (byDestination[destination] ?? 0) + 1;
  }
  return { byOwnership, byDestination };
}

function main() {
  if (!fs.existsSync(path.join(PROJECT_ROOT, "project.godot"))) {
    fail("Run this script from the Godot project root.");
  }
  const rows = loadMoveMap();
  const hashes = validateRows(rows);
  const summary = summarize(rows);
  if (!APPLY) {
    console.log(JSON.stringify({ mode: "dry-run", rows: rows.length, ...summary }, null, 2));
    console.log("Dry run passed. Re-run with --apply to perform the migration.");
    return;
  }

  const rewrittenFiles = execute(rows, hashes);
  const report = {
    generated_at: new Date().toISOString(),
    mode: "applied",
    moved_resources: rows.length,
    moved_png_import_sidecars: rows.filter((row) => row.oldPath.endsWith(".png")).length,
    rewritten_files: rewrittenFiles,
    ...summary,
    resources: hashes,
  };
  fs.writeFileSync(REPORT_PATH, `${JSON.stringify(report, null, 2)}\n`, "utf8");
  console.log(JSON.stringify({
    mode: report.mode,
    moved_resources: report.moved_resources,
    moved_png_import_sidecars: report.moved_png_import_sidecars,
    rewritten_file_count: report.rewritten_files.length,
    ...summary,
    report: path.relative(PROJECT_ROOT, REPORT_PATH).replaceAll("\\", "/"),
  }, null, 2));
}

try {
  main();
} catch (error) {
  console.error(`[ui-reorganize] ${error.message}`);
  process.exitCode = 1;
}
