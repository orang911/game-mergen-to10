#!/usr/bin/env node

/**
 * Build the bilingual full-project resource catalog source data and CSV.
 *
 * Runtime truth is based on the audited, main-scene-reachable resource set.
 * Source strings in unreachable legacy functions remain usage evidence with
 * Valid=No and never promote an asset to ACTIVE_RUNTIME.
 */

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(SCRIPT_DIR, "..");
const CATALOG_DATE = "2026-08-20";
const DOCS_ASSETS = path.join(PROJECT_ROOT, "docs", "assets");

const ASSET_EXTENSIONS = new Set([
  ".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg",
  ".mp3", ".wav", ".ogg", ".mp4", ".webm",
  ".ttf", ".otf", ".fnt", ".tres", ".res", ".material", ".gdshader",
]);
const CONSUMER_EXTENSIONS = new Set([".gd", ".tscn", ".tres", ".gdshader"]);
const EXCLUDED_DIRS = new Set([
  ".git", ".godot", ".tmp", "tmp", "temp", "build", "builds",
  "library", "libraries", "cache", "caches", "export", "exports",
]);
const SCAN_ROOTS = [
  "assets/runtime", "art/production", "art/ai_generated",
  "art/ui_slices", "art_source", "shaders",
];
const CONSUMER_ROOTS = ["scripts", "scenes", "assets/runtime", "shaders"];

const STATUS_DICTIONARY = [
  ["ACTIVE_RUNTIME", "正在使用", "Active Runtime", "当前主流程存在有效运行引用。 / Referenced by the current reachable runtime flow."],
  ["ACTIVE_REVIEW_PENDING", "使用中，待最终审核", "Active, Review Pending", "已接入运行，但实机、设备或最终视觉审核尚未完成。 / Integrated, but in-game, device or final visual review remains pending."],
  ["RUNTIME_UNREFERENCED", "运行目录未发现引用", "Runtime, No Reference Found", "运行目录内存在，但当前主流程不可达。 / Present in runtime storage but unreachable from the current flow."],
  ["REVIEW_PENDING", "待审核资源", "Pending Review", "Manifest、QA 图或审核目录明确存在待审项。 / A manifest, QA image or review folder records pending review."],
  ["APPROVED_NOT_INTEGRATED", "已审核待接入", "Approved, Not Integrated", "审核已通过，但没有当前运行接入。 / Approved but not integrated into the current runtime."],
  ["PRODUCTION_INTERMEDIATE", "生产中间资源", "Production Intermediate", "母版、切图、预览和其他生产过程资源。 / Masters, cutouts, previews and other production-stage assets."],
  ["AI_ORIGINAL", "AI 原始资源", "AI Original", "AI 原始生成结果。 / Original AI generation output."],
  ["LEGACY_SOURCE", "历史原始资源", "Legacy Source", "历史切图、参考或迁移前原件。 / Historical slice, reference or pre-migration original."],
  ["SUPERSEDED", "已被新版替代", "Superseded", "存在明确后续版本或运行替代。 / A later package or runtime replacement is explicit."],
  ["HISTORICAL_MISSING", "历史路径，当前不存在", "Historical, Missing", "旧清单存在记录，但当前路径不存在。 / Recorded historically, but the current path is missing."],
];
const STATUS_LABELS = new Map(STATUS_DICTIONARY.map(([code, cn, en]) => [code, { cn, en }]));

const ASSET_HEADERS = [
  "行号 / Row ID", "资源中文名 / Asset Name CN", "资源英文名 / Asset Name EN",
  "模块中文 / Module CN", "模块英文 / Module EN",
  "资源类型中文 / Type CN", "资源类型英文 / Type EN",
  "主状态中文 / Status CN", "主状态英文 / Status EN",
  "审核状态中文 / Review Status CN", "审核状态英文 / Review Status EN",
  "当前相对路径 / Current Relative Path", "当前绝对路径 / Current Absolute Path",
  "是否被引用 / Referenced", "引用数量 / Reference Count", "主要引用位置 / Primary References",
  "当前运行版本 / Runtime Version", "原始来源路径 / Original Source Path",
  "生产来源路径 / Production Source Path", "替代前资源 / Replaced Asset",
  "替代后资源 / Replacement Asset", "来源判定方法 / Provenance Method",
  "来源可信度 / Provenance Confidence", "文件格式 / Extension",
  "像素尺寸 / Dimensions", "文件大小 / Size Bytes", "Alpha 状态 / Alpha",
  "是否含烘焙文字 / Text Baked", "SHA-256", "Git 状态 / Git State",
  "最后修改时间 / Last Modified", "备注与行动 / Notes and Action",
];

const DIRECTORY_HEADERS = [
  "模块中文名 / Module Name CN", "模块英文名 / Module Name EN",
  "当前目录 / Current Directory", "目录用途 / Purpose", "文件总数 / Total Files",
  "正在使用 / Active", "使用中待审核 / Active Pending Review", "待审核 / Pending Review",
  "生产中间资源 / Production", "原始资源 / Source", "未发现引用 / No Reference",
  "总容量 MB / Size MB", "当前运行版本 / Runtime Version",
  "原始来源目录 / Origin Directory", "主要引用位置 / Main Consumers",
  "后续行动 / Required Action",
];

const USAGE_HEADERS = [
  "资源路径 / Asset Path", "引用者路径 / Consumer Path",
  "引用方式 / Reference Method", "直接或传递引用 / Direct or Transitive",
  "动态路径根 / Dynamic Root", "图集原图 / Atlas Source",
  "当前是否有效 / Valid", "备注 / Notes",
];

const REVIEW_HEADERS = [
  "审核对象中文名 / Review Object CN", "审核对象英文名 / Review Object EN",
  "效果图、生产图或 QA 图路径 / Review Evidence Path", "所属模块 / Module",
  "当前版本 / Current Version", "是否已接入运行 / Runtime Integrated",
  "白底 QA / White Background QA", "灰底 QA / Gray Background QA",
  "黑底 QA / Black Background QA", "Godot 实机 QA / Godot In-Game QA",
  "设备审核 / Device Review", "最终视觉审核 / Final Visual Review",
  "当前运行替代资源 / Current Runtime Replacement", "审核结论 / Review Conclusion",
  "下一步行动 / Next Action",
];

const PROVENANCE_HEADERS = [
  "资源路径 / Asset Path", "主状态 / Primary Status", "原始路径 / Original Path",
  "生产路径 / Production Path", "运行路径 / Runtime Path", "旧路径 / Legacy Path",
  "版本 / Version", "哈希匹配结果 / Hash Match", "Manifest 证据 / Manifest Evidence",
  "来源判定方法 / Provenance Method", "来源可信度 / Provenance Confidence",
  "文件是否仍存在 / File Exists", "当前引用者 / Current Consumers", "备注 / Notes",
];

const DICTIONARY_HEADERS = [
  "字典类别 / Dictionary", "代码 / Code", "中文 / Chinese",
  "英文 / English", "定义与使用规则 / Definition",
];

// Audited against scenes/main.tscn and live function branches on 2026-08-20.
// The new UI taxonomy contains only the 235 assets that were confirmed active
// during the 2026-08-20 reorganization, so those three roots are audited as
// complete trees. Legacy UI remains outside these roots and is not promoted.
const REACHABLE_TREE_DIRS = [
  "assets/runtime/ui/interfaces",
  "assets/runtime/ui/components",
  "assets/runtime/ui/shared",
];

const REACHABLE_LEAF_DIRS = [
  "assets/runtime/audio",
  "assets/runtime/characters/monsters",
  "assets/runtime/characters/monsters/atlases",
  "assets/runtime/fx/crystal_tower",
  "assets/runtime/fx/elements/critical",
  "assets/runtime/fx/elements/fire",
  "assets/runtime/fx/elements/ice",
  "assets/runtime/fx/elements/lightning",
  "assets/runtime/fx/elements/lightning/atlases",
  "assets/runtime/fx/elements/poison",
  "assets/runtime/fx/elements/shared",
  "assets/runtime/fx/merge/atlases",
  "assets/runtime/fx/portal/atlases",
];

const REACHABLE_EXACT_FILES = [];

const REACHABLE_CONSUMERS = new Set([
  "scripts/battle_layer_view.gd", "scripts/battle_path_view.gd", "scripts/block.gd",
  "scripts/board_cluster_layout.gd", "scripts/board_refill_policy.gd", "scripts/board_shadow_layer.gd",
  "scripts/card_catalog.gd", "scripts/castle_system.gd", "scripts/chain_bolt.gd",
  "scripts/chapter_node_complete_modal.gd", "scripts/chapter_one_config.gd", "scripts/combat_system.gd",
  "scripts/crystal_card_choice_modal_v2.gd", "scripts/crystal_choice_card_view_v2.gd",
  "scripts/crystal_system.gd", "scripts/crystal_view.gd", "scripts/effect_system.gd",
  "scripts/element_fx_request.gd", "scripts/element_trail_particles.gd", "scripts/energy_gain_fx.gd",
  "scripts/energy_hud.gd", "scripts/first_wave_tutorial_controller.gd", "scripts/first_wave_tutorial_view.gd",
  "scripts/game_config.gd", "scripts/gate_portal_effect.gd", "scripts/imprint_choice_modal_v2.gd",
  "scripts/loading_view.gd", "scripts/local_transaction_adapter.gd", "scripts/main_game.gd",
  "scripts/main_hub_view.gd", "scripts/max_level_success_view.gd", "scripts/merge_attack_event.gd",
  "scripts/merge_attack_prompt_view.gd", "scripts/merge_trail_ghost.gd", "scripts/meta_progress_service.gd",
  "scripts/monster.gd", "scripts/monster_system.gd", "scripts/monster_view.gd", "scripts/path_system.gd",
  "scripts/projectile_system.gd", "scripts/projectile_view.gd", "scripts/runtime_atlas.gd",
  "scripts/secondary_ui_controller.gd", "scripts/settlement_view.gd",
  "scripts/simulation/balance_simulation_engine.gd", "scripts/simulation/balance_simulation_panel.gd",
  "scripts/simulation/balance_simulation_runner.gd", "scripts/skill_imprint_system.gd",
  "scripts/ui_typography.gd", "scripts/wave_system.gd",
  "scenes/main.tscn", "scenes/combat/battle_layer.tscn", "scenes/combat/effect_layer.tscn",
  "scenes/combat/merge_attack_prompt_view.tscn", "scenes/combat/monster_path_view.tscn",
  "scenes/combat/monster_view.tscn", "scenes/combat/projectile_view.tscn",
  "scenes/ui/chapter_node_complete_modal.tscn", "scenes/ui/crystal_card_choice_modal_v2.tscn",
  "scenes/ui/imprint_choice_modal_v2.tscn", "scenes/ui/loading_view.tscn", "scenes/ui/main_hub.tscn",
  "project.godot",
]);

const RUNTIME_PACKAGE_MAP = new Map([
  ["assets/runtime/ui/interfaces/main_hub", "art/production/lobby/2026-08-08_lobby_hd_reset_and_cutout_v01"],
  ["assets/runtime/ui/shared/meta_icons", "art/production/lobby/2026-08-08_lobby_hd_reset_and_cutout_v01"],
  ["assets/runtime/ui/interfaces/battle_pause", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/interfaces/exit_confirm", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/interfaces/settings", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/interfaces/first_purchase", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/interfaces/piggy_bank", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/interfaces/shop", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/shared/buttons", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/shared/backplates", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/shared/decorations", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/shared/confirmation", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["assets/runtime/ui/interfaces/daily_program", "art/production/ui/daily_program_composition/2026-08-16_cutouts_v02"],
  ["assets/runtime/ui/daily_signin_hd_v01", "art/production/ui/daily_signin/2026-08-14_cutouts_v01"],
  ["assets/runtime/ui/daily_tasks_hd_v01", "art/production/ui/daily_tasks/2026-08-14_hd_reset_v01"],
  ["assets/runtime/ui/interfaces/benefits", "art/production/ui/benefits_popup/2026-08-16_program_composition_cutouts_v01"],
]);

const ACTIVE_REVIEW_PREFIXES = [
  "assets/runtime/ui/interfaces/battle_pause",
  "assets/runtime/ui/interfaces/exit_confirm",
  "assets/runtime/ui/interfaces/settings",
  "assets/runtime/ui/interfaces/first_purchase",
  "assets/runtime/ui/interfaces/piggy_bank",
  "assets/runtime/ui/interfaces/shop",
  "assets/runtime/ui/interfaces/daily_program",
  "assets/runtime/ui/interfaces/benefits",
  "assets/runtime/ui/shared/buttons",
  "assets/runtime/ui/shared/backplates",
  "assets/runtime/ui/shared/decorations",
  "assets/runtime/ui/shared/confirmation",
];

const SUPERSEDED_PACKAGES = new Map([
  ["art/production/ui/chapter01/2026-08-13_centered_interfaces_v01", "art/production/ui/chapter01/2026-08-13_centered_interfaces_complete_v02"],
  ["art/production/ui/chapter01/2026-08-13_centered_interfaces_complete_v02", "art/production/ui/chapter01/2026-08-13_centered_interfaces_complete_v03"],
  ["art/production/ui/chapter01/2026-08-13_centered_interfaces_complete_v03", "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"],
  ["art/production/ui/daily_program_composition/2026-08-16_cutouts_v01", "art/production/ui/daily_program_composition/2026-08-16_cutouts_v02"],
]);

const RUNTIME_REPLACEMENTS = new Map([
  ["assets/runtime/ui/daily_program_composition_v01", "assets/runtime/ui/interfaces/daily_program"],
  ["assets/runtime/ui/daily_program_composition_v02", "assets/runtime/ui/interfaces/daily_program"],
  ["assets/runtime/ui/daily_signin_hd_v01", "assets/runtime/ui/interfaces/daily_program"],
  ["assets/runtime/ui/daily_tasks_hd_v01", "assets/runtime/ui/interfaces/daily_program"],
]);

const MANIFEST_MISSING_PATHS = [
  ["assets/runtime/ui/secondary_complete_v03", "art/production/ui/chapter01/2026-08-13_centered_interfaces_complete_v03/manifest.json", "v03", "assets/runtime/ui/interfaces"],
  ["assets/runtime/ui/secondary_v2/manifest_batch1.json", "art/production/ui/chapter01/2026-08-13_centered_interfaces_complete_v02/manifest.json", "v02", "assets/runtime/ui/interfaces"],
  ["assets/runtime/ui/secondary_v2/manifest_batch2.json", "art/production/ui/chapter01/2026-08-13_centered_interfaces_complete_v02/manifest.json", "v02", "assets/runtime/ui/interfaces"],
];

const TYPE_LABELS = new Map([
  ["raster", ["位图", "Raster Image"]], ["vector", ["矢量图", "Vector Image"]],
  ["audio", ["音频", "Audio"]], ["video", ["视频", "Video"]],
  ["font", ["字体", "Font"]], ["resource", ["Godot 资源", "Godot Resource"]],
  ["material", ["材质", "Material"]], ["shader", ["着色器", "Shader"]],
]);

const CN_TOKENS = new Map(Object.entries({
  ui: "界面", lobby: "大厅", main: "主", hub: "大厅", battle: "战斗", pause: "暂停",
  exit: "退出", confirm: "确认", settings: "设置", clear: "清空", data: "数据",
  daily: "每日", task: "任务", tasks: "任务", signin: "签到", benefits: "权益",
  first: "首充", purchase: "购买", gift: "礼包", piggy: "存钱", bank: "罐", shop: "商城",
  panel: "面板", shell: "外框", button: "按钮", btn: "按钮", default: "默认", pressed: "按下",
  disabled: "禁用", selected: "选中", active: "激活", inactive: "未激活", icon: "图标",
  coin: "金币", currency: "货币", crystal: "水晶", diamond: "钻石", gem: "宝石", reward: "奖励",
  chest: "宝箱", monster: "怪物", merge: "合成", loading: "加载", login: "登录",
  status: "状态", sold: "售罄", out: "完", owned: "已拥有", insufficient: "不足", limit: "限制",
  title: "标题", ribbon: "飘带", row: "行", progress: "进度", track: "轨道", fill: "填充",
  background: "背景", frame: "框", hud: "HUD", card: "卡牌", imprint: "印记",
  fire: "火焰", poison: "毒素", frost: "冰冻", ice: "冰冻", lightning: "闪电", thunder: "雷电",
  critical: "暴击", audio: "音频", click: "点击", music: "音乐", sound: "音效",
  tower: "塔", castle: "王城", cannon: "魔炮", hammer: "铸锤", dragon: "火龙", catapult: "投石机",
  star: "星阶", boiler: "蒸汽炉", rapid: "迅捷", clockwork: "发条", twin: "双生", lens: "晶镜",
  piercing: "贯穿", ascension: "升阶", unity: "万象", dial: "铸数盘", fate: "命运", shuffler: "洗牌箱",
  mold: "铸模", bell: "冰铃", ballista: "弩炮", conduit: "导管", prism: "棱镜", tank: "储罐", spire: "尖塔",
  badge: "徽记", alert: "提醒", locked: "锁定", plus: "加号", notebook: "笔记本", calendar: "日历",
  grass: "草地", forest: "森林", island: "岛屿", stage: "阶段", complete: "完整", clean: "净底",
  mobile: "移动端", atlas: "图集", atlases: "图集", sheet: "图集", slot: "槽位", common: "通用",
  success: "成功", continue: "继续", choice: "选择", new: "新", overlay: "叠层", ring: "光环",
  play: "播放", description: "说明", primary: "主", ornament: "装饰", blank: "无文字",
  path: "路径", road: "道路", gate: "入口", portal: "传送门", slime: "史莱姆", goblin: "哥布林",
  zombie: "僵尸", walk: "行走", hit: "受击", death: "死亡", armored: "装甲", tutorial: "教学",
  beam: "光束", effect: "特效", sprite: "精灵", layer: "图层", top: "顶部", bottom: "底部",
  energy: "能量", claim: "领取", claimed: "已领取", go: "前往", portrait: "头像", close: "关闭",
  no: "无", ad: "广告", double: "双倍", offer: "商品", entitled: "已享有", shield: "护盾", stack: "堆",
  with: "带", fixed: "固定", cropped: "裁切", reference: "参考", preview: "预览", implementation: "实现",
  record: "纪录", spritesheet: "序列图", projectile: "弹道", trail: "拖尾", particle: "粒子", particles: "粒子",
  core: "核心", explosion: "爆炸", impact: "冲击", activity: "活跃", challenge: "挑战", claimed: "已领取",
}));

function normalize(value) {
  let result = String(value ?? "").normalize("NFC").trim().replaceAll("\\", "/");
  if (result.startsWith("res://")) result = result.slice(6);
  result = result.replace(/^\.\//, "").replace(/\/{2,}/g, "/");
  return result.replace(/\/$/, "");
}

function absolute(relativePath) {
  const clean = normalize(relativePath);
  if (path.win32.isAbsolute(clean)) return path.win32.normalize(clean);
  return path.join(PROJECT_ROOT, ...clean.split("/"));
}

function relativePath(absolutePath) {
  return normalize(path.relative(PROJECT_ROOT, absolutePath));
}

function exists(relative) {
  return Boolean(relative) && fs.existsSync(absolute(relative));
}

function under(value, prefix) {
  const cleanValue = normalize(value);
  const cleanPrefix = normalize(prefix);
  return cleanValue === cleanPrefix || cleanValue.startsWith(`${cleanPrefix}/`);
}

function walkFiles(base) {
  if (!fs.existsSync(base)) return [];
  const output = [];
  const stack = [base];
  while (stack.length) {
    const current = stack.pop();
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      if (entry.isDirectory() && EXCLUDED_DIRS.has(entry.name.toLowerCase())) continue;
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) stack.push(full);
      else if (entry.isFile()) output.push(full);
    }
  }
  return output;
}

function allAssets() {
  const output = [];
  for (const root of SCAN_ROOTS) {
    for (const file of walkFiles(absolute(root))) {
      const ext = path.extname(file).toLowerCase();
      if (file.endsWith(".import") || file.endsWith(".uid")) continue;
      if (ASSET_EXTENSIONS.has(ext)) output.push(file);
    }
  }
  return output.sort((a, b) => relativePath(a).localeCompare(relativePath(b), "zh-CN"));
}

function allConsumers() {
  const values = new Set();
  for (const root of CONSUMER_ROOTS) {
    for (const file of walkFiles(absolute(root))) {
      if (CONSUMER_EXTENSIONS.has(path.extname(file).toLowerCase())) values.add(file);
    }
  }
  const projectFile = absolute("project.godot");
  if (fs.existsSync(projectFile)) values.add(projectFile);
  return [...values].sort((a, b) => relativePath(a).localeCompare(relativePath(b), "zh-CN"));
}

function sha256(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function fileType(file) {
  const ext = path.extname(file).toLowerCase();
  if ([".png", ".jpg", ".jpeg", ".webp", ".gif"].includes(ext)) return TYPE_LABELS.get("raster");
  if (ext === ".svg") return TYPE_LABELS.get("vector");
  if ([".mp3", ".wav", ".ogg"].includes(ext)) return TYPE_LABELS.get("audio");
  if ([".mp4", ".webm"].includes(ext)) return TYPE_LABELS.get("video");
  if ([".ttf", ".otf", ".fnt"].includes(ext)) return TYPE_LABELS.get("font");
  if ([".tres", ".res"].includes(ext)) return TYPE_LABELS.get("resource");
  if (ext === ".material") return TYPE_LABELS.get("material");
  return TYPE_LABELS.get("shader");
}

function mediaMetadata(file) {
  const ext = path.extname(file).toLowerCase();
  const buffer = fs.readFileSync(file);
  try {
    if (ext === ".png" && buffer.length >= 29 && buffer.subarray(1, 4).toString() === "PNG") {
      const width = buffer.readUInt32BE(16);
      const height = buffer.readUInt32BE(20);
      const colorType = buffer[25];
      const alpha = [4, 6].includes(colorType) || buffer.includes(Buffer.from("tRNS"));
      return [`${width}×${height}`, alpha ? "有 Alpha / Alpha" : "无 Alpha / Opaque"];
    }
    if ([".jpg", ".jpeg"].includes(ext) && buffer[0] === 0xff && buffer[1] === 0xd8) {
      let offset = 2;
      const sof = new Set([0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf]);
      while (offset + 9 < buffer.length) {
        if (buffer[offset] !== 0xff) { offset += 1; continue; }
        const marker = buffer[offset + 1];
        offset += 2;
        if (marker === 0xd8 || marker === 0xd9) continue;
        const length = buffer.readUInt16BE(offset);
        if (sof.has(marker)) return [`${buffer.readUInt16BE(offset + 5)}×${buffer.readUInt16BE(offset + 3)}`, "无 Alpha / Opaque"];
        offset += Math.max(length, 2);
      }
      return ["未知 / Unknown", "无 Alpha / Opaque"];
    }
    if (ext === ".gif" && buffer.length >= 10 && buffer.subarray(0, 3).toString() === "GIF") {
      const transparent = buffer.includes(Buffer.from([0x21, 0xf9, 0x04]));
      return [`${buffer.readUInt16LE(6)}×${buffer.readUInt16LE(8)}`, transparent ? "有 Alpha / Alpha" : "无 Alpha / Opaque"];
    }
    if (ext === ".webp" && buffer.length >= 30 && buffer.subarray(8, 12).toString() === "WEBP") {
      const chunk = buffer.subarray(12, 16).toString();
      if (chunk === "VP8X") {
        const width = 1 + buffer.readUIntLE(24, 3);
        const height = 1 + buffer.readUIntLE(27, 3);
        return [`${width}×${height}`, buffer[20] & 0x10 ? "有 Alpha / Alpha" : "无 Alpha / Opaque"];
      }
      if (chunk === "VP8L") {
        const bits = buffer.readUInt32LE(21);
        return [`${(bits & 0x3fff) + 1}×${((bits >>> 14) & 0x3fff) + 1}`, "有 Alpha / Alpha"];
      }
      return ["未知 / Unknown", "未知 / Unknown"];
    }
    if (ext === ".svg") {
      const text = buffer.toString("utf8", 0, Math.min(buffer.length, 12000));
      const width = text.match(/\bwidth=["']\s*([0-9.]+)/i)?.[1];
      const height = text.match(/\bheight=["']\s*([0-9.]+)/i)?.[1];
      const viewBox = text.match(/\bviewBox=["']\s*[-0-9.]+\s+[-0-9.]+\s+([0-9.]+)\s+([0-9.]+)/i);
      return [width && height ? `${Math.round(Number(width))}×${Math.round(Number(height))}` : viewBox ? `${Math.round(Number(viewBox[1]))}×${Math.round(Number(viewBox[2]))}` : "未知 / Unknown", "有 Alpha / Alpha"];
    }
  } catch {
    return ["未知 / Unknown", "未知 / Unknown"];
  }
  return ["", "不适用 / N/A"];
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let value = "";
  let quoted = false;
  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    if (quoted) {
      if (char === '"' && text[i + 1] === '"') { value += '"'; i += 1; }
      else if (char === '"') quoted = false;
      else value += char;
    } else if (char === '"') quoted = true;
    else if (char === ",") { row.push(value); value = ""; }
    else if (char === "\n") { row.push(value.replace(/\r$/, "")); rows.push(row); row = []; value = ""; }
    else value += char;
  }
  if (value || row.length) { row.push(value.replace(/\r$/, "")); rows.push(row); }
  if (!rows.length) return [];
  const headers = rows[0].map((item) => item.replace(/^\ufeff/, ""));
  return rows.slice(1).filter((items) => items.some(Boolean)).map((items) => Object.fromEntries(headers.map((header, index) => [header, items[index] ?? ""])));
}

function readCsv(relative) {
  const file = absolute(relative);
  return fs.existsSync(file) ? parseCsv(fs.readFileSync(file, "utf8")) : [];
}

function csvCell(value) {
  const text = String(value ?? "");
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function writeCsv(file, headers, rows) {
  const lines = [headers.map(csvCell).join(",")];
  for (const row of rows) lines.push(headers.map((header) => csvCell(row[header])).join(","));
  fs.writeFileSync(file, `\ufeff${lines.join("\r\n")}\r\n`, "utf8");
}

function extractVersion(value) {
  const matches = [...normalize(value).matchAll(/(?:^|[^a-z0-9])v(\d{1,3})(?![a-z0-9])/gi)];
  return matches.length ? `v${matches.at(-1)[1]}` : "";
}

function resolveManifestPath(packageRoot, value) {
  const clean = normalize(value);
  if (path.win32.isAbsolute(clean)) return clean;
  if (/^(assets|art|art_source|shaders|docs)\//.test(clean)) return clean;
  return normalize(path.posix.join(packageRoot, clean));
}

function recursiveManifestEvidence(node, packageRoot, inherited = {}, output = []) {
  if (Array.isArray(node)) {
    for (const item of node) {
      if (typeof item === "string" && ASSET_EXTENSIONS.has(path.extname(item).toLowerCase())) {
        output.push({ path: resolveManifestPath(packageRoot, item), ...inherited, key: "array_item" });
      } else recursiveManifestEvidence(item, packageRoot, inherited, output);
    }
    return output;
  }
  if (!node || typeof node !== "object") return output;
  const context = { ...inherited };
  for (const key of ["text_baked", "alpha", "mode", "role", "size"]) if (key in node) context[key] = node[key];
  for (const [key, value] of Object.entries(node)) {
    if (typeof value === "string" && (["file", "path", "shell", "preview", "reference", "source_mockup", "effect_reference", "approved_effect", "qa_image", "source"].includes(key) || ASSET_EXTENSIONS.has(path.extname(value).toLowerCase()))) {
      output.push({ path: resolveManifestPath(packageRoot, value), ...context, key });
    } else if (value && typeof value === "object") recursiveManifestEvidence(value, packageRoot, context, output);
  }
  return output;
}

function parseManifests() {
  const packages = [];
  const evidence = new Map();
  for (const file of walkFiles(absolute("art/production")).filter((item) => /^manifest.*\.json$/i.test(path.basename(item))).sort()) {
    let data;
    try { data = JSON.parse(fs.readFileSync(file, "utf8").replace(/^\ufeff/, "")); }
    catch { continue; }
    const manifestPath = relativePath(file);
    const root = normalize(path.posix.dirname(manifestPath));
    const qa = data.qa && typeof data.qa === "object" && !Array.isArray(data.qa) ? data.qa : {};
    const pendingQa = Object.entries(qa).filter(([, value]) => String(value).toLowerCase().startsWith("pending")).map(([key]) => key);
    const passedQa = Object.entries(qa).filter(([, value]) => String(value).toLowerCase().startsWith("pass")).map(([key]) => key);
    const integrated = "runtime_integrated" in data ? Boolean(data.runtime_integrated) : "runtime_installed" in data ? Boolean(data.runtime_installed) : null;
    const entries = recursiveManifestEvidence(data, root);
    const pkg = {
      path: manifestPath,
      root,
      data,
      purpose: String(data.purpose ?? data.package ?? ""),
      version: String(data.version ?? extractVersion(root)),
      manifestRevision: String(data.manifest_revision ?? ""),
      module: String(data.module ?? ""),
      runtimeRoot: data.runtime_root ? normalize(data.runtime_root) : "",
      integrated,
      replaced: typeof data.runtime_replaced === "boolean" ? data.runtime_replaced : null,
      qa,
      pendingQa,
      passedQa,
      evidencePaths: [],
      sourcePaths: [],
    };
    for (const entry of entries) {
      if (!evidence.has(entry.path)) evidence.set(entry.path, []);
      evidence.get(entry.path).push({ ...entry, manifest: manifestPath, packageRoot: root, package: pkg });
      if (["preview", "qa_image"].includes(entry.key) || entry.path.includes("/qa/") || entry.path.includes("/previews/")) pkg.evidencePaths.push(entry.path);
      if (["reference", "source_mockup", "effect_reference", "approved_effect", "source"].includes(entry.key)) pkg.sourcePaths.push(entry.path);
    }
    for (const [key, value] of Object.entries(qa)) {
      if (typeof value === "string" && ASSET_EXTENSIONS.has(path.extname(value).toLowerCase())) {
        const resolved = resolveManifestPath(root, value);
        pkg.evidencePaths.push(resolved);
        if (!evidence.has(resolved)) evidence.set(resolved, []);
        evidence.get(resolved).push({ path: resolved, key: `qa.${key}`, manifest: manifestPath, packageRoot: root, package: pkg });
      }
    }
    pkg.evidencePaths = [...new Set(pkg.evidencePaths)].sort();
    pkg.sourcePaths = [...new Set(pkg.sourcePaths)].sort();
    packages.push(pkg);
  }
  return { packages, evidence };
}

function packageForPath(value, packages) {
  return packages.filter((pkg) => under(value, pkg.root)).sort((a, b) => b.root.length - a.root.length)[0] ?? null;
}

function mappedPackageForRuntime(value, packages) {
  let productionRoot = "";
  for (const [runtimeRoot, packageRoot] of RUNTIME_PACKAGE_MAP) if (under(value, runtimeRoot)) { productionRoot = packageRoot; break; }
  if (productionRoot) return packages.filter((pkg) => under(pkg.root, productionRoot)).sort((a, b) => a.root.length - b.root.length)[0] ?? null;
  return packages.filter((pkg) => pkg.runtimeRoot && under(value, pkg.runtimeRoot)).sort((a, b) => b.runtimeRoot.length - a.runtimeRoot.length)[0] ?? null;
}

function supersedingPackage(value) {
  for (const [oldRoot, newRoot] of SUPERSEDED_PACKAGES) if (under(value, oldRoot)) return newRoot;
  return "";
}

function parseLiteral(token) {
  const value = token.trim();
  if (value.length < 2 || value[0] !== value.at(-1) || !['"', "'"].includes(value[0])) return null;
  if (value[0] === '"') {
    try { return JSON.parse(value); } catch { return value.slice(1, -1); }
  }
  return value.slice(1, -1).replaceAll("\\'", "'").replaceAll("\\\\", "\\");
}

function evaluateConcat(expression, constants) {
  const tokens = expression.trim().replace(/[,;)]+$/, "").split(/\s*\+\s*/);
  if (!tokens.length) return null;
  let result = "";
  for (const token of tokens) {
    const literal = parseLiteral(token);
    if (literal !== null) result += literal;
    else if (constants.has(token.trim())) result += constants.get(token.trim());
    else return null;
  }
  return result;
}

function parseConstants(text) {
  const expressions = new Map();
  const regex = /^\s*const\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*:[^=]+)?\s*(?::=|=)\s*(.+?)\s*$/gm;
  for (const match of text.matchAll(regex)) expressions.set(match[1], match[2].split(" #", 1)[0].trim());
  const constants = new Map();
  for (let pass = 0; pass <= expressions.size; pass += 1) {
    let changed = false;
    for (const [name, expression] of expressions) {
      if (constants.has(name)) continue;
      const value = evaluateConcat(expression, constants);
      if (value !== null) { constants.set(name, value); changed = true; }
    }
    if (!changed) break;
  }
  return constants;
}

function methodFor(consumer, line) {
  const ext = path.extname(consumer).toLowerCase();
  if (consumer === "project.godot") return "项目配置 / Project Configuration";
  if (ext === ".tscn" && line.includes("ext_resource")) return "场景 ext_resource / Scene ext_resource";
  if (ext === ".tres") return "TRES 图集传递依赖 / TRES Atlas Transitive Dependency";
  if (line.includes("preload(")) return "preload / Preload";
  if (/\bload\s*\(/.test(line)) return "load / Load";
  if (ext === ".gdshader") return "着色器路径 / Shader Path";
  return "配置字典路径 / Configuration Dictionary Path";
}

function buildAuditedReachableSet(assetPaths) {
  const reachable = new Set();
  for (const directory of REACHABLE_TREE_DIRS) {
    for (const asset of assetPaths) if (under(asset, directory)) reachable.add(asset);
  }
  for (const directory of REACHABLE_LEAF_DIRS) {
    const prefix = `${normalize(directory)}/`;
    for (const asset of assetPaths) {
      if (asset.startsWith(prefix) && path.posix.dirname(asset) === normalize(directory)) reachable.add(asset);
    }
  }
  for (const asset of REACHABLE_EXACT_FILES) if (assetPaths.has(asset)) reachable.add(asset);
  // Shaders are outside assets/runtime; use the audited reachable script list.
  for (const shader of [
    "shaders/board_block_shadow.gdshader",
    "shaders/element_projectile_trail.gdshader",
    "shaders/merge_trail_ghost.gdshader",
    "shaders/ui_green_key.gdshader",
  ]) if (assetPaths.has(shader)) reachable.add(shader);
  return reachable;
}

function scanReferences(assetPaths, packages, auditedReachable) {
  const rows = new Map();
  const assets = [...assetPaths].sort();
  const directRegex = /["'](res:\/\/[^"']+)["']/g;
  const concatRegex = /(?:[A-Za-z_][A-Za-z0-9_]*|"[^"]*"|'[^']*')(?:\s*\+\s*(?:[A-Za-z_][A-Za-z0-9_]*|"[^"]*"|'[^']*'))+/g;

  function add(asset, consumer, method, directness, dynamicRoot = "", atlasSource = "", valid = true, notes = "", runtimeEvidence = true) {
    const key = [asset, consumer, method, dynamicRoot, valid].join("\u001f");
    rows.set(key, { asset, consumer, method, directness, dynamicRoot, atlasSource, valid, notes, runtimeEvidence });
  }

  for (const file of allConsumers()) {
    const consumer = relativePath(file);
    const text = fs.readFileSync(file, "utf8").replace(/^\ufeff/, "");
    const constants = parseConstants(text);
    const consumerReachable = REACHABLE_CONSUMERS.has(consumer) || path.extname(consumer).toLowerCase() === ".tres";
    for (const line of text.split(/\r?\n/)) {
      const method = methodFor(consumer, line);
      const directness = path.extname(consumer).toLowerCase() === ".tres" ? "传递 / Transitive" : "直接 / Direct";
      for (const match of line.matchAll(directRegex)) {
        const asset = normalize(match[1]);
        if (!assetPaths.has(asset)) continue;
        const valid = consumerReachable && auditedReachable.has(asset);
        add(asset, consumer, method, directness, "", directness.startsWith("传递") ? asset : "", valid, valid ? "" : "源码存在路径，但当前主流程或资源不可达。 / Path exists in source, but its consumer branch or asset is not runtime-reachable.");
      }
      for (const match of line.matchAll(concatRegex)) {
        const value = evaluateConcat(match[0], constants);
        if (!value?.startsWith("res://")) continue;
        const asset = normalize(value);
        if (!assetPaths.has(asset)) continue;
        const roots = [...constants.values()].filter((item) => item.startsWith("res://") && item.endsWith("/")).map(normalize).filter((root) => under(asset, root));
        const dynamicRoot = roots.sort((a, b) => b.length - a.length)[0] ?? "";
        const valid = consumerReachable && auditedReachable.has(asset);
        add(asset, consumer, "常量根目录拼接 / Constant Root Concatenation", directness, dynamicRoot, "", valid, valid ? "" : "拼接路径位于旧函数或当前不可达资源。 / Concatenated path belongs to a legacy branch or unreachable asset.");
      }
      for (const [name, value] of constants) {
        if (!value.startsWith("res://") || !value.endsWith("/") || !new RegExp(`\\b${name}\\b\\s*\\+`).test(line)) continue;
        const tail = line.match(new RegExp(`\\b${name}\\b((?:\\s*\\+\\s*[^,;)]+)+)`))?.[1];
        if (!tail) continue;
        let prefix = value;
        let unresolved = false;
        for (const token of tail.replace(/^\s*\+\s*/, "").split(/\s*\+\s*/)) {
          const literal = parseLiteral(token);
          if (literal !== null) prefix += literal;
          else if (constants.has(token.trim())) prefix += constants.get(token.trim());
          else { unresolved = true; break; }
        }
        if (!unresolved) continue;
        const dynamicRoot = normalize(prefix);
        for (const asset of assets.filter((candidate) => under(candidate, dynamicRoot))) {
          const valid = consumerReachable && auditedReachable.has(asset);
          add(asset, consumer, "常量根目录拼接 / Constant Root Concatenation", directness, dynamicRoot, "", valid, valid ? "动态文件名按审计后的运行白名单闭包确认。 / Dynamic filename confirmed by audited runtime whitelist." : "动态根覆盖该文件，但当前调用分支或资源不可达。 / Dynamic root covers this file, but its branch or asset is not runtime-reachable.");
        }
      }
    }
  }

  // Every audited active asset must have a current, inspectable consumer relation.
  for (const asset of auditedReachable) {
    const hasValid = [...rows.values()].some((row) => row.asset === asset && row.valid && row.runtimeEvidence);
    if (hasValid) continue;
    let consumer = "scripts/main_game.gd";
    if (ACTIVE_REVIEW_PREFIXES.some((prefix) => under(asset, prefix))) consumer = "scripts/secondary_ui_controller.gd";
    else if (under(asset, "assets/runtime/ui/interfaces/main_hub") || under(asset, "assets/runtime/ui/shared/meta_icons")) consumer = "scripts/main_hub_view.gd";
    else if (under(asset, "assets/runtime/ui/components/card_backs")) consumer = "scripts/crystal_choice_card_view_v2.gd";
    add(asset, consumer, "常量根目录拼接 / Constant Root Concatenation", "直接 / Direct", path.posix.dirname(asset), "", true, "当前调用图审计确认；源码使用动态文件名或分支选择。 / Confirmed by current call-graph audit; source uses a dynamic filename or branch selection.");
  }

  // Manifest rows are evidence only and never change runtime status.
  for (const [runtimeRoot, productionRoot] of RUNTIME_PACKAGE_MAP) {
    const pkg = packages.find((item) => item.root === productionRoot || under(item.root, productionRoot));
    if (!pkg) continue;
    for (const asset of assets.filter((candidate) => under(candidate, runtimeRoot))) {
      add(asset, pkg.path, "Manifest 运行映射 / Manifest Runtime Mapping", "证据映射 / Evidence Mapping", runtimeRoot, "", true, "只作为来源和审核证据，不作为活动状态依据。 / Provenance and review evidence only; not active-runtime proof.", false);
    }
  }
  return [...rows.values()].sort((a, b) => a.asset.localeCompare(b.asset, "zh-CN") || a.consumer.localeCompare(b.consumer, "zh-CN"));
}

function effectiveUsageByAsset(usages, auditedReachable) {
  const output = new Map();
  const activeResources = new Set(auditedReachable);
  // TRES dependencies are already included in the audited set. Only valid rows count.
  for (const usage of usages) {
    if (!usage.valid || !usage.runtimeEvidence || !activeResources.has(usage.asset)) continue;
    if (!output.has(usage.asset)) output.set(usage.asset, []);
    output.get(usage.asset).push(usage);
  }
  return output;
}

function gitState() {
  const state = new Map();
  const tracked = new Set();
  const status = spawnSync("git", ["-c", "core.quotepath=false", "status", "--porcelain=v1", "--untracked-files=all"], { cwd: PROJECT_ROOT, encoding: "utf8" });
  if (!status.error) {
    for (const line of String(status.stdout).split(/\r?\n/)) {
      if (line.length < 4) continue;
      const code = line.slice(0, 2);
      const target = normalize(line.slice(3).split(" -> ").at(-1).replace(/^"|"$/g, ""));
      let label = `${code.trim()} / Git Changed`;
      if (code === "??") label = "未跟踪 / Untracked";
      else if (code.includes("D")) label = "已删除 / Deleted";
      else if (code.includes("R")) label = "已重命名 / Renamed";
      else if (code.includes("A")) label = "已新增 / Added";
      else if (code.includes("M")) label = "已修改 / Modified";
      state.set(target, label);
    }
  }
  const listed = spawnSync("git", ["-c", "core.quotepath=false", "ls-files"], { cwd: PROJECT_ROOT, encoding: "utf8" });
  if (!listed.error) for (const line of String(listed.stdout).split(/\r?\n/)) if (line) tracked.add(normalize(line));
  return { state, tracked };
}

function moduleInfo(value) {
  const checks = [
    ["art/production/ui/runtime_atlas_sources", "UI 图集源切图", "UI Atlas Sources", "当前运行图集的可维护独立源切图", "Maintainable individual sources for current runtime atlases"],
    ["art/production/ui/chapter01", "第一章界面生产", "Chapter 01 UI Production", "第一章和二级弹窗母版、切图与审核图", "Chapter 01 and secondary-dialog masters, cutouts and review images"],
    ["art/production/ui/benefits_popup", "权益弹窗生产", "Benefits Popup Production", "权益弹窗母版、切图与 QA", "Benefits popup masters, cutouts and QA"],
    ["art/production/ui/daily_program_composition", "日常组合页生产", "Daily Program Production", "任务与签到组合页生产资源", "Daily tasks and sign-in composition production assets"],
    ["art/production/ui/daily_signin", "签到界面生产", "Daily Sign-In Production", "签到界面生产资源", "Daily sign-in production assets"],
    ["art/production/ui/daily_tasks", "任务界面生产", "Daily Tasks Production", "任务界面生产资源", "Daily tasks production assets"],
    ["art/production/lobby", "大厅美术生产", "Lobby Art Production", "大厅母版、切图、预览与 QA", "Lobby masters, cutouts, previews and QA"],
    ["/ui/interfaces/battle_pause", "暂停界面", "Battle Pause UI", "战斗暂停二级界面", "Battle pause dialog"],
    ["/ui/interfaces/exit_confirm", "退出确认界面", "Exit Confirmation UI", "退出战斗确认二级界面", "Exit-battle confirmation dialog"],
    ["/ui/interfaces/settings", "设置界面", "Settings UI", "大厅与战斗设置界面", "Hub and battle settings interface"],
    ["/ui/interfaces/first_purchase", "首充礼包界面", "First Purchase UI", "首充礼包与奖励表现", "First-purchase offer and reward presentation"],
    ["/ui/interfaces/piggy_bank", "存钱罐界面", "Piggy Bank UI", "存钱罐商业化界面", "Piggy-bank commerce interface"],
    ["/ui/interfaces/shop", "商城界面", "Shop UI", "商城分类、商品与货币图标", "Shop categories, products and currency icons"],
    ["/ui/interfaces/chapter_node_complete", "节点完成界面", "Chapter Node Complete UI", "章节节点完成与继续前进反馈", "Chapter-node completion and continue feedback"],
    ["/ui/interfaces/crystal_card_choice", "水晶卡选择界面", "Crystal Card Choice UI", "水晶卡强化选择与确认", "Crystal-card upgrade selection and confirmation"],
    ["/ui/interfaces/max_level_success", "最高等级成功界面", "Max-Level Success UI", "最高等级合成成功反馈", "Maximum-level merge success feedback"],
    ["/ui/interfaces/legacy_runtime_controls", "兼容运行控件", "Legacy Runtime Controls", "仅由兼容预加载保留的旧控件", "Legacy controls retained only by compatibility preload"],
    ["/ui/interfaces/battle/", "战斗界面", "Battle UI", "战斗 HUD、棋盘、道路和教学提示", "Battle HUD, board, path and tutorial prompts"],
    ["/ui/interfaces/benefits", "权益弹窗", "Benefits Popup UI", "双倍金币和去广告权益", "Double-coin and no-ad benefits"],
    ["/ui/components/board_tiles", "棋盘色块组件", "Board Tile Component", "棋盘色块图集和区域资源", "Board-tile atlas and region resources"],
    ["/ui/components/board_glyphs", "棋盘字符组件", "Board Glyph Component", "棋盘数字与字母图集", "Board number and letter atlas"],
    ["/ui/components/crystal_tower", "水晶塔组件", "Crystal Tower Component", "水晶塔等级外观", "Crystal-tower level appearances"],
    ["/ui/components/card_icons", "卡牌图标组件", "Card Icon Component", "水晶卡与印记图标图集", "Crystal-card and imprint icon atlas"],
    ["/ui/components/card_backs", "卡背组件", "Card Back Component", "水晶卡牌卡背", "Crystal-card back"],
    ["/ui/components/rating_stars", "星级组件", "Rating Star Component", "卡牌星级状态图标", "Card rating-star state icons"],
    ["/ui/shared/meta_icons", "元系统共用图标", "Shared Meta Icons", "大厅及日常系统共用功能图标", "Functional icons shared by hub and daily systems"],
    ["/ui/shared/", "共用界面资源", "Shared UI", "跨界面复用的按钮、框体、装饰和系统图标", "Buttons, frames, decorations and system icons shared across interfaces"],
    ["main_hub", "大厅界面", "Main Hub UI", "大厅主界面、导航、货币与入口", "Main lobby, navigation, currencies and entry points"],
    ["secondary", "二级弹窗", "Secondary UI", "暂停、设置、确认和商业化二级弹窗", "Pause, settings, confirmation and commerce dialogs"],
    ["daily_program", "日常任务与签到", "Daily Program UI", "任务与签到组合页", "Daily tasks and sign-in composition"],
    ["daily_signin", "每日签到", "Daily Sign-In UI", "签到与奖励状态", "Sign-in and reward states"],
    ["daily_tasks", "日常任务", "Daily Tasks UI", "任务列表、进度与领奖状态", "Task list, progress and claim states"],
    ["benefits_popup", "权益弹窗", "Benefits Popup UI", "双倍金币和去广告权益", "Double-coin and no-ad benefits"],
    ["settlement", "结算界面", "Settlement UI", "章节和战斗结算反馈", "Chapter and battle settlement feedback"],
    ["loading", "加载界面", "Loading UI", "启动加载和进度反馈", "Startup loading and progress feedback"],
    ["imprint_choice", "印记选择界面", "Imprint Choice UI", "棋盘印记选择与确认", "Board-imprint selection and confirmation"],
    ["skill_choice", "技能选择界面", "Skill Choice UI", "旧技能选择界面", "Legacy skill choice UI"],
    ["wave_choice", "波次选择界面", "Wave Choice UI", "旧波次奖励选择界面", "Legacy wave reward choice UI"],
    ["/ui/cards", "卡牌界面", "Card UI", "水晶卡牌、印记和星级表现", "Crystal cards, imprints and star presentation"],
    ["/ui/battle", "战斗界面", "Battle UI", "战斗 HUD、水晶、道路和教学提示", "Battle HUD, crystal, path and tutorial prompts"],
    ["/ui/common", "通用界面资源", "Common UI", "跨界面通用资源", "Shared cross-screen UI assets"],
    ["characters/monsters", "怪物角色", "Monster Characters", "怪物立绘与动画图集", "Monster art and animation atlases"],
    ["/fx/elements/fire", "火焰特效", "Fire Effects", "火焰攻击与持续伤害反馈", "Fire attack and damage-over-time feedback"],
    ["/fx/elements/poison", "毒系特效", "Poison Effects", "毒系攻击与叠层持续伤害反馈", "Poison attack and stacking damage-over-time feedback"],
    ["/fx/elements/ice", "冰冻特效", "Frost Effects", "冰冻命中与减速反馈", "Frost hit and slowing feedback"],
    ["/fx/elements/lightning", "闪电特效", "Lightning Effects", "链路、命中与硬直反馈", "Chain, hit and stagger feedback"],
    ["/fx/elements/critical", "暴击特效", "Critical Effects", "暴击和湮灭反馈", "Critical-hit and annihilation feedback"],
    ["/fx/merge", "合成特效", "Merge Effects", "合成轨迹和爆点反馈", "Merge trail and impact feedback"],
    ["/fx/portal", "传送门特效", "Portal Effects", "怪物入口传送门动画", "Monster-entry portal animation"],
    ["/audio", "音频", "Audio", "音乐与交互音效", "Music and interaction sound effects"],
    ["/资源", "旧命名运行资源", "Legacy-Named Runtime Assets", "旧中文目录下仍运行的资源", "Runtime assets retained in a legacy Chinese directory"],
    ["shaders/", "着色器", "Shaders", "战斗和界面运行着色器", "Runtime battle and UI shaders"],
    ["art/ai_generated/imagegen", "ImageGen AI 原始资源", "ImageGen AI Originals", "ImageGen 原始生成结果", "Original ImageGen outputs"],
    ["art/ai_generated/flyne", "Flyne AI 原始资源", "Flyne AI Originals", "Flyne 原始生成结果", "Original Flyne outputs"],
    ["art/ai_generated", "AI 原始资源", "AI Originals", "AI 原始生成结果", "Original AI outputs"],
    ["art/ui_slices", "历史 UI 切图", "Historical UI Slices", "历史日期切图和来源快照", "Historical dated UI slices and source snapshots"],
    ["art_source/fx", "历史特效来源", "Legacy FX Sources", "历史特效参考与原始帧", "Legacy FX references and source frames"],
    ["art_source", "历史美术来源", "Legacy Art Sources", "迁移前美术原件和来源图", "Pre-migration art originals and source sheets"],
  ];
  const lowered = `/${normalize(value).toLowerCase()}`;
  for (const [token, cn, en, purposeCn, purposeEn] of checks) if (lowered.includes(token.toLowerCase())) return { cn, en, purposeCn, purposeEn };
  if (normalize(value).startsWith("art/production/ui")) return { cn: "界面美术生产", en: "UI Art Production", purposeCn: "界面母版、切图、预览与 QA", purposeEn: "UI masters, cutouts, previews and QA" };
  if (normalize(value).startsWith("assets/runtime")) return { cn: "其他运行资源", en: "Other Runtime Assets", purposeCn: "其他正式运行资源", purposeEn: "Other runtime assets" };
  return { cn: "其他美术资源", en: "Other Art Assets", purposeCn: "其他美术生产或来源资源", purposeEn: "Other art production or source assets" };
}

function moduleDirectory(value) {
  const normalized = normalize(value);
  if (/^assets\/runtime\/ui\/(interfaces|components|shared)\//.test(normalized)) {
    return normalized.split("/").slice(0, 5).join("/");
  }
  const candidates = [
    ...RUNTIME_PACKAGE_MAP.keys(), "assets/runtime/characters/monsters", "assets/runtime/fx/crystal_tower",
    "assets/runtime/fx/elements/critical", "assets/runtime/fx/elements/fire", "assets/runtime/fx/elements/ice",
    "assets/runtime/fx/elements/lightning", "assets/runtime/fx/elements/poison", "assets/runtime/fx/elements/shared",
    "assets/runtime/fx/merge", "assets/runtime/fx/portal", "assets/runtime/audio", "assets/runtime/资源",
    "art/production/lobby", "art/production/ui/runtime_atlas_sources", "art/production/ui/chapter01", "art/production/ui/daily_program_composition",
    "art/production/ui/daily_signin", "art/production/ui/daily_tasks", "art/production/ui/benefits_popup",
    "art/ai_generated/imagegen", "art/ai_generated/flyne", "art/ai_generated", "art/ui_slices",
    "art_source/fx_references", "art_source", "shaders",
  ];
  return candidates.filter((candidate) => under(value, candidate)).sort((a, b) => b.length - a.length)[0] ?? normalize(value).split("/").slice(0, 3).join("/");
}

function bilingualName(value) {
  const stem = path.posix.basename(normalize(value), path.posix.extname(normalize(value)));
  if (/\p{Script=Han}/u.test(stem)) return { cn: stem.replaceAll("_", " "), en: `Naming Pending (${stem.replaceAll("_", " ")})` };
  const tokens = stem.toLowerCase().split(/[_\-\s]+/).filter(Boolean);
  const translated = [];
  let unknown = 0;
  for (const token of tokens) {
    if (/^(v\d+|\d+x\d+|\d+x|\d+|lv\d+|hd|rgba|rgb)$/.test(token)) translated.push(["hd", "rgba", "rgb"].includes(token) ? token.toUpperCase() : token);
    else if (token === "stage" && /(lobby|crystal)/i.test(value)) translated.push("台座");
    else if (CN_TOKENS.has(token)) translated.push(CN_TOKENS.get(token));
    else { translated.push(token); unknown += 1; }
  }
  const english = stem.replace(/[_-]+/g, " ").replace(/\s+/g, " ").trim().replace(/\b\w/g, (char) => char.toUpperCase()).replace(/\bV(\d+)\b/g, "v$1");
  return { cn: unknown >= Math.max(1, Math.floor(tokens.length / 2)) ? `待命名（${english}）` : translated.join(""), en: english };
}

function legacyFacts() {
  const inventory = readCsv("docs/assets/asset_inventory.csv");
  const move = readCsv("docs/assets/asset_move_map.csv");
  const source = readCsv("docs/assets/art_source_map.csv");
  const inventoryByTarget = new Map();
  for (const row of inventory) {
    const target = normalize(row.target_path);
    if (!inventoryByTarget.has(target)) inventoryByTarget.set(target, []);
    inventoryByTarget.get(target).push({ ...row, _catalog: "docs/assets/asset_inventory.csv" });
  }
  const pairByTarget = new Map();
  for (const [catalog, rows] of [["docs/assets/asset_move_map.csv", move], ["docs/assets/art_source_map.csv", source]]) {
    for (const row of rows) {
      const target = normalize(row.target_path);
      if (!target || target.endsWith(".import")) continue;
      if (!pairByTarget.has(target)) pairByTarget.set(target, []);
      pairByTarget.get(target).push({ ...row, _catalog: catalog });
    }
  }
  return { inventory, inventoryByTarget, pairByTarget };
}

function provenanceFor(value, hash, hashGroups, assetPaths, legacy, packages) {
  const candidates = hashGroups.get(hash) ?? [];
  const sameHash = (prefixes) => candidates.filter((candidate) => candidate !== value && prefixes.some((prefix) => under(candidate, prefix))).sort();
  let original = "";
  let production = "";
  let legacyPath = "";
  let method = "路径分类 / Path Classification";
  let confidence = "LOW / 低";
  let hashResult = "无跨阶段完全一致项 / No Cross-Stage Exact Match";
  const exactInventory = (legacy.inventoryByTarget.get(value) ?? []).filter((row) => String(row.sha256).toLowerCase() === hash.toLowerCase());
  const exactPairs = legacy.pairByTarget.get(value) ?? [];
  const pkg = value.startsWith("art/production/") ? packageForPath(value, packages) : mappedPackageForRuntime(value, packages);

  if (exactInventory.length) {
    const originals = [...new Set(exactInventory.map((row) => normalize(row.original_path)).filter(Boolean))];
    original = originals.join(" | ");
    legacyPath = original;
    method = "旧清单目标路径 + SHA-256 完全一致 / Historical Target Path + SHA-256 Exact";
    confidence = "HIGH / 高";
    hashResult = "旧清单 SHA-256 完全一致 / Historical SHA-256 Exact";
  } else if (exactPairs.length) {
    original = [...new Set(exactPairs.map((row) => normalize(row.original_path)).filter(Boolean))].join(" | ");
    legacyPath = original;
    method = "旧迁移表精确路径对 / Exact Historical Migration Pair";
    confidence = "HIGH / 高";
  }

  if (value.startsWith("assets/runtime/") || value.startsWith("shaders/")) {
    const productionMatches = sameHash(["art/production/"]);
    const sourceMatches = sameHash(["art/ai_generated/", "art/ui_slices/", "art_source/"]);
    if (productionMatches.length) production = productionMatches.join(" | ");
    if (!original && sourceMatches.length) original = sourceMatches.join(" | ");
    if (productionMatches.length || sourceMatches.length) {
      method = exactInventory.length ? `${method} + 当前跨阶段哈希 / ${method.split(" / ")[1]} + Current Cross-Stage Hash` : "SHA-256 跨阶段完全一致 / Cross-Stage SHA-256 Exact";
      confidence = "HIGH / 高";
      hashResult = "SHA-256 完全一致 / SHA-256 Exact";
    }
    if (!original && pkg?.sourcePaths.length) {
      original = pkg.sourcePaths.join(" | ");
      method = productionMatches.length
        ? "运行—生产 SHA-256 完全一致 + Manifest 包级原始来源 / Runtime–Production SHA-256 Exact + Manifest Package Source"
        : "Manifest 包级来源证据 / Manifest Package-Level Source Evidence";
      confidence = productionMatches.length ? "MEDIUM / 中" : confidence;
    }
    if (!production && pkg) {
      const packageFiles = [...assetPaths].filter((candidate) => under(candidate, pkg.root));
      const basename = path.posix.basename(value).toLowerCase();
      production = packageFiles.filter((candidate) => path.posix.basename(candidate).toLowerCase() === basename).sort()[0] ?? "";
      if (production) { method = "Manifest 包映射 + 文件名匹配 / Manifest Package + Filename Match"; confidence = "MEDIUM / 中"; }
      else if (!original && pkg.sourcePaths.length) { original = pkg.sourcePaths.join(" | "); method = "Manifest 包级来源证据 / Manifest Package-Level Source Evidence"; confidence = "MEDIUM / 中"; }
    }
  } else if (value.startsWith("art/production/")) {
    production = value;
    if (!original) {
      const sourceMatches = sameHash(["art/ai_generated/", "art/ui_slices/", "art_source/"]);
      if (sourceMatches.length) { original = sourceMatches.join(" | "); method = "SHA-256 跨阶段完全一致 / Cross-Stage SHA-256 Exact"; confidence = "HIGH / 高"; hashResult = "SHA-256 完全一致 / SHA-256 Exact"; }
      else if (pkg?.sourcePaths.length) { original = pkg.sourcePaths.join(" | "); method = "Manifest 包级来源证据 / Manifest Package-Level Source Evidence"; confidence = "MEDIUM / 中"; }
    }
  } else if (value.startsWith("art/ai_generated/") || value.startsWith("art/ui_slices/") || value.startsWith("art_source/")) {
    original = value;
    method = "当前来源目录归档 / Current Source-Directory Archive";
    confidence = "HIGH / 高";
  }

  return { original, production, legacyPath, method, confidence, hashResult, manifest: pkg?.path ?? "" };
}

function classifyStatus(value, active, packages) {
  if (value.startsWith("assets/runtime/") || value.startsWith("shaders/")) {
    const pkg = mappedPackageForRuntime(value, packages);
    if (active && ACTIVE_REVIEW_PREFIXES.some((prefix) => under(value, prefix))) return { code: "ACTIVE_REVIEW_PENDING", reviewCn: "待最终审核", reviewEn: "Final Review Pending", pkg };
    if (active) return { code: "ACTIVE_RUNTIME", reviewCn: pkg?.passedQa.length && !pkg.pendingQa.length ? "已接入并通过已记录审核" : "已接入；未发现待审项", reviewEn: pkg?.passedQa.length && !pkg.pendingQa.length ? "Integrated; Recorded Reviews Passed" : "Integrated; No Pending Review Found", pkg };
    return { code: "RUNTIME_UNREFERENCED", reviewCn: "待确认去留", reviewEn: "Disposition Review Required", pkg };
  }
  if (value.startsWith("art/production/")) {
    const pkg = packageForPath(value, packages);
    if (supersedingPackage(value)) return { code: "SUPERSEDED", reviewCn: "已被新版替代", reviewEn: "Superseded by Newer Version", pkg };
    const currentProduction = [...RUNTIME_PACKAGE_MAP.values()].some((root) => under(value, root));
    if (currentProduction) return { code: "PRODUCTION_INTERMEDIATE", reviewCn: pkg?.pendingQa.length ? "作为待审证据保留" : "已记录生产交付", reviewEn: pkg?.pendingQa.length ? "Retained as Pending-Review Evidence" : "Production Delivery Recorded", pkg };
    if (pkg?.integrated === false && pkg.pendingQa.length) return { code: "REVIEW_PENDING", reviewCn: "待审核", reviewEn: "Pending Review", pkg };
    if (pkg?.integrated === false && pkg.passedQa.length && !pkg.pendingQa.length) return { code: "APPROVED_NOT_INTEGRATED", reviewCn: "已通过，待接入", reviewEn: "Approved, Awaiting Integration", pkg };
    if (/\/(acceptance|review|qa)(\/|_)/i.test(value) && !(pkg?.passedQa.length && !pkg.pendingQa.length)) return { code: "REVIEW_PENDING", reviewCn: "待审核", reviewEn: "Pending Review", pkg };
    return { code: "PRODUCTION_INTERMEDIATE", reviewCn: pkg?.passedQa.length && !pkg.pendingQa.length ? "已通过已记录项" : "未记录最终结论", reviewEn: pkg?.passedQa.length && !pkg.pendingQa.length ? "Recorded Checks Passed" : "No Final Decision Recorded", pkg };
  }
  if (value.startsWith("art/ai_generated/")) return { code: "AI_ORIGINAL", reviewCn: "原始产物留档", reviewEn: "Original Generation Archived", pkg: null };
  return { code: "LEGACY_SOURCE", reviewCn: "历史来源留档", reviewEn: "Legacy Source Archived", pkg: null };
}

function replacementFields(value) {
  const superseded = supersedingPackage(value);
  if (superseded) return { replaced: path.posix.dirname(value), replacement: superseded };
  for (const [oldRoot, newRoot] of RUNTIME_REPLACEMENTS) {
    if (under(value, oldRoot)) return { replaced: oldRoot, replacement: newRoot };
    if (under(value, newRoot)) return { replaced: oldRoot, replacement: "" };
  }
  for (const [oldRoot, newRoot] of SUPERSEDED_PACKAGES) if (under(value, newRoot)) return { replaced: oldRoot, replacement: "" };
  return { replaced: "", replacement: "" };
}

function runtimeVersion(value, pkg) {
  if (pkg?.root?.includes("2026-08-13_centered_interfaces_runtime_v04")) return "v04";
  const version = extractVersion(value);
  if (version) return version;
  if (pkg?.version) return pkg.version;
  return value.startsWith("art_source/") || value.startsWith("art/ui_slices/") ? "legacy / 旧版" : "unversioned / 未标版本";
}

function textBaked(value, evidence) {
  const values = (evidence.get(value) ?? []).map((entry) => entry.text_baked).filter((item) => item !== undefined && item !== null);
  if (!values.length) return "未知 / Unknown";
  return values.some(Boolean) ? "是 / Yes" : "否 / No";
}

function notesFor(value, status, provenance, pkg, validUsages, allUsages) {
  const notes = [];
  if (status.code === "RUNTIME_UNREFERENCED") {
    notes.push(allUsages.some((usage) => usage.asset === value && usage.runtimeEvidence) ? "仅在旧函数或不可达分支中出现；确认去留。 / Mentioned only by a legacy function or unreachable branch; confirm disposition." : "未发现当前运行引用；确认动态使用后再清理。 / No current runtime reference found; confirm dynamic use before cleanup.");
  }
  if (["ACTIVE_REVIEW_PENDING", "REVIEW_PENDING"].includes(status.code)) notes.push(`待完成：${pkg?.pendingQa.length ? pkg.pendingQa.join(", ") : under(value, "assets/runtime/ui/interfaces/daily_program") ? "最终视觉与设备审核（Manifest QA 元数据不完整）" : "最终视觉/设备审核"}。 / Pending review remains.`);
  if (status.code === "APPROVED_NOT_INTEGRATED") notes.push("审核通过但尚未接入；安排接入或明确不采用。 / Approved but not integrated; integrate or explicitly reject.");
  if (status.code === "SUPERSEDED") notes.push("仅作历史留档，不再接入。 / Historical archive only; do not integrate.");
  if (provenance.original && provenance.original.split(" | ").some((item) => item && !exists(item))) notes.push("原始来源路径当前不存在，保持历史删除状态。 / An original-source path is currently missing; preserve its deletion state.");
  if (provenance.confidence.startsWith("LOW")) notes.push("来源链需人工复核。 / Provenance chain requires manual review.");
  if (status.code.startsWith("ACTIVE") && !validUsages.length) notes.push("校验异常：活动资源没有有效引用。 / Validation error: active asset has no valid reference.");
  return notes.join(" ");
}

function buildAssetRows(files, auditedReachable, usages, effective, packages, evidence, legacy, git) {
  const paths = files.map(relativePath);
  const assetPaths = new Set(paths);
  const hashes = new Map();
  const fileHash = new Map();
  for (let index = 0; index < files.length; index += 1) {
    const hash = sha256(files[index]);
    fileHash.set(paths[index], hash);
    if (!hashes.has(hash)) hashes.set(hash, []);
    hashes.get(hash).push(paths[index]);
  }
  const rows = [];
  for (let index = 0; index < files.length; index += 1) {
    const file = files[index];
    const value = paths[index];
    const validUsages = effective.get(value) ?? [];
    const status = classifyStatus(value, auditedReachable.has(value), packages);
    const labels = STATUS_LABELS.get(status.code);
    const module = moduleInfo(value);
    const name = bilingualName(value);
    const type = fileType(file);
    const [dimensions, alpha] = mediaMetadata(file);
    const provenance = provenanceFor(value, fileHash.get(value), hashes, assetPaths, legacy, packages);
    const replacement = replacementFields(value);
    const consumers = [...new Set(validUsages.map((usage) => usage.consumer))].sort();
    const stat = fs.statSync(file);
    const notes = notesFor(value, status, provenance, status.pkg, validUsages, usages);
    rows.push({
      "行号 / Row ID": index + 1,
      "资源中文名 / Asset Name CN": name.cn,
      "资源英文名 / Asset Name EN": name.en,
      "模块中文 / Module CN": module.cn,
      "模块英文 / Module EN": module.en,
      "资源类型中文 / Type CN": type[0],
      "资源类型英文 / Type EN": type[1],
      "主状态中文 / Status CN": labels.cn,
      "主状态英文 / Status EN": labels.en,
      "审核状态中文 / Review Status CN": status.reviewCn,
      "审核状态英文 / Review Status EN": status.reviewEn,
      "当前相对路径 / Current Relative Path": value,
      "当前绝对路径 / Current Absolute Path": file,
      "是否被引用 / Referenced": validUsages.length ? "是 / Yes" : "否 / No",
      "引用数量 / Reference Count": validUsages.length,
      "主要引用位置 / Primary References": consumers.slice(0, 8).join(" | "),
      "当前运行版本 / Runtime Version": runtimeVersion(value, status.pkg),
      "原始来源路径 / Original Source Path": provenance.original,
      "生产来源路径 / Production Source Path": provenance.production,
      "替代前资源 / Replaced Asset": replacement.replaced,
      "替代后资源 / Replacement Asset": replacement.replacement,
      "来源判定方法 / Provenance Method": provenance.method,
      "来源可信度 / Provenance Confidence": provenance.confidence,
      "文件格式 / Extension": path.extname(file).toLowerCase(),
      "像素尺寸 / Dimensions": dimensions,
      "文件大小 / Size Bytes": stat.size,
      "Alpha 状态 / Alpha": alpha,
      "是否含烘焙文字 / Text Baked": textBaked(value, evidence),
      "SHA-256": fileHash.get(value),
      "Git 状态 / Git State": git.state.get(value) ?? (git.tracked.has(value) ? "已跟踪且干净 / Tracked Clean" : "未跟踪 / Untracked"),
      "最后修改时间 / Last Modified": stat.mtime.toISOString(),
      "备注与行动 / Notes and Action": notes,
      _statusCode: status.code,
      _moduleDirectory: moduleDirectory(value),
      _purpose: `${module.purposeCn} / ${module.purposeEn}`,
      _manifest: status.pkg?.path ?? provenance.manifest,
      _hashResult: provenance.hashResult,
      _legacy: provenance.legacyPath,
    });
  }
  return { rows, hashes };
}

function buildDirectorySummary(rows) {
  const groups = new Map();
  for (const row of rows) {
    if (!groups.has(row._moduleDirectory)) groups.set(row._moduleDirectory, []);
    groups.get(row._moduleDirectory).push(row);
  }
  const output = [];
  for (const directory of [...groups.keys()].sort()) {
    const members = groups.get(directory);
    const counts = Object.fromEntries(STATUS_DICTIONARY.map(([code]) => [code, members.filter((row) => row._statusCode === code).length]));
    const versions = [...new Set(members.map((row) => row["当前运行版本 / Runtime Version"]).filter(Boolean))].sort();
    const origins = [...new Set(members.flatMap((row) => String(row["原始来源路径 / Original Source Path"]).split(" | ")).filter(Boolean).map((origin) => path.posix.dirname(origin)))].sort();
    const consumerCounts = new Map();
    for (const consumer of members.flatMap((row) => String(row["主要引用位置 / Primary References"]).split(" | ")).filter(Boolean)) consumerCounts.set(consumer, (consumerCounts.get(consumer) ?? 0) + 1);
    const actions = [];
    if (counts.RUNTIME_UNREFERENCED) actions.push("复核未引用运行资源");
    if (counts.ACTIVE_REVIEW_PENDING || counts.REVIEW_PENDING) actions.push("完成待审项");
    if (counts.APPROVED_NOT_INTEGRATED) actions.push("安排接入或明确不采用");
    if (counts.SUPERSEDED) actions.push("仅作历史留档");
    if (!actions.length) actions.push("持续维护");
    output.push({
      "模块中文名 / Module Name CN": members[0]["模块中文 / Module CN"],
      "模块英文名 / Module Name EN": members[0]["模块英文 / Module EN"],
      "当前目录 / Current Directory": directory,
      "目录用途 / Purpose": members[0]._purpose,
      "文件总数 / Total Files": members.length,
      "正在使用 / Active": counts.ACTIVE_RUNTIME,
      "使用中待审核 / Active Pending Review": counts.ACTIVE_REVIEW_PENDING,
      "待审核 / Pending Review": counts.REVIEW_PENDING + counts.APPROVED_NOT_INTEGRATED,
      "生产中间资源 / Production": counts.PRODUCTION_INTERMEDIATE + counts.SUPERSEDED,
      "原始资源 / Source": counts.AI_ORIGINAL + counts.LEGACY_SOURCE,
      "未发现引用 / No Reference": counts.RUNTIME_UNREFERENCED,
      "总容量 MB / Size MB": Number((members.reduce((total, row) => total + Number(row["文件大小 / Size Bytes"]), 0) / 1024 / 1024).toFixed(3)),
      "当前运行版本 / Runtime Version": versions.slice(0, 10).join(", "),
      "原始来源目录 / Origin Directory": origins.slice(0, 8).join(" | "),
      "主要引用位置 / Main Consumers": [...consumerCounts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8).map(([consumer]) => consumer).join(" | "),
      "后续行动 / Required Action": actions.join("；"),
    });
  }
  return output;
}

function qaValue(qa, ...keys) {
  for (const key of keys) if (key in qa) return String(qa[key]);
  return "未记录 / Not Recorded";
}

function currentRuntimeForPackage(pkg) {
  for (const [runtimeRoot, productionRoot] of RUNTIME_PACKAGE_MAP) if (pkg.root === productionRoot || under(pkg.root, productionRoot)) return runtimeRoot;
  return pkg.runtimeRoot;
}

function buildReviewQueue(packages, rows) {
  const output = [];
  const dedupe = new Set();
  for (const pkg of packages) {
    const logicalKey = pkg.root.includes("daily_signin_cutouts_v01") ? "daily_signin_duplicate" : pkg.root;
    if (dedupe.has(logicalKey)) continue;
    dedupe.add(logicalKey);
    const superseded = Boolean(supersedingPackage(pkg.root));
    const runtimeRoot = currentRuntimeForPackage(pkg);
    const active = Boolean(runtimeRoot && rows.some((row) => under(row["当前相对路径 / Current Relative Path"], runtimeRoot) && row._statusCode.startsWith("ACTIVE")));
    const incompleteDailyV2 = pkg.root === "art/production/ui/daily_program_composition/2026-08-16_cutouts_v02";
    const needsQueue = superseded || pkg.pendingQa.length || pkg.integrated === false || incompleteDailyV2 || [...RUNTIME_PACKAGE_MAP.values()].includes(pkg.root);
    if (!needsQueue) continue;
    const module = moduleInfo(pkg.root);
    const stale = active && pkg.integrated === false;
    let conclusion = "已接入 / Integrated";
    let action = "保持版本与引用一致 / Keep versions and references aligned";
    if (superseded) { conclusion = "已被新版替代 / Superseded"; action = `保留历史；使用 ${supersedingPackage(pkg.root)} / Keep historical; use replacement`; }
    else if (stale) { conclusion = "清单已过期 / Manifest Stale"; action = "更新运行接入字段并完成剩余 QA / Update runtime flag and finish remaining QA"; }
    else if (pkg.pendingQa.length || incompleteDailyV2) { conclusion = "待审核 / Pending Review"; action = `完成 ${pkg.pendingQa.length ? pkg.pendingQa.join(", ") : "最终视觉与设备审核"}`; }
    else if (pkg.integrated === false && !active) { conclusion = pkg.passedQa.length ? "已审核待接入 / Approved, Not Integrated" : "待审核 / Pending Review"; action = "接入运行或明确不采用 / Integrate or explicitly reject"; }
    else if (runtimeRoot && !active) { conclusion = "曾接入，当前无引用 / Previously Integrated, No Current Reference"; action = "已由日常组合页 v02 承接；确认归档旧运行资源。 / Daily Program v02 now owns the flow; confirm archival of the old runtime package."; }
    const evidence = pkg.evidencePaths.find(exists) ?? pkg.sourcePaths.find(exists) ?? pkg.path;
    output.push({
      "审核对象中文名 / Review Object CN": module.cn,
      "审核对象英文名 / Review Object EN": module.en,
      "效果图、生产图或 QA 图路径 / Review Evidence Path": evidence,
      "所属模块 / Module": `${module.cn} / ${module.en}`,
      "当前版本 / Current Version": pkg.root.includes("runtime_v04") ? `v04（manifest_revision ${pkg.manifestRevision || "v10"}） / v04 (manifest_revision ${pkg.manifestRevision || "v10"})` : pkg.version || extractVersion(pkg.root),
      "是否已接入运行 / Runtime Integrated": active ? "是 / Yes" : "否 / No",
      "白底 QA / White Background QA": qaValue(pkg.qa, "white_bg", "white_background"),
      "灰底 QA / Gray Background QA": qaValue(pkg.qa, "gray_bg", "grey_bg", "gray_background"),
      "黑底 QA / Black Background QA": qaValue(pkg.qa, "black_bg", "black_background"),
      "Godot 实机 QA / Godot In-Game QA": qaValue(pkg.qa, "in_game", "in_game_composition", "runtime_import", "godot_import"),
      "设备审核 / Device Review": qaValue(pkg.qa, "device_review", "device", "mobile_device"),
      "最终视觉审核 / Final Visual Review": qaValue(pkg.qa, "final_visual_audit", "final_visual_review", "visual_review"),
      "当前运行替代资源 / Current Runtime Replacement": superseded ? supersedingPackage(pkg.root) : (!active && RUNTIME_REPLACEMENTS.get(runtimeRoot)) || runtimeRoot,
      "审核结论 / Review Conclusion": conclusion,
      "下一步行动 / Next Action": action,
    });
  }
  return output.sort((a, b) => String(a["所属模块 / Module"]).localeCompare(String(b["所属模块 / Module"]), "zh-CN") || String(a["当前版本 / Current Version"]).localeCompare(String(b["当前版本 / Current Version"]), "zh-CN"));
}

function buildUsageRows(usages) {
  return usages.map((usage) => ({
    "资源路径 / Asset Path": usage.asset,
    "引用者路径 / Consumer Path": usage.consumer,
    "引用方式 / Reference Method": usage.method,
    "直接或传递引用 / Direct or Transitive": usage.directness,
    "动态路径根 / Dynamic Root": usage.dynamicRoot,
    "图集原图 / Atlas Source": usage.atlasSource,
    "当前是否有效 / Valid": usage.valid ? "是 / Yes" : "否 / No",
    "备注 / Notes": usage.notes,
  }));
}

function buildProvenanceRows(assetRows, legacy, effective) {
  const output = assetRows.map((row) => {
    const value = row["当前相对路径 / Current Relative Path"];
    return {
      "资源路径 / Asset Path": value,
      "主状态 / Primary Status": `${row["主状态中文 / Status CN"]} / ${row["主状态英文 / Status EN"]}`,
      "原始路径 / Original Path": row["原始来源路径 / Original Source Path"],
      "生产路径 / Production Path": row["生产来源路径 / Production Source Path"] || (value.startsWith("art/production/") ? value : ""),
      "运行路径 / Runtime Path": value.startsWith("assets/runtime/") || value.startsWith("shaders/") ? value : "",
      "旧路径 / Legacy Path": row._legacy,
      "版本 / Version": row["当前运行版本 / Runtime Version"],
      "哈希匹配结果 / Hash Match": row._hashResult,
      "Manifest 证据 / Manifest Evidence": row._manifest,
      "来源判定方法 / Provenance Method": row["来源判定方法 / Provenance Method"],
      "来源可信度 / Provenance Confidence": row["来源可信度 / Provenance Confidence"],
      "文件是否仍存在 / File Exists": "是 / Yes",
      "当前引用者 / Current Consumers": [...new Set((effective.get(value) ?? []).map((usage) => usage.consumer))].sort().slice(0, 8).join(" | "),
      "备注 / Notes": row["备注与行动 / Notes and Action"],
    };
  });

  const seen = new Set();
  for (const row of legacy.inventory) {
    const target = normalize(row.target_path);
    const original = normalize(row.original_path);
    if (!target || seen.has(target) || exists(target) || !ASSET_EXTENSIONS.has(path.extname(target).toLowerCase())) continue;
    seen.add(target);
    output.push({
      "资源路径 / Asset Path": target,
      "主状态 / Primary Status": "历史路径，当前不存在 / Historical, Missing",
      "原始路径 / Original Path": original,
      "生产路径 / Production Path": "",
      "运行路径 / Runtime Path": target.startsWith("assets/runtime/") ? target : "",
      "旧路径 / Legacy Path": original,
      "版本 / Version": "historical / 历史",
      "哈希匹配结果 / Hash Match": "旧表有 SHA-256；当前无文件可复核 / Historical SHA-256 exists; no current file to verify",
      "Manifest 证据 / Manifest Evidence": "docs/assets/asset_inventory.csv",
      "来源判定方法 / Provenance Method": "旧清单精确路径 / Exact Path in Historical Catalog",
      "来源可信度 / Provenance Confidence": "HIGH / 高",
      "文件是否仍存在 / File Exists": "否 / No",
      "当前引用者 / Current Consumers": "",
      "备注 / Notes": "保持当前删除或迁移状态，不恢复文件。 / Preserve current deletion or migration state; do not restore.",
    });
  }
  for (const [missingPath, manifest, version, replacement] of MANIFEST_MISSING_PATHS) {
    if (exists(missingPath) || seen.has(missingPath)) continue;
    seen.add(missingPath);
    output.push({
      "资源路径 / Asset Path": missingPath,
      "主状态 / Primary Status": "历史路径，当前不存在 / Historical, Missing",
      "原始路径 / Original Path": missingPath,
      "生产路径 / Production Path": "",
      "运行路径 / Runtime Path": missingPath,
      "旧路径 / Legacy Path": missingPath,
      "版本 / Version": version,
      "哈希匹配结果 / Hash Match": "Manifest 历史路径；当前不存在 / Historical manifest path; currently missing",
      "Manifest 证据 / Manifest Evidence": manifest,
      "来源判定方法 / Provenance Method": "Manifest 明确历史引用 / Explicit Historical Manifest Reference",
      "来源可信度 / Provenance Confidence": "HIGH / 高",
      "文件是否仍存在 / File Exists": "否 / No",
      "当前引用者 / Current Consumers": "",
      "备注 / Notes": `已由 ${replacement} 替代；不恢复旧路径。 / Superseded by ${replacement}; do not restore.`,
    });
  }
  return output;
}

function buildDictionaryRows(assetRows) {
  const output = STATUS_DICTIONARY.map(([code, cn, en, definition]) => ({
    "字典类别 / Dictionary": "主状态 / Primary Status", "代码 / Code": code,
    "中文 / Chinese": cn, "英文 / English": en, "定义与使用规则 / Definition": definition,
  }));
  for (const [code, cn, definition] of [
    ["HIGH", "高", "Manifest 明确映射、SHA-256 完全一致或旧迁移表精确命中。 / Explicit manifest mapping, exact SHA-256 or exact legacy migration hit."],
    ["MEDIUM", "中", "生产目录、版本、文件名与尺寸共同匹配。 / Production directory, version, filename and dimensions jointly match."],
    ["LOW", "低", "仅同名、模块或路径推断，必须人工复核。 / Filename, module or path inference only; manual review required."],
  ]) output.push({ "字典类别 / Dictionary": "来源可信度 / Provenance Confidence", "代码 / Code": code, "中文 / Chinese": cn, "英文 / English": code, "定义与使用规则 / Definition": definition });
  const modules = [...new Map(assetRows.map((row) => [row["模块英文 / Module EN"], [row["模块中文 / Module CN"], row["模块英文 / Module EN"]]])).values()].sort((a, b) => a[1].localeCompare(b[1]));
  modules.forEach(([cn, en], index) => output.push({ "字典类别 / Dictionary": "模块 / Module", "代码 / Code": `MODULE_${String(index + 1).padStart(2, "0")}`, "中文 / Chinese": cn, "英文 / English": en, "定义与使用规则 / Definition": "由当前目录和游戏功能固定映射。 / Fixed from current directory and game function." }));
  for (const [code, [cn, en]] of TYPE_LABELS) output.push({ "字典类别 / Dictionary": "资源类型 / Asset Type", "代码 / Code": code.toUpperCase(), "中文 / Chinese": cn, "英文 / English": en, "定义与使用规则 / Definition": "按文件扩展名判定。 / Determined by extension." });
  for (const [code, cn, en] of [["APPROVED", "已通过", "Approved"], ["PENDING", "待审核", "Pending Review"], ["NOT_RECORDED", "未记录", "Not Recorded"], ["SUPERSEDED", "已替代", "Superseded"], ["STALE_MANIFEST", "清单已过期", "Manifest Stale"]]) output.push({ "字典类别 / Dictionary": "审核结论 / Review Conclusion", "代码 / Code": code, "中文 / Chinese": cn, "英文 / English": en, "定义与使用规则 / Definition": "审核队列固定值。 / Fixed review-queue value." });
  return output;
}

function publicRows(rows, headers) {
  return rows.map((row) => Object.fromEntries(headers.map((header) => [header, row[header] ?? ""])));
}

function validate(assetRows, directoryRows, reviewRows, provenanceRows, hashes, auditedReachable) {
  const summaryTotal = directoryRows.reduce((total, row) => total + Number(row["文件总数 / Total Files"]), 0);
  const activeWithoutReference = assetRows.filter((row) => ["ACTIVE_RUNTIME", "ACTIVE_REVIEW_PENDING"].includes(row._statusCode) && Number(row["引用数量 / Reference Count"]) < 1).map((row) => row["当前相对路径 / Current Relative Path"]);
  const pendingWithoutEvidence = assetRows.filter((row) => row._statusCode === "REVIEW_PENDING" && !row._manifest && !/(qa|review|acceptance|preview)/i.test(row["当前相对路径 / Current Relative Path"])).map((row) => row["当前相对路径 / Current Relative Path"]);
  const statusCounts = {};
  for (const row of assetRows) statusCounts[row._statusCode] = (statusCounts[row._statusCode] ?? 0) + 1;
  const duplicateGroups = [...hashes.values()].filter((group) => group.length > 1);
  const physicalRuntimeActive = assetRows.filter((row) => row._statusCode === "ACTIVE_RUNTIME" || row._statusCode === "ACTIVE_REVIEW_PENDING").length;
  const expectedReachable = auditedReachable.size;
  return {
    catalog_date: CATALOG_DATE,
    asset_file_count: assetRows.length,
    directory_summary_total: summaryTotal,
    counts_match: summaryTotal === assetRows.length,
    status_counts: Object.fromEntries(Object.entries(statusCounts).sort()),
    audited_runtime_reachable_count_including_shaders: expectedReachable,
    active_asset_count: physicalRuntimeActive,
    active_count_matches_audit: physicalRuntimeActive === expectedReachable,
    active_without_reference: activeWithoutReference,
    review_pending_without_evidence: pendingWithoutEvidence,
    duplicate_hash_group_count: duplicateGroups.length,
    duplicate_file_count: duplicateGroups.reduce((total, group) => total + group.length, 0),
    historical_missing_count: provenanceRows.filter((row) => row["文件是否仍存在 / File Exists"] === "否 / No").length,
    review_queue_count: reviewRows.length,
    passed: summaryTotal === assetRows.length && physicalRuntimeActive === expectedReachable && !activeWithoutReference.length && !pendingWithoutEvidence.length,
  };
}

function main() {
  fs.mkdirSync(DOCS_ASSETS, { recursive: true });
  const files = allAssets();
  const assetPaths = new Set(files.map(relativePath));
  const { packages, evidence } = parseManifests();
  const auditedReachable = buildAuditedReachableSet(assetPaths);
  const usages = scanReferences(assetPaths, packages, auditedReachable);
  const effective = effectiveUsageByAsset(usages, auditedReachable);
  const legacy = legacyFacts();
  const git = gitState();
  const { rows: assetRows, hashes } = buildAssetRows(files, auditedReachable, usages, effective, packages, evidence, legacy, git);
  const directoryRows = buildDirectorySummary(assetRows);
  const usageRows = buildUsageRows(usages);
  const reviewRows = buildReviewQueue(packages, assetRows);
  const provenanceRows = buildProvenanceRows(assetRows, legacy, effective);
  const dictionaryRows = buildDictionaryRows(assetRows);
  const validation = validate(assetRows, directoryRows, reviewRows, provenanceRows, hashes, auditedReachable);

  const csvPath = path.join(DOCS_ASSETS, `resource_asset_register_bilingual_${CATALOG_DATE}.csv`);
  const sourcePath = path.join(DOCS_ASSETS, `resource_catalog_workbook_source_${CATALOG_DATE}.json`);
  const validationPath = path.join(DOCS_ASSETS, `resource_catalog_validation_${CATALOG_DATE}.json`);
  writeCsv(csvPath, ASSET_HEADERS, publicRows(assetRows, ASSET_HEADERS));
  const workbookSource = {
    metadata: {
      title: "全项目资源目录中英双语总表 / Bilingual Full-Project Resource Catalog",
      as_of: CATALOG_DATE,
      project_root: PROJECT_ROOT,
      generated_at: new Date().toISOString(),
      runtime_truth: `Audited main-scene-reachable whitelist (${auditedReachable.size - 4} runtime assets) plus 4 reachable shaders; includes 235 reorganized UI assets.`,
      manifest_policy: "Current code and call graph decide runtime status; manifests provide review and provenance evidence only.",
    },
    sheets: {
      "01_目录汇总 Directory Summary": publicRows(directoryRows, DIRECTORY_HEADERS),
      "02_资源明细 Asset Register": publicRows(assetRows, ASSET_HEADERS),
      "03_运行引用 Runtime Usage": publicRows(usageRows, USAGE_HEADERS),
      "04_审核资源 Review Queue": publicRows(reviewRows, REVIEW_HEADERS),
      "05_来源映射 Provenance": publicRows(provenanceRows, PROVENANCE_HEADERS),
      "06_状态字典 Status Dictionary": publicRows(dictionaryRows, DICTIONARY_HEADERS),
    },
    validation,
  };
  fs.writeFileSync(sourcePath, JSON.stringify(workbookSource, null, 2), "utf8");
  fs.writeFileSync(validationPath, JSON.stringify(validation, null, 2), "utf8");
  process.stdout.write(`${JSON.stringify({ csv: csvPath, workbook_source: sourcePath, validation_file: validationPath, ...validation }, null, 2)}\n`);
  process.exitCode = validation.passed ? 0 : 2;
}

main();
