# 原项目文档迁移说明

日期：2026-09-13，v01。来源 `D:/UGit/UGit/TO10`，目标为本工程 `Docs/LegacyGodot/2026-09-13_v01`。

复制全部 docs 文件（包括 CSV/JSON 资源台账及 archive），以及根目录 AGENTS.md、MIGRATION_GODOT.md、PROJECT_DIRECTION.md。原样保留内容和相对层级，不搬走源文件。SHA256及字节数见 [复制清单](legacy_manifest_2026-09-13_v01.json)。

## 使用范围

- 00–10、13、24、26：产品/规则/架构参考；实际行为还须对照已批准冻结代码。
- 27、28、31、32及assets：视觉生产、二级页、UI审查、资源映射资料；旧路径保留溯源，不是Unity可加载路径。
- 29、30：连锁/共鸣后续实装资料，避免被早期两次点击/旧队列描述覆盖。
- 12、14–23、archive：旧计划、卡牌提案和实验，不自动升级为迁移需求。
- 根目录 MIGRATION_GODOT.md 记述更早的 Cocos→Godot 迁移，不是本次 Godot→Unity 完成清单。
- 归档 AGENTS.md 只用于追溯旧工程规则，不复制为 Unity 根目录执行规则。

## 链接与附件边界

本次迁移的是文档及 docs 内附件，未复制整套运行资源和 docs 外的美术/构建产物。原文中的 `res://`、旧F盘绝对路径、指向 scripts/scenes/builds 的引用保留历史含义，需要查阅冻结源码或原项目。原README引用的 `25_chapter01_modal_ui_audit_2026-07-29/二级弹窗优化需求.md` 在本次活动docs目录中不存在，标记为源缺失，未伪造补齐。

## 已迁移文件索引

|原相对路径|迁移后原文|
|---|---|
|docs/00_current_product_baseline.md|[查看](<LegacyGodot/2026-09-13_v01/docs/00_current_product_baseline.md>)|
|docs/01_current_state.md|[查看](<LegacyGodot/2026-09-13_v01/docs/01_current_state.md>)|
|docs/02_core_merge_rules.md|[查看](<LegacyGodot/2026-09-13_v01/docs/02_core_merge_rules.md>)|
|docs/03_combat_design.md|[查看](<LegacyGodot/2026-09-13_v01/docs/03_combat_design.md>)|
|docs/04_attack_crystal_design.md|[查看](<LegacyGodot/2026-09-13_v01/docs/04_attack_crystal_design.md>)|
|docs/05_technical_architecture.md|[查看](<LegacyGodot/2026-09-13_v01/docs/05_technical_architecture.md>)|
|docs/06_visual_scene_plan.md|[查看](<LegacyGodot/2026-09-13_v01/docs/06_visual_scene_plan.md>)|
|docs/07_roadmap.md|[查看](<LegacyGodot/2026-09-13_v01/docs/07_roadmap.md>)|
|docs/08_open_questions.md|[查看](<LegacyGodot/2026-09-13_v01/docs/08_open_questions.md>)|
|docs/09_decision_log.md|[查看](<LegacyGodot/2026-09-13_v01/docs/09_decision_log.md>)|
|docs/10_architecture_maintenance_art_effects.md|[查看](<LegacyGodot/2026-09-13_v01/docs/10_architecture_maintenance_art_effects.md>)|
|docs/11_web_smoke_test_2026-07-08.md|[查看](<LegacyGodot/2026-09-13_v01/docs/11_web_smoke_test_2026-07-08.md>)|
|docs/12_execution_plan_2026-07-15.md|[查看](<LegacyGodot/2026-09-13_v01/docs/12_execution_plan_2026-07-15.md>)|
|docs/13_skill_imprint_mechanism.md|[查看](<LegacyGodot/2026-09-13_v01/docs/13_skill_imprint_mechanism.md>)|
|docs/14_initial_card_catalog.md|[查看](<LegacyGodot/2026-09-13_v01/docs/14_initial_card_catalog.md>)|
|docs/15_unified_card_wave_rules_2026-07-16.md|[查看](<LegacyGodot/2026-09-13_v01/docs/15_unified_card_wave_rules_2026-07-16.md>)|
|docs/16_crystal_tower_card_design_2026-07-17.md|[查看](<LegacyGodot/2026-09-13_v01/docs/16_crystal_tower_card_design_2026-07-17.md>)|
|docs/17_target_card_catalog_2026-07-17.md|[查看](<LegacyGodot/2026-09-13_v01/docs/17_target_card_catalog_2026-07-17.md>)|
|docs/18_balance_simulation_report_2026-07-22.md|[查看](<LegacyGodot/2026-09-13_v01/docs/18_balance_simulation_report_2026-07-22.md>)|
|docs/19_refresh_probability_experiment_2026-07-22.md|[查看](<LegacyGodot/2026-09-13_v01/docs/19_refresh_probability_experiment_2026-07-22.md>)|
|docs/20_state_scored_refresh_experiment_2026-07-22.md|[查看](<LegacyGodot/2026-09-13_v01/docs/20_state_scored_refresh_experiment_2026-07-22.md>)|
|docs/21_sliding_window_board_progression_2026-07-22.md|[查看](<LegacyGodot/2026-09-13_v01/docs/21_sliding_window_board_progression_2026-07-22.md>)|
|docs/22_crystal_tower_long_term_progression_2026-07-23.md|[查看](<LegacyGodot/2026-09-13_v01/docs/22_crystal_tower_long_term_progression_2026-07-23.md>)|
|docs/23_combo_focus_simulation_2026-07-23.md|[查看](<LegacyGodot/2026-09-13_v01/docs/23_combo_focus_simulation_2026-07-23.md>)|
|docs/24_chapter_one_campaign.md|[查看](<LegacyGodot/2026-09-13_v01/docs/24_chapter_one_campaign.md>)|
|docs/26_combat_balance_master.md|[查看](<LegacyGodot/2026-09-13_v01/docs/26_combat_balance_master.md>)|
|docs/27_art_production_and_asset_pipeline_standard_2026-08-06.md|[查看](<LegacyGodot/2026-09-13_v01/docs/27_art_production_and_asset_pipeline_standard_2026-08-06.md>)|
|docs/27_chapter01_ui_art_requirements.md|[查看](<LegacyGodot/2026-09-13_v01/docs/27_chapter01_ui_art_requirements.md>)|
|docs/28_secondary_interfaces_2026-08-13.md|[查看](<LegacyGodot/2026-09-13_v01/docs/28_secondary_interfaces_2026-08-13.md>)|
|docs/29_chain_merge_and_chain_burst_v1.md|[查看](<LegacyGodot/2026-09-13_v01/docs/29_chain_merge_and_chain_burst_v1.md>)|
|docs/30_resonance_v05_test_notes.md|[查看](<LegacyGodot/2026-09-13_v01/docs/30_resonance_v05_test_notes.md>)|
|docs/31_ui_global_audit_2026-09-10.md|[查看](<LegacyGodot/2026-09-13_v01/docs/31_ui_global_audit_2026-09-10.md>)|
|docs/32_ui_unified_v02_integration.md|[查看](<LegacyGodot/2026-09-13_v01/docs/32_ui_unified_v02_integration.md>)|
|docs/README.md|[查看](<LegacyGodot/2026-09-13_v01/docs/README.md>)|
|docs/archive/PROJECT_DIRECTION_FULL_2026-07-04.md|[查看](<LegacyGodot/2026-09-13_v01/docs/archive/PROJECT_DIRECTION_FULL_2026-07-04.md>)|
|docs/assets/.gdignore|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/.gdignore>)|
|docs/assets/active_review_visual_queue_2026-08-20.csv|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/active_review_visual_queue_2026-08-20.csv>)|
|docs/assets/android_arm64_test_build.md|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/android_arm64_test_build.md>)|
|docs/assets/art_source_map.csv|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/art_source_map.csv>)|
|docs/assets/asset_inventory.csv|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/asset_inventory.csv>)|
|docs/assets/asset_move_map.csv|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/asset_move_map.csv>)|
|docs/assets/atlas_groups.csv|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/atlas_groups.csv>)|
|docs/assets/claude_resource_followup_execution_status_2026-08-20.md|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/claude_resource_followup_execution_status_2026-08-20.md>)|
|docs/assets/directory_structure_cross_reference_detailed_2026-08-21.md|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/directory_structure_cross_reference_detailed_2026-08-21.md>)|
|docs/assets/directory_structure_register_detailed_2026-08-21.csv|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/directory_structure_register_detailed_2026-08-21.csv>)|
|docs/assets/non_ui_atlas_source_scan_2026-08-20.json|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/non_ui_atlas_source_scan_2026-08-20.json>)|
|docs/assets/README.md|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/README.md>)|
|docs/assets/resource_asset_register_bilingual_2026-08-20.csv|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/resource_asset_register_bilingual_2026-08-20.csv>)|
|docs/assets/resource_catalog_validation_2026-08-20.json|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/resource_catalog_validation_2026-08-20.json>)|
|docs/assets/resource_catalog_workbook_source_2026-08-20.json|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/resource_catalog_workbook_source_2026-08-20.json>)|
|docs/assets/resource_directory_cross_reference_bilingual_2026-08-20.md|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/resource_directory_cross_reference_bilingual_2026-08-20.md>)|
|docs/assets/resource_reorganization_followup_plan_2026-08-20.md|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/resource_reorganization_followup_plan_2026-08-20.md>)|
|docs/assets/runtime_unreferenced_review_queue_2026-08-20.csv|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/runtime_unreferenced_review_queue_2026-08-20.csv>)|
|docs/assets/ui_runtime_asset_move_map_2026-08-20.csv|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/ui_runtime_asset_move_map_2026-08-20.csv>)|
|docs/assets/ui_runtime_asset_reorganization_report_2026-08-20.json|[查看](<LegacyGodot/2026-09-13_v01/docs/assets/ui_runtime_asset_reorganization_report_2026-08-20.json>)|
|AGENTS.md|[查看](<LegacyGodot/2026-09-13_v01/AGENTS.md>)|
|MIGRATION_GODOT.md|[查看](<LegacyGodot/2026-09-13_v01/MIGRATION_GODOT.md>)|
|PROJECT_DIRECTION.md|[查看](<LegacyGodot/2026-09-13_v01/PROJECT_DIRECTION.md>)|