// Search the whole repo (excluding heavy/VCS dirs) for surviving copies of
// the missing non-UI atlas source frames/sheets.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const skip = new Set([".git", ".godot", "library", "builds", "node_modules", ".tmp", "temp", "local"]);

const needles = [
  "slime_stage_01",
  "goblin_stage_03",
  "shyouji",
  "gate_portal_sheet",
  "monster_death",
  "slime",
  "goblin",
  "portal_sheet",
];

function walk(dir, depth) {
  if (depth > 8) return;
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const e of entries) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (skip.has(e.name)) continue;
      walk(p, depth + 1);
    } else {
      const lower = e.name.toLowerCase();
      for (const n of needles) {
        if (lower.includes(n)) {
          const rel = path.relative(repoRoot, p).replace(/\\/g, "/");
          console.log(rel);
          break;
        }
      }
    }
  }
}

walk(repoRoot, 0);
