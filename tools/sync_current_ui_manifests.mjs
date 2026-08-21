#!/usr/bin/env node

/** Synchronize current production manifests with the 2026-08-20 runtime UI move map. */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(SCRIPT_DIR, "..");
const MOVE_MAP = path.join(PROJECT_ROOT, "docs/assets/ui_runtime_asset_move_map_2026-08-20.csv");
const CURRENT_MANIFESTS = [
  "art/production/lobby/2026-08-08_lobby_hd_reset_and_cutout_v01/manifest.json",
  "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04/manifest.json",
  "art/production/ui/daily_program_composition/2026-08-16_cutouts_v02/manifest.json",
];
const BENEFITS_MANIFEST = "art/production/ui/benefits_popup/2026-08-16_program_composition_cutouts_v01/manifest.json";

function parseCsv(text) {
  const rows = [];
  let row = [];
  let value = "";
  let quoted = false;
  for (let index = 0; index < text.length; index += 1) {
    const char = text[index];
    if (quoted) {
      if (char === '"' && text[index + 1] === '"') {
        value += '"';
        index += 1;
      } else if (char === '"') quoted = false;
      else value += char;
    } else if (char === '"') quoted = true;
    else if (char === ",") {
      row.push(value);
      value = "";
    } else if (char === "\n") {
      row.push(value.replace(/\r$/, ""));
      rows.push(row);
      row = [];
      value = "";
    } else value += char;
  }
  if (value || row.length) {
    row.push(value.replace(/\r$/, ""));
    rows.push(row);
  }
  return rows.filter((item) => item.some(Boolean));
}

function loadMappings() {
  const rows = parseCsv(fs.readFileSync(MOVE_MAP, "utf8").replace(/^\uFEFF/, ""));
  const headers = rows.shift();
  const oldIndex = headers.indexOf("old_path");
  const newIndex = headers.indexOf("new_path");
  if (oldIndex < 0 || newIndex < 0 || rows.length !== 235) throw new Error("Move map is incomplete.");
  return rows.map((row) => [row[oldIndex], row[newIndex]]);
}

function syncPlainPaths(relativePath, mappings) {
  const absolute = path.join(PROJECT_ROOT, ...relativePath.split("/"));
  let text = fs.readFileSync(absolute, "utf8");
  let count = 0;
  for (const [oldPath, newPath] of mappings) {
    if (!text.includes(oldPath)) continue;
    const parts = text.split(oldPath);
    count += parts.length - 1;
    text = parts.join(newPath);
  }
  fs.writeFileSync(absolute, text, "utf8");
  JSON.parse(text);
  return count;
}

function syncLobbyManifest() {
  const relativePath = CURRENT_MANIFESTS[0];
  const absolute = path.join(PROJECT_ROOT, ...relativePath.split("/"));
  const data = JSON.parse(fs.readFileSync(absolute, "utf8"));
  data.runtime_root = "assets/runtime/ui/interfaces/main_hub";
  data.mobile_frame_root = "assets/runtime/ui/interfaces/main_hub/backplates";
  data.runtime_shared_meta_icons_root = "assets/runtime/ui/shared/meta_icons";
  fs.writeFileSync(absolute, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}

function syncBenefitsManifest() {
  const absolute = path.join(PROJECT_ROOT, ...BENEFITS_MANIFEST.split("/"));
  const data = JSON.parse(fs.readFileSync(absolute, "utf8"));
  data.runtime_integrated = true;
  data.runtime_replaced = false;
  data.runtime_root = "assets/runtime/ui/interfaces/benefits";
  for (const asset of data.assets ?? []) {
    const productionPath = String(asset.path ?? "");
    if (!productionPath.startsWith("cutouts/")) continue;
    asset.runtime_path = `assets/runtime/ui/interfaces/benefits/${productionPath.slice("cutouts/".length)}`;
  }
  fs.writeFileSync(absolute, `${JSON.stringify(data, null, 2)}\n`, "utf8");
  return (data.assets ?? []).filter((asset) => asset.runtime_path).length;
}

const mappings = loadMappings();
const results = {};
for (const manifest of CURRENT_MANIFESTS) results[manifest] = syncPlainPaths(manifest, mappings);
syncLobbyManifest();
results[BENEFITS_MANIFEST] = syncBenefitsManifest();
console.log(JSON.stringify(results, null, 2));
