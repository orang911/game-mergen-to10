// Validate that no runtime-consumer file references a res:// path under an
// export-excluded root. Reproducible: node tools/validate_export_exclusions.mjs
//
// Read-only: this script never writes, moves, or restores project files.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

// Must stay in sync with export_presets.cfg exclude_filter for the Web and
// Android presets. Each entry is a top-level directory (or `.tmp`) followed by
// `/**`, so only the first path segment after `res://` is checked.
const EXCLUDED_ROOTS = new Set([
  "art",
  "artifacts",
  "art_source",
  "asset_review_delete",
  "build",
  "build-templates",
  "builds",
  "docs",
  "imge",
  "library",
  "local",
  "packages",
  "settings",
  "temp",
  "tests",
  "tools",
  ".tmp",
]);

const CONSUMER_EXTENSIONS = new Set([
  ".gd",
  ".gdshader",
  ".tscn",
  ".tres",
  ".res",
  ".material",
  ".cfg",
  ".godot",
  ".json",
]);

const CONSUMER_ROOTS = ["scenes", "scripts", "shaders", "assets/runtime"];
const EXTRA_FILES = ["project.godot"];

function collectFiles(dir, out) {
  if (!fs.existsSync(dir)) return;
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    const absolute = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === ".import" || entry.name === "import") continue;
      collectFiles(absolute, out);
    } else if (entry.isFile() && CONSUMER_EXTENSIONS.has(path.extname(entry.name).toLowerCase())) {
      out.add(absolute);
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

const files = new Set();
for (const root of CONSUMER_ROOTS) collectFiles(path.join(repoRoot, ...root.split("/")), files);
for (const rel of EXTRA_FILES) files.add(path.join(repoRoot, ...rel.split("/")));

const violations = [];
let filesScanned = 0;
let referenceCount = 0;
for (const absolute of [...files].sort()) {
  if (!fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) continue;
  const text = fs.readFileSync(absolute, "utf8");
  filesScanned += 1;
  const pattern = /res:\/\/([^"\s)]+)/gi;
  let match;
  while ((match = pattern.exec(text)) !== null) {
    const rawPath = match[1].replace(/\\/g, "/").replace(/^\/+/, "");
    referenceCount += 1;
    const firstSegment = rawPath.split("/")[0].toLowerCase();
    if (EXCLUDED_ROOTS.has(firstSegment)) {
      const relativeConsumer = path.relative(repoRoot, absolute).replace(/\\/g, "/");
      violations.push({
        consumer: relativeConsumer,
        line: lineNumberAt(text, match.index),
        reference: `res://${rawPath}`,
        excluded_root: firstSegment,
      });
    }
  }
}

console.log("Export exclusion reference validation / 导出排除引用校验");
console.log(`Consumer files scanned: ${filesScanned}`);
console.log(`res:// references found: ${referenceCount}`);
console.log(`References into excluded roots: ${violations.length}`);
for (const violation of violations) {
  console.log(`  VIOLATION ${violation.consumer}:${violation.line} -> ${violation.reference} (root=${violation.excluded_root})`);
}
if (violations.length > 0) {
  console.error("RESULT: FAIL");
  process.exitCode = 1;
} else {
  console.log("RESULT: PASS");
}
