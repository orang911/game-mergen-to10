#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const date = "2026-08-21";
const catalogPath = path.join(repoRoot, "docs", "assets", "resource_catalog_workbook_source_2026-08-20.json");
const csvPath = path.join(repoRoot, "docs", "assets", `directory_structure_register_detailed_${date}.csv`);
const markdownPath = path.join(repoRoot, "docs", "assets", `directory_structure_cross_reference_detailed_${date}.md`);
const catalogSheet = "02_资源明细 Asset Register";

const scanRoots = [
  "assets/runtime",
  "shaders",
  "art/production",
  "art/ai_generated",
  "art/ui_slices",
  "art_source",
];

const field = {
  currentPath: "当前相对路径 / Current Relative Path",
  statusEn: "主状态英文 / Status EN",
  productionPath: "生产来源路径 / Production Source Path",
  originalPath: "原始来源路径 / Original Source Path",
  replacementPath: "替代后资源 / Replacement Asset",
};

const oldUiMappings = [
  ["assets/runtime/ui/battle", "assets/runtime/ui/interfaces/battle/**；印记选择见 interfaces/imprint_choice/**；棋盘组件见 components/**"],
  ["assets/runtime/ui/cards", "assets/runtime/ui/components/card_*/**；水晶卡选择见 interfaces/crystal_card_choice/**"],
  ["assets/runtime/ui/daily_program_composition_v01", "assets/runtime/ui/interfaces/daily_program/**"],
  ["assets/runtime/ui/daily_signin_hd_v01", "assets/runtime/ui/interfaces/daily_program/**"],
  ["assets/runtime/ui/daily_tasks_hd_v01", "assets/runtime/ui/interfaces/daily_program/**"],
  ["assets/runtime/ui/screens/main_hub_v2", "assets/runtime/ui/interfaces/main_hub/**；shared/meta_icons/**"],
  ["assets/runtime/ui/screens/skill_choice", "assets/runtime/ui/interfaces/imprint_choice/**"],
  ["assets/runtime/ui/screens/wave_choice", "assets/runtime/ui/interfaces/crystal_card_choice/**"],
  ["assets/runtime/ui/secondary_centered_v04", "assets/runtime/ui/interfaces/{battle_pause,exit_confirm,settings,first_purchase,piggy_bank,shop}/**；shared/**"],
  ["assets/runtime/ui/secondary", "assets/runtime/ui/interfaces/**；shared/**"],
];

function normalize(value) {
  return String(value ?? "").replaceAll("\\", "/").replace(/^res:\/\//, "").replace(/^\/+/, "");
}

function rel(absPath) {
  return path.relative(repoRoot, absPath).replaceAll("\\", "/");
}

function isInside(filePath, directoryPath) {
  return filePath === directoryPath || filePath.startsWith(`${directoryPath}/`);
}

function enumerateDirectories(rootRelative) {
  const rootAbsolute = path.join(repoRoot, rootRelative);
  if (!fs.existsSync(rootAbsolute)) return [];
  const found = [];
  function walk(absolute) {
    const relative = rel(absolute);
    found.push(relative);
    for (const entry of fs.readdirSync(absolute, { withFileTypes: true })) {
      if (!entry.isDirectory() || entry.name === ".godot" || entry.name === ".tmp") continue;
      walk(path.join(absolute, entry.name));
    }
  }
  walk(rootAbsolute);
  return found;
}

function directFileCount(directoryRelative) {
  const absolute = path.join(repoRoot, directoryRelative);
  return fs.readdirSync(absolute, { withFileTypes: true }).filter((entry) => entry.isFile() && !entry.name.endsWith(".import") && !entry.name.endsWith(".uid")).length;
}

function unique(values, limit = 4) {
  return [...new Set(values.filter(Boolean))].slice(0, limit);
}

function sourceDirectories(values) {
  return unique(values.map((value) => normalize(value)).filter((value) => value && !value.startsWith("assets/runtime/")).map((value) => path.posix.dirname(value)));
}

function classifyDirectory(directory) {
  if (/^assets\/runtime\/ui\/(interfaces|components|shared)(\/|$)/.test(directory)) {
    return { category: "当前运行 UI / Current Runtime UI", editable: "否；改 production 或图集源后重建 / No; edit production or atlas source then rebuild", atlas: "按子目录；atlas_regions/atlases/ 必须通过构建脚本维护" };
  }
  if (directory.startsWith("assets/runtime/ui/")) {
    return { category: "旧运行 UI 包 / Legacy Runtime UI Package", editable: "否；仅审核，不作为新增资源入口 / No; review only, not an intake location", atlas: "不新增图集 / No new atlas work" };
  }
  if (directory.startsWith("assets/runtime/")) {
    return { category: "当前运行资源 / Current Runtime Asset", editable: "否；改 production 源后同步 / No; edit production source then sync", atlas: "按运行图集脚本维护 / Build-script managed where applicable" };
  }
  if (directory === "shaders" || directory.startsWith("shaders/")) {
    return { category: "运行 Shader / Runtime Shader", editable: "是；修改后必须运行材质与主场景校验 / Yes; run material and main-scene checks", atlas: "不适用 / N/A" };
  }
  if (directory.startsWith("art/production/")) {
    return { category: "生产可编辑源 / Editable Production Source", editable: "是；此处是美术修改入口 / Yes; art-editing entry point", atlas: "runtime_atlas_sources/** 修改后运行图集构建" };
  }
  if (directory.startsWith("art/ai_generated/")) {
    return { category: "AI 原始产物 / AI Original", editable: "否；保留来源，复制到 production 后再加工 / No; preserve origin, copy into production to edit", atlas: "不直接打包 / Never pack directly" };
  }
  return { category: "历史来源 / Historical Source", editable: "否；只作溯源与审核 / No; traceability and review only", atlas: "不直接打包 / Never pack directly" };
}

function legacyMapping(directory) {
  const matched = oldUiMappings.find(([oldRoot]) => isInside(directory, oldRoot));
  return matched ? matched[1] : "—";
}

function shortList(values) {
  const list = unique(values, 3);
  return list.length ? list.join(" | ") : "—";
}

function pathCompare(a, b) {
  return a === b ? 0 : (a < b ? -1 : 1);
}

function statusSummary(records, category) {
  const active = records.filter((record) => ["Active Runtime", "Active, Review Pending"].includes(record[field.statusEn]));
  const pending = records.filter((record) => record[field.statusEn] === "Active, Review Pending");
  const unreferenced = records.filter((record) => record[field.statusEn] === "Runtime, No Reference Found");
  if (category.includes("旧运行 UI")) return "旧包；不作为当前入口 / Legacy package; not current intake";
  if (active.length) return pending.length ? `在用待审核 ${active.length}（其中待审 ${pending.length}） / Active pending review` : `正在使用 ${active.length} / Active`;
  if (unreferenced.length) return `未发现运行引用 ${unreferenced.length} / No runtime reference found`;
  return records.length ? "生产/历史资源 / Production or historical" : "空目录或仅含非总账文件 / Empty or non-catalog files only";
}

function csvCell(value) {
  const text = String(value ?? "");
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

const workbook = JSON.parse(fs.readFileSync(catalogPath, "utf8"));
const assets = workbook.sheets?.[catalogSheet];
if (!Array.isArray(assets)) throw new Error(`Missing catalog sheet: ${catalogSheet}`);

const directories = [...new Set(scanRoots.flatMap(enumerateDirectories))].sort(pathCompare);
const rows = directories.map((directory, index) => {
  const info = classifyDirectory(directory);
  const records = assets.filter((asset) => isInside(normalize(asset[field.currentPath]), directory));
  const activeRecords = records.filter((asset) => ["Active Runtime", "Active, Review Pending"].includes(asset[field.statusEn]));
  const productionSources = sourceDirectories(activeRecords.map((asset) => asset[field.productionPath]));
  const originalSources = sourceDirectories(activeRecords.map((asset) => asset[field.originalPath]));
  const productionConsumerRecords = assets.filter((asset) => {
    const productionPath = normalize(asset[field.productionPath]);
    const runtimePath = normalize(asset[field.currentPath]);
    return isInside(productionPath, directory) && runtimePath.startsWith("assets/runtime/");
  });
  const runtimeConsumers = unique(productionConsumerRecords.flatMap((asset) => [
    normalize(asset[field.currentPath]),
    ...String(asset[field.replacementPath] ?? "").split("|").map(normalize),
  ]).filter((value) => value.startsWith("assets/runtime/")), 4);
  const level = directory.split("/").length - 1;
  const parent = level ? directory.split("/").slice(0, -1).join("/") : "—";
  const mapping = info.category.includes("旧运行 UI")
    ? legacyMapping(directory)
    : info.category.includes("生产可编辑")
      ? shortList(runtimeConsumers.map((value) => path.posix.dirname(value)))
      : shortList(productionSources);

  return {
    "序号 / ID": String(index + 1),
    "层级 / Depth": String(level),
    "当前目录 / Current Directory": `${directory}/`,
    "父目录 / Parent Directory": parent === "—" ? "—" : `${parent}/`,
    "目录类别 / Directory Category": info.category,
    "状态 / Status": statusSummary(records, info.category),
    "直属文件数 / Direct Files": String(directFileCount(directory)),
    "目录内总账资源数 / Catalog Assets Under Directory": String(records.length),
    "当前在用资源数 / Active Assets": String(activeRecords.length),
    "对应运行或生产目录 / Runtime or Production Counterpart": mapping,
    "原始来源目录 / Original Source Directories": shortList(originalSources),
    "可否直接修改 / Direct Editing": info.editable,
    "图集规则 / Atlas Rule": info.atlas,
  };
});

const headers = Object.keys(rows[0] ?? {});
fs.writeFileSync(csvPath, [headers.join(","), ...rows.map((row) => headers.map((name) => csvCell(row[name])).join(","))].join("\n") + "\n", "utf8");

const rootsSummary = scanRoots.map((root) => ({
  root,
  directories: rows.filter((row) => row["当前目录 / Current Directory"].startsWith(`${root}/`)).length,
}));
const currentUiRows = rows.filter((row) => row["目录类别 / Directory Category"] === "当前运行 UI / Current Runtime UI");
const legacyUiRows = rows.filter((row) => row["目录类别 / Directory Category"] === "旧运行 UI 包 / Legacy Runtime UI Package");

function treeTag(row) {
  const category = row["目录类别 / Directory Category"];
  const status = row["状态 / Status"];
  if (category === "当前运行 UI / Current Runtime UI") return status.includes("待审核") ? "🟡 运行待审" : "🟢 当前运行";
  if (category === "旧运行 UI 包 / Legacy Runtime UI Package") return "🟠 旧包";
  if (category === "生产可编辑源 / Editable Production Source") return "🔵 生产源";
  if (category === "AI 原始产物 / AI Original") return "🟣 AI原图";
  if (category === "历史来源 / Historical Source") return "⚪ 历史来源";
  return "🟢 运行资源";
}

function renderTree(treeRows) {
  const rowByDirectory = new Map(treeRows.map((row) => [row["当前目录 / Current Directory"].replace(/\/$/, ""), row]));
  const root = { children: new Map(), row: null, name: "" };
  for (const directory of rowByDirectory.keys()) {
    const parts = directory.split("/");
    let cursor = root;
    const accumulated = [];
    for (const part of parts) {
      accumulated.push(part);
      if (!cursor.children.has(part)) cursor.children.set(part, { children: new Map(), row: null, name: part });
      cursor = cursor.children.get(part);
      cursor.row ??= rowByDirectory.get(accumulated.join("/")) ?? null;
    }
  }
  const output = [];
  function visit(node, prefix, isLast, isTop) {
    const branch = isTop ? "" : (isLast ? "└─ " : "├─ ");
    const nextPrefix = isTop ? "" : `${prefix}${isLast ? "   " : "│  "}`;
    const row = node.row;
    const detail = row
      ? `  ${treeTag(row)} · 在用 ${row["当前在用资源数 / Active Assets"]} · 目录资源 ${row["目录内总账资源数 / Catalog Assets Under Directory"]}`
      : "  虚拟父级 / virtual parent";
    output.push(`${prefix}${branch}${node.name}/ ${detail}`.trimEnd());
    const children = [...node.children.values()].sort((a, b) => pathCompare(a.name, b.name));
    children.forEach((child, index) => visit(child, nextPrefix, index === children.length - 1, false));
  }
  const top = [...root.children.values()].sort((a, b) => pathCompare(a.name, b.name));
  top.forEach((node, index) => visit(node, "", index === top.length - 1, true));
  return output.join("\n");
}

const currentUiTree = renderTree(currentUiRows);
const fullTree = renderTree(rows);

const markdown = `# 逐子目录结构对照 / Detailed Directory Structure Cross-Reference

更新日期：\`${date}\`  
生成方式：\`node tools/build_detailed_directory_cross_reference.mjs\`

这份文档改为树状阅读：每一个当前存在的资源子目录都显示在完整树内。逐文件级的哈希、引用和来源仍以 \`resource_asset_register_bilingual_2026-08-20.csv\` 为准；逐目录的生产/运行对应关系、修改规则和图集规则请在同名 CSV 中筛选。

## 使用规则

- 要改运行中的 UI：先在 \`assets/runtime/ui/interfaces/**\`、\`components/**\`、\`shared/**\` 找到成品，再跳转到本表“对应运行或生产目录”列的生产源修改。
- \`assets/runtime/ui/\` 下未进入上述三层的旧包不是当前新增资源入口；它们仍在磁盘上，仅供审核与溯源，不能直接删除。
- \`art/production/**\` 是可编辑源；\`art/ai_generated/**\`、\`art/ui_slices/**\`、\`art_source/**\` 是来源或历史区，不能直接作为运行资源。
- 图集目录中的 \`atlas_regions/\` 和 \`atlases/\` 必须通过 \`tools/build_runtime_atlases.ps1\` 重建，不能只手工改 TRES 或图集原图。

## 扫描范围

| 顶层根目录 | 子目录数 |
|---|---:|
${rootsSummary.map((item) => `| \`${item.root}/\` | ${item.directories} |`).join("\n")}

总计：\`${rows.length}\` 个目录；当前 UI 结构目录 \`${currentUiRows.length}\` 个，旧 UI 包目录 \`${legacyUiRows.length}\` 个。

## 当前 UI 完整结构（可直接修改入口）

图例：\`🟢 当前运行\`、\`🟡 运行待审核\`、\`🟠 旧包（不再新增）\`、\`🔵 生产可编辑源\`、\`🟣 AI 原图\`、\`⚪ 历史来源\`。  
节点信息：\`在用\` 是当前可达资源数；\`目录资源\` 包含该目录下所有子目录的总账资源数。

\`\`\`text
${currentUiTree}
\`\`\`

## 全项目资源目录树（全部 359 个目录）

<details>
<summary>展开完整目录树：运行资源、生产源、AI 原图与历史来源</summary>

\`\`\`text
${fullTree}
\`\`\`

</details>

## 逐目录对照与修改入口

- [\`directory_structure_register_detailed_${date}.csv\`](directory_structure_register_detailed_${date}.csv) 保留全部 \`${rows.length}\` 个目录的一行式对照，可按“当前目录、父目录、状态、对应目录、直接修改、图集规则”筛选。
- 运行 UI 的修改入口遵循：\`assets/runtime/ui/interfaces/**\`、\`components/**\`、\`shared/**\` 是成品定位区；生产源目录才是美术修改区。
- \`assets/runtime/ui/\` 中未进入上述三层的目录均是 \`🟠 旧包\`，只用于审核、来源追溯和历史回退判断。

## 字段说明

- **直属文件**：仅当前目录下一层文件，不含子目录；不计 \`.import\`、\`.uid\`。
- **目录内资源**：该目录及其全部子目录在资源总账中的有效资源数量。
- **对应运行或生产目录**：当前运行目录优先展示生产修改入口；生产目录优先展示当前运行去向；旧 UI 包展示其当前替代入口。模块级候选不等于逐文件替代关系。
- **直接修改**与**图集规则**完整字段请使用同名 CSV 过滤查看。

## 不允许的操作

1. 不要把新资源放回 \`battle/\`、\`cards/\`、\`screens/\`、\`secondary_centered_v04/\` 等旧 UI 包。
2. 不要因“未发现引用”直接删除目录或文件；先通过 \`runtime_unreferenced_review_queue_2026-08-20.csv\` 审核。
3. 不要把生产图、AI 原图、QA 图放入 \`assets/runtime/**\`。
4. 不要手动破坏图集与 AtlasTexture TRES 的对应关系。
`;
fs.writeFileSync(markdownPath, markdown, "utf8");

console.log(JSON.stringify({
  markdown: rel(markdownPath),
  csv: rel(csvPath),
  directory_count: rows.length,
  current_ui_directory_count: currentUiRows.length,
  legacy_ui_directory_count: legacyUiRows.length,
}, null, 2));
