#!/usr/bin/env node

/**
 * Read-only validator for the 2026-08-20 UI runtime asset reorganization.
 *
 * The move map is the contract. This script never creates, moves, imports, or
 * rewrites project files; it only verifies the post-migration filesystem and
 * textual reference graph.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(SCRIPT_DIR, "..");
const MOVE_MAP_RELATIVE = "docs/assets/ui_runtime_asset_move_map_2026-08-20.csv";
const MOVE_MAP_PATH = path.join(PROJECT_ROOT, ...MOVE_MAP_RELATIVE.split("/"));
const EXPECTED_ASSET_COUNT = 235;
const EXPECTED_EXTENSION_COUNTS = new Map([
  [".png", 163],
  [".tres", 72],
]);
const DETAIL_LIMIT_PER_CHECK = 80;

const TEXT_EXTENSIONS = new Set([
  ".cfg",
  ".gd",
  ".gdshader",
  ".godot",
  ".json",
  ".mjs",
  ".js",
  ".ps1",
  ".py",
  ".tscn",
  ".tres",
]);

const issues = [];
const warnings = [];


function toPosix(value) {
  return value.replaceAll("\\", "/");
}


function stripResourcePrefix(value) {
  let result = String(value ?? "").replace(/^\uFEFF/, "").trim();
  if (result.toLowerCase().startsWith("res://")) result = result.slice(6);
  while (result.startsWith("./")) result = result.slice(2);
  return toPosix(result).replace(/^\/+/, "");
}


function pathKey(value) {
  return stripResourcePrefix(value).normalize("NFC").toLowerCase();
}


function projectAbsolute(relativePath, label) {
  const normalized = stripResourcePrefix(relativePath);
  if (!normalized || path.isAbsolute(normalized) || normalized.split("/").includes("..")) {
    throw new Error(`${label} is not a safe project-relative path: ${relativePath}`);
  }
  const absolute = path.resolve(PROJECT_ROOT, ...normalized.split("/"));
  const rootWithSeparator = `${PROJECT_ROOT}${path.sep}`;
  if (absolute !== PROJECT_ROOT && !absolute.startsWith(rootWithSeparator)) {
    throw new Error(`${label} resolves outside the project: ${relativePath}`);
  }
  return absolute;
}


function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = "";
  let quoted = false;

  const source = text.replace(/^\uFEFF/, "");
  for (let index = 0; index < source.length; index += 1) {
    const character = source[index];
    if (quoted) {
      if (character === '"') {
        if (source[index + 1] === '"') {
          field += '"';
          index += 1;
        } else {
          quoted = false;
        }
      } else {
        field += character;
      }
      continue;
    }

    if (character === '"') {
      quoted = true;
    } else if (character === ",") {
      row.push(field);
      field = "";
    } else if (character === "\n") {
      row.push(field.replace(/\r$/, ""));
      rows.push(row);
      row = [];
      field = "";
    } else {
      field += character;
    }
  }

  if (quoted) throw new Error("Move-map CSV ends inside a quoted field.");
  if (field.length > 0 || row.length > 0) {
    row.push(field.replace(/\r$/, ""));
    rows.push(row);
  }
  return rows.filter((values) => values.some((value) => value.trim() !== ""));
}


function normalizedHeader(value) {
  return String(value ?? "")
    .replace(/^\uFEFF/, "")
    .trim()
    .toLowerCase()
    .replaceAll(" ", "_")
    .replaceAll("-", "_");
}


function findHeaderIndex(headers, kind) {
  const normalized = headers.map(normalizedHeader);
  const exactCandidates = kind === "old"
    ? ["old_path", "old_relative_path", "source_path", "原路径", "旧路径", "迁移前路径"]
    : ["new_path", "new_relative_path", "target_path", "新路径", "目标路径", "迁移后路径"];

  for (const candidate of exactCandidates) {
    const index = normalized.indexOf(candidate);
    if (index >= 0) return index;
  }

  const englishNeedle = kind === "old" ? "old_path" : "new_path";
  const bilingualNeedle = kind === "old" ? /(^|[/_])(old|旧|原|迁移前).*path|路径.*(old|旧|原|迁移前)/i : /(^|[/_])(new|新|目标|迁移后).*path|路径.*(new|新|目标|迁移后)/i;
  return normalized.findIndex((header) => header.includes(englishNeedle) || bilingualNeedle.test(header));
}


function readMoveMap() {
  if (!fs.existsSync(MOVE_MAP_PATH)) {
    throw new Error(`Move map not found: ${MOVE_MAP_RELATIVE}`);
  }
  const parsed = parseCsv(fs.readFileSync(MOVE_MAP_PATH, "utf8"));
  if (parsed.length < 2) throw new Error("Move-map CSV has no data rows.");

  const headers = parsed[0].map((header) => header.trim());
  const oldIndex = findHeaderIndex(headers, "old");
  const newIndex = findHeaderIndex(headers, "new");
  if (oldIndex < 0 || newIndex < 0) {
    throw new Error(`Move-map CSV must contain old_path and new_path columns. Headers: ${headers.join(", ")}`);
  }

  return parsed.slice(1).map((values, index) => ({
    rowNumber: index + 2,
    oldPath: stripResourcePrefix(values[oldIndex]),
    newPath: stripResourcePrefix(values[newIndex]),
  }));
}


function addIssue(check, message) {
  issues.push({ check, message });
}


function addWarning(check, message) {
  warnings.push({ check, message });
}


function validateRows(rows) {
  if (rows.length !== EXPECTED_ASSET_COUNT) {
    addIssue("MOVE_MAP_COUNT", `Expected ${EXPECTED_ASSET_COUNT} rows, found ${rows.length}.`);
  }

  const oldPaths = new Map();
  const newPaths = new Map();
  for (const row of rows) {
    if (!row.oldPath) addIssue("MOVE_MAP_ROW", `Row ${row.rowNumber}: old_path is empty.`);
    if (!row.newPath) addIssue("MOVE_MAP_ROW", `Row ${row.rowNumber}: new_path is empty.`);
    if (!row.oldPath || !row.newPath) continue;

    try {
      projectAbsolute(row.oldPath, `Row ${row.rowNumber} old_path`);
      projectAbsolute(row.newPath, `Row ${row.rowNumber} new_path`);
    } catch (error) {
      addIssue("MOVE_MAP_ROW", error.message);
      continue;
    }

    const oldKey = pathKey(row.oldPath);
    const newKey = pathKey(row.newPath);
    if (oldKey === newKey) {
      addIssue("UNCHANGED_TARGET", `Row ${row.rowNumber}: old_path and new_path are the same: ${row.oldPath}`);
    }
    if (oldPaths.has(oldKey)) {
      addIssue("DUPLICATE_SOURCE", `Rows ${oldPaths.get(oldKey)} and ${row.rowNumber} share old_path: ${row.oldPath}`);
    } else {
      oldPaths.set(oldKey, row.rowNumber);
    }
    if (newPaths.has(newKey)) {
      addIssue("DUPLICATE_TARGET", `Rows ${newPaths.get(newKey)} and ${row.rowNumber} share new_path: ${row.newPath}`);
    } else {
      newPaths.set(newKey, row.rowNumber);
    }
  }
}


function validateFilesystem(rows) {
  let newFilesPresent = 0;
  let oldFilesAbsent = 0;
  let pngImportsValid = 0;
  let tresFilesValid = 0;
  let tresDependenciesChecked = 0;

  for (const row of rows) {
    if (!row.oldPath || !row.newPath) continue;

    let oldAbsolute;
    let newAbsolute;
    try {
      oldAbsolute = projectAbsolute(row.oldPath, `Row ${row.rowNumber} old_path`);
      newAbsolute = projectAbsolute(row.newPath, `Row ${row.rowNumber} new_path`);
    } catch {
      continue;
    }

    if (!fs.existsSync(newAbsolute)) {
      addIssue("NEW_PATH_MISSING", `Row ${row.rowNumber}: ${row.newPath}`);
    } else if (!fs.statSync(newAbsolute).isFile()) {
      addIssue("NEW_PATH_NOT_FILE", `Row ${row.rowNumber}: ${row.newPath}`);
    } else {
      newFilesPresent += 1;
    }

    if (fs.existsSync(oldAbsolute)) {
      addIssue("OLD_PATH_STILL_EXISTS", `Row ${row.rowNumber}: ${row.oldPath}`);
    } else {
      oldFilesAbsent += 1;
    }

    const extension = path.posix.extname(row.newPath).toLowerCase();
    if (extension === ".png") {
      const importAbsolute = `${newAbsolute}.import`;
      if (!fs.existsSync(importAbsolute)) {
        addIssue("PNG_IMPORT_MISSING", `Row ${row.rowNumber}: ${row.newPath}.import`);
      } else if (!fs.statSync(importAbsolute).isFile()) {
        addIssue("PNG_IMPORT_NOT_FILE", `Row ${row.rowNumber}: ${row.newPath}.import`);
      } else {
        const importText = fs.readFileSync(importAbsolute, "utf8");
        const sourceMatch = importText.match(/^\s*source_file\s*=\s*"([^"]+)"\s*$/m);
        const expectedSource = `res://${row.newPath}`;
        if (!sourceMatch) {
          addIssue("PNG_IMPORT_SOURCE_MISSING", `Row ${row.rowNumber}: ${row.newPath}.import has no source_file.`);
        } else if (pathKey(sourceMatch[1]) !== pathKey(expectedSource)) {
          addIssue(
            "PNG_IMPORT_SOURCE_MISMATCH",
            `Row ${row.rowNumber}: ${row.newPath}.import source_file=${sourceMatch[1]}, expected ${expectedSource}`,
          );
        } else {
          pngImportsValid += 1;
        }
      }

      const oldImportAbsolute = `${oldAbsolute}.import`;
      if (fs.existsSync(oldImportAbsolute)) {
        addIssue("OLD_IMPORT_STILL_EXISTS", `Row ${row.rowNumber}: ${row.oldPath}.import`);
      }
    }

    if (extension === ".tres" && fs.existsSync(newAbsolute) && fs.statSync(newAbsolute).isFile()) {
      const tresText = fs.readFileSync(newAbsolute, "utf8");
      const blocks = [...tresText.matchAll(/\[ext_resource\b([^\]]*)\]/g)];
      const dependencyPaths = [];
      for (const block of blocks) {
        const pathMatch = block[1].match(/\bpath\s*=\s*"([^"]+)"/);
        if (pathMatch) dependencyPaths.push(pathMatch[1]);
      }
      if (dependencyPaths.length === 0) {
        addIssue("TRES_EXT_RESOURCE_MISSING", `Row ${row.rowNumber}: ${row.newPath} has no ext_resource path.`);
        continue;
      }

      let dependenciesValid = true;
      for (const dependency of dependencyPaths) {
        if (!dependency.toLowerCase().startsWith("res://")) {
          dependenciesValid = false;
          addIssue("TRES_EXT_RESOURCE_INVALID", `${row.newPath}: non-project dependency ${dependency}`);
          continue;
        }
        try {
          const dependencyRelative = stripResourcePrefix(dependency);
          const dependencyAbsolute = projectAbsolute(dependencyRelative, `${row.newPath} ext_resource`);
          if (!fs.existsSync(dependencyAbsolute) || !fs.statSync(dependencyAbsolute).isFile()) {
            dependenciesValid = false;
            addIssue("TRES_DEPENDENCY_MISSING", `${row.newPath} -> ${dependency}`);
          } else {
            tresDependenciesChecked += 1;
          }
        } catch (error) {
          dependenciesValid = false;
          addIssue("TRES_EXT_RESOURCE_INVALID", `${row.newPath}: ${error.message}`);
        }
      }
      if (dependenciesValid) tresFilesValid += 1;
    }
  }

  return {
    newFilesPresent,
    oldFilesAbsent,
    pngImportsValid,
    tresFilesValid,
    tresDependenciesChecked,
  };
}


function collectFilesRecursively(directory, output) {
  if (!fs.existsSync(directory)) return;
  const entries = fs.readdirSync(directory, { withFileTypes: true });
  for (const entry of entries) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      collectFilesRecursively(absolute, output);
    } else if (entry.isFile() && TEXT_EXTENSIONS.has(path.extname(entry.name).toLowerCase())) {
      output.add(absolute);
    }
  }
}


function lineNumberAt(text, index) {
  let line = 1;
  for (let cursor = 0; cursor < index; cursor += 1) {
    if (text.charCodeAt(cursor) === 10) line += 1;
  }
  return line;
}


function scanForStaleReferences(rows) {
  const files = new Set();
  files.add(path.join(PROJECT_ROOT, "project.godot"));
  files.add(path.join(PROJECT_ROOT, "export_presets.cfg"));
  for (const directory of ["scripts", "scenes", "tests", "tools"]) {
    collectFilesRecursively(path.join(PROJECT_ROOT, directory), files);
  }
  for (const relativePath of [
    "art/production/lobby/2026-08-08_lobby_hd_reset_and_cutout_v01/manifest.json",
    "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04/manifest.json",
    "art/production/ui/daily_program_composition/2026-08-16_cutouts_v02/manifest.json",
    "art/production/ui/benefits_popup/2026-08-16_program_composition_cutouts_v01/manifest.json",
  ]) files.add(path.join(PROJECT_ROOT, ...relativePath.split("/")));
  for (const row of rows) {
    if (path.posix.extname(row.newPath).toLowerCase() !== ".tres") continue;
    try {
      const absolute = projectAbsolute(row.newPath, `Row ${row.rowNumber} new_path`);
      if (fs.existsSync(absolute) && fs.statSync(absolute).isFile()) files.add(absolute);
    } catch {
      // Unsafe paths are already reported by validateRows().
    }
  }

  const oldReferences = new Map();
  for (const row of rows) {
    if (!row.oldPath) continue;
    oldReferences.set(`res://${row.oldPath}`.toLowerCase(), row);
  }

  let filesScanned = 0;
  let staleOccurrences = 0;
  for (const absolute of [...files].sort()) {
    if (!fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) continue;
    const text = fs.readFileSync(absolute, "utf8");
    const lowerText = text.toLowerCase();
    filesScanned += 1;
    for (const [oldReference, row] of oldReferences) {
      let offset = 0;
      while (offset < lowerText.length) {
        const index = lowerText.indexOf(oldReference, offset);
        if (index < 0) break;
        const relativeConsumer = toPosix(path.relative(PROJECT_ROOT, absolute));
        addIssue(
          "STALE_OLD_REFERENCE",
          `${relativeConsumer}:${lineNumberAt(text, index)} still contains res://${row.oldPath}`,
        );
        staleOccurrences += 1;
        offset = index + oldReference.length;
      }
    }
  }

  return { filesScanned, staleOccurrences };
}


function countExtensions(rows) {
  const counts = new Map();
  for (const row of rows) {
    const extension = path.posix.extname(row.newPath).toLowerCase() || "<none>";
    counts.set(extension, (counts.get(extension) ?? 0) + 1);
  }
  return counts;
}


function validateExtensionCounts(extensionCounts) {
  for (const [extension, expected] of EXPECTED_EXTENSION_COUNTS) {
    const actual = extensionCounts.get(extension) ?? 0;
    if (actual !== expected) {
      addIssue("MOVE_MAP_TYPE_COUNT", `Expected ${expected} ${extension} rows, found ${actual}.`);
    }
  }
  for (const [extension, count] of extensionCounts) {
    if (!EXPECTED_EXTENSION_COUNTS.has(extension)) {
      addIssue("MOVE_MAP_UNEXPECTED_TYPE", `Unexpected asset type ${extension}: ${count} rows.`);
    }
  }
}


function printGroupedDiagnostics(title, values) {
  if (values.length === 0) return;
  console.error(`\n${title} (${values.length})`);
  const grouped = new Map();
  for (const value of values) {
    if (!grouped.has(value.check)) grouped.set(value.check, []);
    grouped.get(value.check).push(value.message);
  }
  for (const [check, messages] of grouped) {
    console.error(`  [${check}] ${messages.length}`);
    for (const message of messages.slice(0, DETAIL_LIMIT_PER_CHECK)) {
      console.error(`    - ${message}`);
    }
    if (messages.length > DETAIL_LIMIT_PER_CHECK) {
      console.error(`    - ... ${messages.length - DETAIL_LIMIT_PER_CHECK} more`);
    }
  }
}


function main() {
  const rows = readMoveMap();
  validateRows(rows);
  const extensionCounts = countExtensions(rows);
  validateExtensionCounts(extensionCounts);
  const filesystem = validateFilesystem(rows);
  const references = scanForStaleReferences(rows);

  console.log("UI asset reorganization validation / UI 资源归整验收");
  console.log(`Project root: ${PROJECT_ROOT}`);
  console.log(`Move map: ${MOVE_MAP_RELATIVE}`);
  console.log(`Move-map rows: ${rows.length}/${EXPECTED_ASSET_COUNT}`);
  console.log(`Asset types: ${[...extensionCounts].map(([extension, count]) => `${extension}=${count}`).join(", ")}`);
  console.log(`New files present: ${filesystem.newFilesPresent}/${rows.length}`);
  console.log(`Old files absent: ${filesystem.oldFilesAbsent}/${rows.length}`);
  console.log(`PNG imports aligned: ${filesystem.pngImportsValid}/${extensionCounts.get(".png") ?? 0}`);
  console.log(`TRES dependencies valid: ${filesystem.tresFilesValid}/${extensionCounts.get(".tres") ?? 0} files, ${filesystem.tresDependenciesChecked} dependencies`);
  console.log(`Reference files scanned: ${references.filesScanned}`);
  console.log(`Stale old res:// references: ${references.staleOccurrences}`);
  console.log(`Warnings: ${warnings.length}`);
  console.log(`Errors: ${issues.length}`);

  printGroupedDiagnostics("WARNINGS", warnings);
  printGroupedDiagnostics("ERRORS", issues);

  if (issues.length > 0) {
    console.error("\nRESULT: FAIL");
    process.exitCode = 1;
  } else {
    console.log("RESULT: PASS");
  }
}


try {
  main();
} catch (error) {
  console.error("UI asset reorganization validation / UI 资源归整验收");
  console.error(`FATAL: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 2;
}
