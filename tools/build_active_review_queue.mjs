#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourcePath = path.join(repoRoot, "docs", "assets", "resource_catalog_workbook_source_2026-08-20.json");
const outputPath = path.join(repoRoot, "docs", "assets", "active_review_visual_queue_2026-08-20.csv");
const sheetName = "02_资源明细 Asset Register";

const field = {
  rowId: "行号 / Row ID",
  nameCn: "资源中文名 / Asset Name CN",
  nameEn: "资源英文名 / Asset Name EN",
  moduleCn: "模块中文 / Module CN",
  moduleEn: "模块英文 / Module EN",
  statusEn: "主状态英文 / Status EN",
  path: "当前相对路径 / Current Relative Path",
  version: "当前运行版本 / Runtime Version",
  production: "生产来源路径 / Production Source Path",
  alpha: "Alpha 状态 / Alpha",
  notes: "备注与行动 / Notes and Action",
};

const csv = (value) => {
  const text = String(value ?? "");
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
};

const workbook = JSON.parse(fs.readFileSync(sourcePath, "utf8"));
const sourceRows = workbook.sheets?.[sheetName];
if (!Array.isArray(sourceRows)) throw new Error(`Missing sheet: ${sheetName}`);

const rows = sourceRows
  .filter((row) => row[field.statusEn] === "Active, Review Pending")
  .sort((a, b) => (a[field.moduleEn] ?? "").localeCompare(b[field.moduleEn] ?? "", "en") || (a[field.path] ?? "").localeCompare(b[field.path] ?? "", "en"))
  .map((row, index) => ({
    "审核行号 / Review Row ID": String(index + 1),
    "原总账行号 / Catalog Row ID": row[field.rowId] ?? "",
    "资源中文名 / Asset Name CN": row[field.nameCn] ?? "",
    "资源英文名 / Asset Name EN": row[field.nameEn] ?? "",
    "模块中文 / Module CN": row[field.moduleCn] ?? "",
    "模块英文 / Module EN": row[field.moduleEn] ?? "",
    "运行路径 / Runtime Path": row[field.path] ?? "",
    "当前版本 / Runtime Version": row[field.version] ?? "",
    "生产与QA证据路径 / Production and QA Evidence": row[field.production] ?? "",
    "透明底检查 / White Gray Black QA": /true|是/i.test(row[field.alpha] ?? "") ? "待审核 / Required" : "不适用或按组件审核 / N/A or component-level",
    "Godot截图 / Godot Screenshot": "待生成：941x1672、720x1600、1080x1920 / Pending",
    "设备审核 / Device Review": "待审核 / Pending",
    "最终视觉审核 / Final Visual Review": "待审核 / Pending",
    "审核责任 / Review Owner": "UI美术 + QA + 策划终审 / UI Art + QA + Design Final Review",
    "当前备注 / Current Notes": row[field.notes] ?? "",
  }));

const unique = new Set(rows.map((row) => row["运行路径 / Runtime Path"]));
if (rows.length !== unique.size) throw new Error(`Duplicate review paths: rows=${rows.length}, unique=${unique.size}`);
const headers = Object.keys(rows[0] ?? {});
fs.writeFileSync(outputPath, [headers.join(","), ...rows.map((row) => headers.map((name) => csv(row[name])).join(","))].join("\n") + "\n", "utf8");

const moduleCounts = Object.fromEntries(rows.reduce((map, row) => {
  const key = row["模块英文 / Module EN"];
  map.set(key, (map.get(key) ?? 0) + 1);
  return map;
}, new Map()));
console.log(JSON.stringify({ output: path.relative(repoRoot, outputPath).replaceAll("\\", "/"), rows: rows.length, unique_paths: unique.size, module_counts: moduleCounts }, null, 2));
