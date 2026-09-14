# 资源归整后续执行状态

更新日期：2026-08-20

## 阶段状态

- **phase**: `completed`
- 范围：仅执行 `docs/assets/resource_reorganization_followup_plan_2026-08-20.md` 的 P0（P0-A 导出包收缩 + P0-B 非 UI 图集来源链修复）。
- 约束遵守：不删除、不恢复、不覆盖历史文件；不修改玩法。本轮重建的 12 张运行图集与 72 个 AtlasTexture 区域文件经解码像素/字节比对与重建前一致，无内容漂移。

## 上一会话变更保全

已检查并保留上一 Claude 会话的工作，未回退、未覆盖：

- `export_presets.cfg`：Web 预设保留 `export_filter="all_resources"`，并已写入与 Android 预设完全一致的 `exclude_filter`；Android ARM64 预设为上一会话新增。
- `art/production/`：`characters`、`fx`、`ui` 三棵 `runtime_atlas_sources/2026-08-20/` 源切图，以及 `non_ui_runtime_atlas_sources_manifest_2026-08-20.csv`（114 条）。
- `docs/assets/`：双语资源总账、目录对照、UI 迁移表与报告、总账校验、非 UI 图集来源扫描等新文件。
- `tools/`：图集构建/校验/像素对比/来源扫描/目录构建等既有工具。
- `assets/runtime/` 的 489 项归整删除/迁移工作区变更保持原样，未恢复任何旧路径文件。
- 上一会话 Web 收缩导出 `builds/web_export_shrink_2026-08-20/` 保留未覆盖。

## 完成摘要

### P0-A：收缩正式导出包

- **完成**。Web 预设保持 `all_resources`，`exclude_filter` 与 Android 预设逐字一致：
  `art/**,artifacts/**,art_source/**,asset_review_delete/**,build/**,build-templates/**,builds/**,docs/**,imge/**,library/**,local/**,packages/**,settings/**,temp/**,tests/**,tools/**,.tmp/**`
- **通过**。运行时消费者对排除根目录的 `res://` 引用校验：扫描 `163` 个消费者文件、`410` 条 `res://` 引用，指向排除根目录的引用为 `0`。
- **通过**。Web 冒烟导出到新目录 `builds/web_export_shrink_p0_2026-08-20/`，`index.pck` 实测 `35,678,268` 字节（收缩前参考基线 `330,256,600` 字节，为 `builds/ui_reorganization_smoke_2026-08-20/index.pck`）。
- 导出日志 savepack 阶段进入包的排除根目录条目数为 `0`；日志无 ERROR/缺失/失败。

### P0-B：修复非 UI 图集的来源链

- **完成**。以当前 8 组非 UI 运行图集为当前像素事实源，已具备重建全部 8 组的工具与生产源 Manifest：
  - `non_ui_atlas_source_scan_2026-08-20.json`：8 组、`total_present=114`、`total_missing=0`。
  - `art/production/non_ui_runtime_atlas_sources_manifest_2026-08-20.csv`：114 条无损反切记录。
- **完成**。传送门采用 20 帧当前尺寸 `320×320` 反切帧（`art/production/fx/runtime_atlas_sources/2026-08-20/portal/frame_00..19.png`），构建器不再指向缺失的高清 `gate_portal_sheet.png`；构建器内已加注释说明来源。
- **完成**。图集构建器 `-Scope All` 现在显式断言 `12` 组（8 非 UI + 4 UI）；`-Scope UI` 仍断言 `4` 组。
- **通过**。`-Scope All` 重建 + 校验：`ATLAS_BUILD_OK scope=ALL groups=12`，`ATLAS_VERIFY_OK scope=ALL groups=12`，`ATLAS_VERIFY_OK scope=UI groups=4`。
- **通过**。重建前后 RGBA 解码像素对比：12 张图集全部 `PIXEL_MATCH`，`ATLAS_PIXEL_COMPARE_OK all=12`；72 个 AtlasTexture 区域文件字节级一致（`same=72 diffs=0`）。
- Headless 主场景冒烟（`--quit-after 5`）退出码 `0`，无脚本/资源错误。

## 命令与输出

```bash
# P0-A 排除根目录引用校验（新增工具）
node tools/validate_export_exclusions.mjs
# => Consumer files scanned: 163
# => res:// references found: 410
# => References into excluded roots: 0
# => RESULT: PASS

# P0-A Web 冒烟导出（新目录）
"/c/Users/PC/AppData/Local/Programs/Godot/4.7/Godot_v4.7-stable_win64_console.exe" \
  --headless --path . --export-debug "Web Test" \
  "builds/web_export_shrink_p0_2026-08-20/index.html" \
  > builds/web_export_shrink_p0_2026-08-20.log 2>&1
# => EXIT=0；index.pck = 35,678,268 bytes；排除根目录 savepack 条目 = 0

# P0-B 非 UI 来源扫描
node tools/scan_atlas_sources.mjs
# => TOTAL present=114 missing=0

# P0-B 重建前基线快照（12 张图集）
node tools/snapshot_atlas_baseline.mjs
# => BASELINE_ROOT .tmp/atlas_verify_baseline_2026-08-20

# P0-B 全范围重建
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/build_runtime_atlases.ps1 -Mode Build -Scope All
# => BUILT ×12；ATLAS_BUILD_OK scope=ALL groups=12

# P0-B 重建前后 RGBA 像素对比
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/compare_atlas_pixels.ps1
# => PIXEL_MATCH ×12；ATLAS_PIXEL_COMPARE_OK all=12

# P0-B 全范围 + UI 范围校验
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/build_runtime_atlases.ps1 -Mode Verify -Scope All
# => ATLAS_VERIFY_OK scope=ALL groups=12
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/build_runtime_atlases.ps1 -Mode Verify -Scope UI
# => ATLAS_VERIFY_OK scope=UI groups=4

# 72 个 AtlasTexture 区域文件字节一致性校验
node .tmp/compare_tres.mjs
# => TRES same=72 diffs=0 missing_backup=0 total=72

# Headless 主场景冒烟
"/c/Users/PC/AppData/Local/Programs/Godot/4.7/Godot_v4.7-stable_win64_console.exe" \
  --headless --path . --quit-after 5
# => EXIT=0，无错误输出
```

## 变更文件

本轮新增/修改：

- 新增 `docs/assets/claude_resource_followup_execution_status_2026-08-20.md`
- 新增 `tools/validate_export_exclusions.mjs`
- 修改 `tools/build_runtime_atlases.ps1`（All 范围 12 组断言 + 传送门来源注释）
- 修改 `tools/snapshot_atlas_baseline.mjs`（基线快照扩展到 12 张图集）
- 修改 `tools/compare_atlas_pixels.ps1`（像素对比扩展到 12 张图集）
- 重写（无损，内容不变）：`assets/runtime/**/atlases/*.png` 12 张、`assets/runtime/ui/**/atlas_regions/*.tres` 72 个
- 刷新 `docs/assets/non_ui_atlas_source_scan_2026-08-20.json`（扫描时间戳更新，数据不变）
- 生成 `builds/web_export_shrink_p0_2026-08-20/`（Web 导出产物与日志）

临时产物（位于 `.tmp/`，不进版本库）：

- `.tmp/atlas_verify_baseline_2026-08-20/`
- `.tmp/atlas_tres_baseline_2026-08-20/`
- `.tmp/compare_tres.mjs`
- `.tmp/headless_smoke_p0.log`

## 阻塞项

无。

---

## P1-A：运行目录未引用资源审核包

- **phase**: `completed`
- 范围：为 189 个 `RUNTIME_UNREFERENCED` 资源建立可审核证据清单；不删除、不恢复、不移动任何资源。
- 新增生成器：`tools/build_runtime_unreferenced_review_queue.mjs`。
- 新增审核表：`docs/assets/runtime_unreferenced_review_queue_2026-08-20.csv`。
- 校验通过：审核表 `189` 行、`189` 条唯一当前路径；与当前总账的未引用资源数量一致。

### 审核表字段

- 中英文名称、模块和当前路径。
- 静态引用证据、动态加载人工复核提示、精确替代资源和模块级替代候选。
- 来源可信度、建议处理、责任人、审批要求和原始备注。

### 建议处理规则

- 有精确替代资源，或有模块级替代候选且原备注明确为旧函数/不可达分支：`已替代，归档候选`。
- Shader 和缺少可验证替代关系的资源：`保留`或`保留待核`。
- 所有行均标记为“需要审批”；本轮未生成删除候选的自动执行操作。

### 分模块数量

- Secondary UI：98
- Daily Program UI：25
- Daily Tasks UI：19
- Daily Sign-In UI：15
- Imprint Choice UI：12
- Main Hub UI：10
- Card UI：4
- Skill Choice UI：3
- Shaders：2
- Wave Choice UI：1

### 命令与输出

```bash
node --check tools/build_runtime_unreferenced_review_queue.mjs
node tools/build_runtime_unreferenced_review_queue.mjs
# => rows=189; unique_paths=189
```

## P1-B：视觉审核准备、Manifest 与总账刷新

- **phase**: `prepared`
- 新增 `tools/build_active_review_queue.mjs`，从总账生成 56 项 `ACTIVE_REVIEW_PENDING` 的逐资源视觉审核队列。
- 新增 `docs/assets/active_review_visual_queue_2026-08-20.csv`；校验通过：`56` 行、`56` 条唯一运行路径。
- 队列按模块覆盖：Daily Program 26、Benefits 8、Shared 8、Shop 5、Settings 3、First Purchase 3，以及暂停、退出确认、存钱罐各 1。
- 每行均包含生产/QA证据路径，并锁定白灰黑底、941×1672、720×1600、1080×1920、设备和最终视觉审核关卡；本轮没有将任何资产标记为最终通过。
- Chapter01 运行 Manifest 已归一：物理包版本 `v04`、`manifest_revision` 为 `v10`，并保留历史内部版本 `v09` 与归一说明。
- 已执行 `node tools/build_resource_catalog.mjs` 刷新 CSV、工作簿源 JSON、校验 JSON 与文档索引。

### 当前总账验证

- 当前物理资源：`1379`；目录汇总与资源明细一致。
- `ACTIVE_RUNTIME`：224；`ACTIVE_REVIEW_PENDING`：56；`RUNTIME_UNREFERENCED`：189。
- 当前可达运行资源：280；`active_without_reference=[]`；总账自动验收通过。

### 仍需人工或环境关卡

1. 根据 `active_review_visual_queue_2026-08-20.csv` 完成实际设备、截图与最终美术审核，并回写结论。
2. 项目规定的工作簿生成运行时仍不可用；因此 `resource_catalog_bilingual_2026-08-20.xlsx` 未生成，也未创建任何占位文件。
