#!/usr/bin/env node

/** Build the audited 235-row UI runtime move map. */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(SCRIPT_DIR, "..");
const CATALOG_PATH = path.join(
  PROJECT_ROOT,
  "docs/assets/resource_catalog_workbook_source_2026-08-20.json",
);
const OUTPUT_PATH = path.join(
  PROJECT_ROOT,
  "docs/assets/ui_runtime_asset_move_map_2026-08-20.csv",
);
const EXPECTED_COUNT = 235;

function fail(message) {
  throw new Error(message);
}

function normalize(value) {
  return String(value ?? "").replaceAll("\\", "/").replace(/^\.\//, "");
}

function csv(value) {
  const text = String(value ?? "");
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function destination(ownership, owner, folder, fileName, options = {}) {
  const ownershipType = new Map([
    ["interfaces", "interface"],
    ["components", "component"],
    ["shared", "shared"],
  ]).get(ownership);
  if (!ownershipType) fail(`Unknown ownership root: ${ownership}`);
  return {
    newPath: `assets/runtime/ui/${ownership}/${owner}/${folder}/${fileName}`,
    ownershipType,
    owner,
    atlasGroup: options.atlasGroup ?? `atlas_ui_${ownershipType}_${owner}`,
    packingPolicy: options.packingPolicy ?? "PACK_CANDIDATE",
    notes: options.notes ?? "按当前真实消费者归入对应界面或共用模块。",
  };
}

function atlasDestination(ownership, owner, folder, fileName) {
  const isRegion = folder === "atlas_regions";
  return destination(ownership, owner, folder, fileName, {
    packingPolicy: isRegion ? "EXISTING_ATLAS_REGION" : "EXISTING_ATLAS_SHEET",
    notes: isRegion
      ? "现有 AtlasTexture 区域资源；必须与图集原图及消费者引用原子迁移。"
      : "现有运行图集原图；必须与全部 AtlasTexture 区域资源原子迁移。",
  });
}

function targetFor(oldPath) {
  const p = normalize(oldPath);
  const fileName = path.posix.basename(p);

  if (p.startsWith("assets/runtime/ui/screens/loading/")) {
    return destination(
      "interfaces",
      "loading",
      fileName.includes("background") ? "standalone" : "progress",
      fileName,
      fileName.includes("background")
        ? { packingPolicy: "STANDALONE", notes: "全屏 Loading 背景，不进入普通 UI 图集。" }
        : {},
    );
  }

  if (p.startsWith("assets/runtime/ui/screens/main_hub_v2/atlas_regions/")) {
    return atlasDestination("shared", "meta_icons", "atlas_regions", fileName);
  }
  if (p.startsWith("assets/runtime/ui/screens/main_hub_v2/atlases/")) {
    return atlasDestination("shared", "meta_icons", "atlases", fileName);
  }
  if (p.startsWith("assets/runtime/ui/screens/main_hub_v2/frames_mobile/")) {
    return destination("interfaces", "main_hub", "backplates", fileName, {
      packingPolicy: "STANDALONE",
      notes: "大厅移动端 NinePatch/框体资源，保持独立纹理便于局部替换。",
    });
  }
  if (p.startsWith("assets/runtime/ui/screens/main_hub_v2/")) {
    return destination("interfaces", "main_hub", "standalone", fileName, {
      packingPolicy: "STANDALONE",
      notes: "大厅大尺寸背景或主体岛屿，不进入普通 UI 图集。",
    });
  }

  if (p.startsWith("assets/runtime/ui/screens/settlement/")) {
    let folder = "backplates";
    if (fileName.startsWith("icon_") || ["reward_chest.png", "reward_coin.png", "reward_crystal.png"].includes(fileName)) folder = "icons";
    else if (fileName.startsWith("tab_")) folder = "tabs";
    else if (fileName.startsWith("title_") || fileName.startsWith("badge_")) folder = "decorations";
    return destination("interfaces", "settlement", folder, fileName, {
      packingPolicy: folder === "backplates" ? "STANDALONE" : "PACK_CANDIDATE",
      notes: folder === "backplates" ? "结算面板与统计框体保持独立，避免 NinePatch 串色。" : "结算界面同生命周期小资源，可作为本界面图集候选。",
    });
  }

  if (p.startsWith("assets/runtime/ui/battle/blocks/atlas_regions/")) {
    return atlasDestination("components", "board_tiles", "atlas_regions", fileName);
  }
  if (p.startsWith("assets/runtime/ui/battle/blocks/atlases/")) {
    return atlasDestination("components", "board_tiles", "atlases", fileName);
  }
  if (p.startsWith("assets/runtime/ui/battle/board/text/atlas_regions/")) {
    return atlasDestination("components", "board_glyphs", "atlas_regions", fileName);
  }
  if (p.startsWith("assets/runtime/ui/battle/board/text/atlases/")) {
    return atlasDestination("components", "board_glyphs", "atlases", fileName);
  }
  if (p === "assets/runtime/ui/battle/board/imprints/combat_skill_placeholder.png") {
    return destination("interfaces", "battle", "energy_hud/icons", fileName);
  }
  if (p.startsWith("assets/runtime/ui/battle/core/crystal_v2/")) {
    return destination("components", "crystal_tower", "textures", fileName, {
      packingPolicy: "STANDALONE",
      notes: "水晶塔等级序列是跨战斗流程复用的玩法组件，保持逐级独立替换。",
    });
  }
  if (p.startsWith("assets/runtime/ui/battle/core/")) {
    const renamed = new Map([
      ["guaiwmendong.png", "monster_gate.png"],
      ["背景.png", "battle_background.png"],
      ["路径.png", "monster_path.png"],
    ]).get(fileName);
    if (!renamed) fail(`Unmapped battle core asset: ${p}`);
    return destination("interfaces", "battle", "standalone", renamed, {
      packingPolicy: "STANDALONE",
      notes: "战斗世界大图；同时将中文/拼音旧名称改为明确英文功能名。",
    });
  }
  if (p.startsWith("assets/runtime/ui/battle/prompts/imprint_choice_v2/")) {
    const folder = fileName.includes("button_")
      ? "buttons"
      : fileName.includes("item_card")
        ? "backplates"
        : "decorations";
    return destination("interfaces", "imprint_choice", folder, fileName);
  }
  if (p.startsWith("assets/runtime/ui/battle/prompts/level_complete_v2/")) {
    const folder = fileName === "primary_button.png"
      ? "buttons"
      : fileName === "popup_panel.png"
        ? "backplates"
        : "decorations";
    return destination("interfaces", "chapter_node_complete", folder, fileName);
  }
  if (p.startsWith("assets/runtime/ui/battle/prompts/")) {
    return destination(
      "interfaces",
      "battle",
      fileName === "prompt_panel.png" ? "combat_feedback/backplates" : "combat_feedback/icons",
      fileName,
    );
  }
  if (p.startsWith("assets/runtime/ui/battle/tutorial/")) {
    return destination("interfaces", "battle", "tutorial/icons", fileName);
  }

  if (p.startsWith("assets/runtime/ui/cards/atlas_regions/")) {
    return atlasDestination("components", "card_icons", "atlas_regions", fileName);
  }
  if (p.startsWith("assets/runtime/ui/cards/atlases/")) {
    return atlasDestination("components", "card_icons", "atlases", fileName);
  }
  if (p === "assets/runtime/ui/cards/backs/crystal_card_back.png") {
    return destination("components", "card_backs", "textures", fileName, {
      packingPolicy: "STANDALONE",
      notes: "水晶卡背为玩法组件大图，保持独立纹理。",
    });
  }
  if (p.startsWith("assets/runtime/ui/cards/choice_v2/")) {
    const folder = fileName.includes("button_")
      ? "buttons"
      : fileName.includes("choice_card")
        ? "backplates"
        : "decorations";
    return destination("interfaces", "crystal_card_choice", folder, fileName);
  }
  if (p.startsWith("assets/runtime/ui/cards/stars/")) {
    return destination("components", "rating_stars", "icons", fileName);
  }

  if (p.startsWith("assets/runtime/ui/daily_program_composition_v02/")) {
    const relative = p.slice("assets/runtime/ui/daily_program_composition_v02/".length);
    const [folder, ...rest] = relative.split("/");
    return destination("interfaces", "daily_program", folder, rest.join("/"));
  }
  if (p.startsWith("assets/runtime/ui/benefits_popup_v01/")) {
    const relative = p.slice("assets/runtime/ui/benefits_popup_v01/".length);
    const [folder, ...rest] = relative.split("/");
    return destination("interfaces", "benefits", folder, rest.join("/"));
  }

  if (p.startsWith("assets/runtime/ui/secondary_centered_v04/frames/")) {
    const frameOwners = new Map([
      ["ui_battle_pause_shell_v03.png", ["interfaces", "battle_pause"]],
      ["ui_exit_confirm_shell_v03.png", ["interfaces", "exit_confirm"]],
      ["ui_settings_shell_v03.png", ["interfaces", "settings"]],
      ["ui_clear_data_confirm_shell_v03.png", ["shared", "confirmation"]],
      ["ui_first_purchase_gift_shell_v03.png", ["interfaces", "first_purchase"]],
      ["ui_piggy_bank_shell_v03.png", ["interfaces", "piggy_bank"]],
      ["ui_shop_shell_v03.png", ["interfaces", "shop"]],
    ]);
    const owner = frameOwners.get(fileName);
    if (!owner) fail(`Unmapped active secondary frame: ${p}`);
    return destination(owner[0], owner[1], "backplates", fileName, {
      packingPolicy: "STANDALONE",
      notes: owner[1] === "confirmation"
        ? "清空数据与购买确认共用同一确认框体。"
        : "二级界面独占框体，保持独立纹理便于局部修改。",
    });
  }
  if (p.startsWith("assets/runtime/ui/secondary_centered_v04/elements/common/")) {
    if (["switch_off.png", "switch_on.png"].includes(fileName)) {
      return destination("interfaces", "settings", "controls", fileName);
    }
    if (fileName.startsWith("button_")) {
      return destination("shared", "buttons", "states", fileName);
    }
    if (fileName === "panel_light.png") {
      return destination("shared", "backplates", "panels", fileName, {
        packingPolicy: "STANDALONE",
        notes: "多个二级界面共用的 NinePatch 基础面板。",
      });
    }
    if (fileName === "title_ribbon_blue.png") {
      return destination("shared", "decorations", "titles", fileName);
    }
    fail(`Unmapped active secondary common element: ${p}`);
  }
  if (p === "assets/runtime/ui/secondary_centered_v04/elements/icons/crystal.png") {
    return destination("interfaces", "shop", "icons", "shop_crystal.png");
  }
  if (p.includes("/elements/pages/commerce/")) {
    return destination(
      "interfaces",
      "first_purchase",
      fileName === "first_chest_open.png" ? "rewards" : "decorations",
      fileName,
    );
  }
  if (p.includes("/elements/pages/shop/")) {
    return destination("interfaces", "shop", "icons", fileName);
  }

  if (p.startsWith("assets/runtime/ui/common/")) {
    if (fileName === "app_icon.png") {
      return destination("shared", "app", "icons", fileName, {
        packingPolicy: "STANDALONE",
        notes: "项目配置直接引用的应用图标。",
      });
    }
    if (["success_light.png", "legacy_success_panel.png", "button_continue.png", "legacy_new_record.png", "icon_crown.png"].includes(fileName)) {
      let folder = "decorations";
      if (fileName === "legacy_success_panel.png") folder = "backplates";
      else if (fileName === "button_continue.png") folder = "buttons";
      else if (fileName === "icon_crown.png") folder = "icons";
      return destination("interfaces", "max_level_success", folder, fileName);
    }
    if (fileName === "legacy_game_background.png") {
      return destination("interfaces", "battle", "standalone", fileName, {
        packingPolicy: "STANDALONE",
        notes: "战斗界面兼容回退背景；保留 legacy 文件名以标记技术债。",
      });
    }
    if (["button_back.png", "button_close.png", "button_refresh.png", "button_restart.png", "button_sound.png", "popup_panel.png"].includes(fileName)) {
      return destination(
        "interfaces",
        "legacy_runtime_controls",
        fileName === "popup_panel.png" ? "backplates" : "buttons",
        fileName,
        {
          packingPolicy: "STANDALONE",
          notes: "当前仅由兼容预加载路径持有，单独隔离，避免误标为全局共用。",
        },
      );
    }
    fail(`Unmapped active common asset: ${p}`);
  }

  const legacyBattleNames = new Map([
    ["assets/runtime/资源/diban.png", ["board/standalone", "battle_board_backdrop.png"]],
    ["assets/runtime/资源/layer_001.png", ["top_hud/buttons", "battle_pause_button.png"]],
    ["assets/runtime/资源/layer_002.png", ["top_hud/icons", "battle_timer_clock_icon.png"]],
    ["assets/runtime/资源/layer_003.png", ["top_hud/backplates", "battle_wave_panel.png"]],
    ["assets/runtime/资源/layer_004.png", ["top_hud/backplates", "battle_timer_panel.png"]],
    ["assets/runtime/资源/layer_005.png", ["top_hud/icons", "battle_currency_icon.png"]],
    ["assets/runtime/资源/layer_006.png", ["top_hud/backplates", "battle_currency_panel.png"]],
    ["assets/runtime/资源/X-1.png", ["energy_hud/icons", "skill_disabled_icon.png"]],
    ["assets/runtime/资源/X-2.png", ["energy_hud/backplates", "skill_panel_frame.png"]],
    ["assets/runtime/资源/X-3.png", ["energy_hud/icons", "instant_cluster_swap.png"]],
    ["assets/runtime/资源/X-4.png", ["energy_hud/icons", "instant_crystal_rain.png"]],
    ["assets/runtime/资源/X-5.png", ["energy_hud/icons", "locked_item_slot.png"]],
  ]);
  if (legacyBattleNames.has(p)) {
    const [folder, renamed] = legacyBattleNames.get(p);
    return destination("interfaces", "battle", folder, renamed, {
      packingPolicy: folder.includes("standalone") || folder.includes("backplates") ? "STANDALONE" : "PACK_CANDIDATE",
      notes: "从中文旧根目录迁入战斗界面，并改为可读的英文功能名。",
    });
  }

  fail(`No destination rule for active UI asset: ${p}`);
}

function loadActivePaths() {
  if (!fs.existsSync(CATALOG_PATH)) fail(`Catalog source is missing: ${CATALOG_PATH}`);
  const catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, "utf8"));
  const sheets = Object.values(catalog.sheets ?? {});
  const register = sheets.find((rows) => Array.isArray(rows) && rows.length > 0 && Object.keys(rows[0]).some((key) => key.includes("Current Relative Path")));
  if (!register) fail("Asset Register sheet was not found in catalog source.");
  const keys = Object.keys(register[0]);
  const pathKey = keys.find((key) => key.includes("Current Relative Path"));
  const statusKey = keys.find((key) => key.includes("Status EN"));
  if (!pathKey || !statusKey) fail("Catalog register is missing path/status columns.");

  const activeUi = register
    .filter((row) => normalize(row[pathKey]).startsWith("assets/runtime/ui/"))
    .filter((row) => ["Active Runtime", "Active, Review Pending"].includes(String(row[statusKey])))
    .map((row) => normalize(row[pathKey]));
  const legacyUi = [
    "diban.png",
    "layer_001.png", "layer_002.png", "layer_003.png", "layer_004.png", "layer_005.png", "layer_006.png",
    "X-1.png", "X-2.png", "X-3.png", "X-4.png", "X-5.png",
  ].map((fileName) => `assets/runtime/资源/${fileName}`);
  return [...activeUi, ...legacyUi].sort((left, right) => left.localeCompare(right, "en"));
}

function main() {
  const oldPaths = loadActivePaths();
  if (oldPaths.length !== EXPECTED_COUNT) {
    fail(`Expected ${EXPECTED_COUNT} active UI assets, found ${oldPaths.length}.`);
  }
  if (new Set(oldPaths).size !== oldPaths.length) fail("Active source list contains duplicates.");

  const rows = oldPaths.map((oldPath) => ({ oldPath, ...targetFor(oldPath) }));
  const newPaths = new Set();
  for (const row of rows) {
    const oldAbsolute = path.join(PROJECT_ROOT, ...row.oldPath.split("/"));
    const newAbsolute = path.join(PROJECT_ROOT, ...row.newPath.split("/"));
    if (!fs.existsSync(oldAbsolute)) fail(`Active source does not exist: ${row.oldPath}`);
    if (fs.existsSync(newAbsolute)) fail(`Destination already exists: ${row.newPath}`);
    if (newPaths.has(row.newPath)) fail(`Duplicate destination: ${row.newPath}`);
    newPaths.add(row.newPath);
  }

  const headers = [
    "old_path", "new_path", "ownership_type", "interface_or_component",
    "atlas_group", "packing_policy", "notes_cn",
  ];
  const lines = [headers.join(",")];
  for (const row of rows) {
    lines.push([
      row.oldPath, row.newPath, row.ownershipType, row.owner,
      row.atlasGroup, row.packingPolicy, row.notes,
    ].map(csv).join(","));
  }
  fs.writeFileSync(OUTPUT_PATH, `\uFEFF${lines.join("\r\n")}\r\n`, "utf8");

  const ownership = {};
  const owners = {};
  const packing = {};
  for (const row of rows) {
    ownership[row.ownershipType] = (ownership[row.ownershipType] ?? 0) + 1;
    owners[row.owner] = (owners[row.owner] ?? 0) + 1;
    packing[row.packingPolicy] = (packing[row.packingPolicy] ?? 0) + 1;
  }
  console.log(JSON.stringify({
    output: path.relative(PROJECT_ROOT, OUTPUT_PATH).replaceAll("\\", "/"),
    rows: rows.length,
    ownership,
    owners,
    packing,
  }, null, 2));
}

try {
  main();
} catch (error) {
  console.error(`[ui-move-map] ${error.message}`);
  process.exitCode = 1;
}
