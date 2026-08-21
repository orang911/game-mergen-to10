// Scan non-UI atlas source dependencies defined in build_runtime_atlases.ps1
// and report which source files are present vs missing.
// Reproducible: node tools/scan_atlas_sources.mjs
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
function repo(rel) {
  return path.join(repoRoot, ...rel.split("/"));
}

function exists(rel) {
  return fs.existsSync(repo(rel));
}

function numbered(format, start, count) {
  const items = [];
  for (let i = start; i < start + count; i++) {
    items.push(format.replace("{0:00}", String(i).padStart(2, "0"))
      .replace("{0:00000}", String(i).padStart(5, "0"))
      .replace("{0}", String(i)));
  }
  return items;
}

const characterRoot = "art/production/characters/runtime_atlas_sources/2026-08-20";
const fxRoot = "art/production/fx/runtime_atlas_sources/2026-08-20";

// Mirror the non-UI groups in build_runtime_atlases.ps1 (Output not under assets/runtime/ui/).
const groups = [
  {
    output: "assets/runtime/characters/monsters/atlases/slime_stage_01_walk_sheet.png",
    sources: numbered(`${characterRoot}/slime_stage_01/walk/frame_{0:00}.png`, 0, 18),
  },
  {
    output: "assets/runtime/characters/monsters/atlases/slime_stage_01_hit_sheet.png",
    sources: numbered(`${characterRoot}/slime_stage_01/hit/frame_{0:00}.png`, 0, 8),
  },
  {
    output: "assets/runtime/characters/monsters/atlases/monster_death_sheet.png",
    sources: numbered(`${characterRoot}/die/C-{0}.png`, 1, 19),
  },
  {
    output: "assets/runtime/characters/monsters/atlases/tutorial_armored_walk_sheet.png",
    sources: numbered(`${characterRoot}/xingzou_boos/goblin_stage_03_{0:00000}.png`, 0, 28),
  },
  {
    output: "assets/runtime/characters/monsters/atlases/tutorial_armored_hit_sheet.png",
    sources: numbered(`${characterRoot}/xingzou_boos/shyouji-{0}.png`, 1, 5),
  },
  {
    output: "assets/runtime/fx/merge/atlases/merge_sheet.png",
    sources: numbered(`${fxRoot}/merge/frame_{0:00}.png`, 0, 13),
  },
  {
    output: "assets/runtime/fx/elements/lightning/atlases/beam_sheet.png",
    sources: numbered(`${fxRoot}/lightning_beam/frame_{0:00}.png`, 0, 3),
  },
  {
    output: "assets/runtime/fx/portal/atlases/gate_portal_sheet_mobile.png",
    sources: numbered(`${fxRoot}/portal/frame_{0:00}.png`, 0, 20),
  },
];

const rows = [];
let missingCount = 0;
let presentCount = 0;
for (const group of groups) {
  const outExists = exists(group.output);
  const missing = group.sources.filter((s) => !exists(s));
  presentCount += group.sources.length - missing.length;
  missingCount += missing.length;
  rows.push({
    output: group.output,
    output_exists: outExists,
    source_total: group.sources.length,
    present: group.sources.length - missing.length,
    missing: missing.length,
    missing_sources: missing,
  });
  console.log(`GROUP ${group.output}`);
  console.log(`  output_exists=${outExists} sources=${group.sources.length} present=${group.sources.length - missing.length} missing=${missing.length}`);
  for (const m of missing) console.log(`  MISSING ${m}`);
}

console.log(`\nTOTAL present=${presentCount} missing=${missingCount}`);
fs.writeFileSync(
  repo("docs/assets/non_ui_atlas_source_scan_2026-08-20.json"),
  JSON.stringify({ scanned_at: new Date().toISOString(), groups: rows, total_present: presentCount, total_missing: missingCount }, null, 2),
);
console.log("WROTE docs/assets/non_ui_atlas_source_scan_2026-08-20.json");
