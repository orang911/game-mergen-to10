import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const targets = process.argv.slice(2);

function walk(dir, prefix) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (e) {
    console.log(prefix + "[unreadable] " + dir);
    return;
  }
  entries.sort((a, b) => a.name.localeCompare(b.name));
  for (const e of entries) {
    const rel = path.relative(repoRoot, path.join(dir, e.name)).replace(/\\/g, "/");
    if (e.isDirectory()) {
      console.log(rel + "/");
      walk(path.join(dir, e.name), prefix + "  ");
    } else {
      let size = "";
      try {
        size = String(fs.statSync(path.join(dir, e.name)).size);
      } catch {}
      console.log(rel + "  (" + size + " bytes)");
    }
  }
}

for (const t of targets) {
  const abs = path.join(repoRoot, ...t.split("/"));
  console.log("=== " + t + " ===");
  walk(abs, "");
}
