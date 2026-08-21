#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourcePath = path.join(repoRoot, "docs", "assets", "resource_catalog_workbook_source_2026-08-20.json");
const outputPath = path.join(repoRoot, "docs", "assets", "runtime_unreferenced_review_queue_2026-08-20.csv");
const sheetName = "02_资源明细 Asset Register";

const columns = {
  rowId: "行号 / Row ID",
  nameCn: "资源中文名 / Asset Name CN",
  nameEn: "资源英文名 / Asset Name EN",
  moduleCn: "模块中文 / Module CN",
  moduleEn: "模块英文 / Module EN",
  statusEn: "主状态英文 / Status EN",
  currentPath: "当前相对路径 / Current Relative Path",
  referenceCount: "引用数量 / Reference Count",
  primaryReferences: "主要引用位置 / Primary References",
  replacement: "替代后资源 / Replacement Asset",
  provenance: "来源可信度 / Provenance Confidence",
  notes: "备注与行动 / Notes and Action",
};

const packageCandidates = new Map([
  ["Secondary UI", "assets/runtime/ui/interfaces/** and assets/runtime/ui/shared/**"],
  ["Daily Program UI", "assets/runtime/ui/interfaces/daily_program/**"],
  ["Daily Tasks UI", "assets/runtime/ui/interfaces/daily_program/**"],
  ["Daily Sign-In UI", "assets/runtime/ui/interfaces/daily_program/**"],
  ["Imprint Choice UI", "assets/runtime/ui/interfaces/imprint_choice/**"],
  ["Main Hub UI", "assets/runtime/ui/interfaces/main_hub/**"],
  ["Card UI", "assets/runtime/ui/components/card_icons/**"],
  ["Skill Choice UI", "assets/runtime/ui/interfaces/imprint_choice/**"],
  ["Wave Choice UI", "assets/runtime/ui/interfaces/crystal_card_choice/**"],
]);

function csvCell(value) {
  const text = String(value ?? "");
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function get(record, key) {
  return record[key] ?? "";
}

const workbook = JSON.parse(fs.readFileSync(sourcePath, "utf8"));
const records = workbook.sheets?.[sheetName];
if (!Array.isArray(records)) {
  throw new Error(`Missing sheet: ${sheetName}`);
}

const rows = records
  .filter((record) => get(record, columns.statusEn) === "Runtime, No Reference Found")
  .sort((a, b) => {
    const byModule = get(a, columns.moduleEn).localeCompare(get(b, columns.moduleEn), "en");
    return byModule || get(a, columns.currentPath).localeCompare(get(b, columns.currentPath), "en");
  })
  .map((record, index) => {
    const moduleEn = get(record, columns.moduleEn);
    const notes = get(record, columns.notes);
    const exactReplacement = get(record, columns.replacement);
    const packageCandidate = packageCandidates.get(moduleEn) ?? "";
    const legacyEvidence = /legacy|unreachable|旧函数|不可达|未发现当前运行引用/i.test(notes);
    const isShader = moduleEn === "Shaders";
    const recommended = isShader
      ? "保留 / Retain"
      : exactReplacement || (packageCandidate && legacyEvidence)
        ? "已替代，归档候选 / Superseded Archive Candidate"
        : "保留待核 / Retain Pending Review";
    const replacementEvidence = exactReplacement
      ? `明确替代 / Exact replacement: ${exactReplacement}`
      : packageCandidate
        ? `模块级候选，非逐文件映射 / Package-level candidate only: ${packageCandidate}`
        : "未找到替代映射 / No replacement mapping found";
    const dynamicEvidence = legacyEvidence
      ? "旧函数或不可达分支线索；须人工确认动态加载 / Legacy or unreachable-branch evidence; confirm dynamic loading manually"
      : "清单未记录动态加载；须人工确认 / No dynamic-load evidence in catalog; confirm manually";
    const staticReferences = Number(get(record, columns.referenceCount) || 0);
    const primaryReferences = get(record, columns.primaryReferences);

    return {
      "审核行号 / Review Row ID": String(index + 1),
      "原总账行号 / Catalog Row ID": get(record, columns.rowId),
      "资源中文名 / Asset Name CN": get(record, columns.nameCn),
      "资源英文名 / Asset Name EN": get(record, columns.nameEn),
      "模块中文 / Module CN": get(record, columns.moduleCn),
      "模块英文 / Module EN": moduleEn,
      "当前路径 / Current Path": get(record, columns.currentPath),
      "静态引用证据 / Static Reference Evidence": staticReferences > 0
        ? `静态引用数 ${staticReferences} / Static references ${staticReferences}: ${primaryReferences}`
        : "当前静态扫描未发现引用 / No current static reference found",
      "动态加载证据 / Dynamic Loading Evidence": dynamicEvidence,
      "替代资源 / Exact Replacement": exactReplacement,
      "替代包候选 / Replacement Package Candidate": packageCandidate,
      "替代证据 / Replacement Evidence": replacementEvidence,
      "来源可信度 / Provenance Confidence": get(record, columns.provenance),
      "建议处理 / Recommended Disposition": recommended,
      "责任人 / Owner": "资源工程复核 / Resource Engineering Review",
      "需要审批 / Approval Required": "是 / Yes",
      "原始备注 / Original Notes": notes,
    };
  });

const uniquePaths = new Set(rows.map((row) => row["当前路径 / Current Path"]));
if (rows.length !== uniquePaths.size) {
  throw new Error(`Duplicate current paths in review queue: rows=${rows.length} unique=${uniquePaths.size}`);
}

const headers = Object.keys(rows[0] ?? {});
const csv = [headers.join(","), ...rows.map((row) => headers.map((header) => csvCell(row[header])).join(","))].join("\n") + "\n";
fs.writeFileSync(outputPath, csv, "utf8");

const moduleCounts = Object.fromEntries(rows.reduce((counts, row) => {
  const key = row["模块英文 / Module EN"];
  counts.set(key, (counts.get(key) ?? 0) + 1);
  return counts;
}, new Map()));

console.log(JSON.stringify({
  source: path.relative(repoRoot, sourcePath).replaceAll("\\", "/"),
  output: path.relative(repoRoot, outputPath).replaceAll("\\", "/"),
  rows: rows.length,
  unique_paths: uniquePaths.size,
  module_counts: moduleCounts,
}, null, 2));
