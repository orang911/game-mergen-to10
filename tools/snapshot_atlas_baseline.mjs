// Snapshot current runtime atlas PNGs to .tmp for pre/post rebuild pixel comparison.
// Usage: node tools/snapshot_atlas_baseline.mjs
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const baselines = [
  "assets/runtime/characters/monsters/atlases/slime_stage_01_walk_sheet.png",
  "assets/runtime/characters/monsters/atlases/slime_stage_01_hit_sheet.png",
  "assets/runtime/characters/monsters/atlases/monster_death_sheet.png",
  "assets/runtime/characters/monsters/atlases/tutorial_armored_walk_sheet.png",
  "assets/runtime/characters/monsters/atlases/tutorial_armored_hit_sheet.png",
  "assets/runtime/fx/merge/atlases/merge_sheet.png",
  "assets/runtime/fx/elements/lightning/atlases/beam_sheet.png",
  "assets/runtime/fx/portal/atlases/gate_portal_sheet_mobile.png",
  "assets/runtime/ui/components/board_tiles/atlases/block_tiles_sheet.png",
  "assets/runtime/ui/components/board_glyphs/atlases/block_glyphs_sheet.png",
  "assets/runtime/ui/components/card_icons/atlases/card_icons_sheet.png",
  "assets/runtime/ui/shared/meta_icons/atlases/lobby_icons_sheet.png",
];

const outRoot = path.join(repoRoot, ".tmp", "atlas_verify_baseline_2026-08-20");
fs.mkdirSync(outRoot, { recursive: true });
for (const rel of baselines) {
  const src = path.join(repoRoot, ...rel.split("/"));
  const dst = path.join(outRoot, ...rel.split("/"));
  fs.mkdirSync(path.dirname(dst), { recursive: true });
  fs.copyFileSync(src, dst);
  console.log("SNAPSHOT " + rel);
}
console.log("BASELINE_ROOT .tmp/atlas_verify_baseline_2026-08-20");
