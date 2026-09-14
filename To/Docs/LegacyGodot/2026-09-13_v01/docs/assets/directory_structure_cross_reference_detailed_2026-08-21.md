# 逐子目录结构对照 / Detailed Directory Structure Cross-Reference

更新日期：`2026-08-21`  
生成方式：`node tools/build_detailed_directory_cross_reference.mjs`

这份文档改为树状阅读：每一个当前存在的资源子目录都显示在完整树内。逐文件级的哈希、引用和来源仍以 `resource_asset_register_bilingual_2026-08-20.csv` 为准；逐目录的生产/运行对应关系、修改规则和图集规则请在同名 CSV 中筛选。

## 使用规则

- 要改运行中的 UI：先在 `assets/runtime/ui/interfaces/**`、`components/**`、`shared/**` 找到成品，再跳转到本表“对应运行或生产目录”列的生产源修改。
- `assets/runtime/ui/` 下未进入上述三层的旧包不是当前新增资源入口；它们仍在磁盘上，仅供审核与溯源，不能直接删除。
- `art/production/**` 是可编辑源；`art/ai_generated/**`、`art/ui_slices/**`、`art_source/**` 是来源或历史区，不能直接作为运行资源。
- 图集目录中的 `atlas_regions/` 和 `atlases/` 必须通过 `tools/build_runtime_atlases.ps1` 重建，不能只手工改 TRES 或图集原图。

## 扫描范围

| 顶层根目录 | 子目录数 |
|---|---:|
| `assets/runtime/` | 164 |
| `shaders/` | 1 |
| `art/production/` | 121 |
| `art/ai_generated/` | 56 |
| `art/ui_slices/` | 8 |
| `art_source/` | 9 |

总计：`359` 个目录；当前 UI 结构目录 `103` 个，旧 UI 包目录 `35` 个。

## 当前 UI 完整结构（可直接修改入口）

图例：`🟢 当前运行`、`🟡 运行待审核`、`🟠 旧包（不再新增）`、`🔵 生产可编辑源`、`🟣 AI 原图`、`⚪ 历史来源`。  
节点信息：`在用` 是当前可达资源数；`目录资源` 包含该目录下所有子目录的总账资源数。

```text
assets/   虚拟父级 / virtual parent
└─ runtime/   虚拟父级 / virtual parent
   └─ ui/   虚拟父级 / virtual parent
      ├─ components/   🟢 当前运行 · 在用 72 · 目录资源 72
      │  ├─ board_g3
      .0lyphs/   🟢 当前运行 · 在用 37 · 目录资源 37
      │  │  ├─ atlas_regions/   🟢 当前运行 · 在用 36 · 目录资源 36
      │  │  └─ atlases/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ board_tiles/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  ├─ atlas_regions/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  └─ atlases/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ card_backs/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  └─ textures/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ card_icons/   🟢 当前运行 · 在用 17 · 目录资源 17
      │  │  ├─ atlas_regions/   🟢 当前运行 · 在用 16 · 目录资源 16
      │  │  └─ atlases/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ crystal_tower/   🟢 当前运行 · 在用 9 · 目录资源 9
      │  │  └─ textures/   🟢 当前运行 · 在用 9 · 目录资源 9
      │  └─ rating_stars/   🟢 当前运行 · 在用 2 · 目录资源 2
      │     └─ icons/   🟢 当前运行 · 在用 2 · 目录资源 2
      ├─ interfaces/   🟡 运行待审 · 在用 138 · 目录资源 138
      │  ├─ battle/   🟢 当前运行 · 在用 24 · 目录资源 24
      │  │  ├─ board/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  │  └─ standalone/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ combat_feedback/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  │  └─ icons/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  ├─ energy_hud/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  │  └─ icons/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  ├─ standalone/   🟢 当前运行 · 在用 4 · 目录资源 4
      │  │  ├─ top_hud/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  │  ├─ backplates/   🟢 当前运行 · 在用 3 · 目录资源 3
      │  │  │  ├─ buttons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  │  └─ icons/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  │  └─ tutorial/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │     └─ icons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ battle_pause/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  ├─ benefits/   🟡 运行待审 · 在用 8 · 目录资源 8
      │  │  ├─ backplates/   🟡 运行待审 · 在用 5 · 目录资源 5
      │  │  └─ icons/   🟡 运行待审 · 在用 3 · 目录资源 3
      │  ├─ chapter_node_complete/   🟢 当前运行 · 在用 4 · 目录资源 4
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ buttons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  └─ decorations/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  ├─ crystal_card_choice/   🟢 当前运行 · 在用 4 · 目录资源 4
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ buttons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  └─ decorations/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  ├─ daily_program/   🟡 运行待审 · 在用 26 · 目录资源 26
      │  │  ├─ backplates/   🟡 运行待审 · 在用 16 · 目录资源 16
      │  │  └─ icons/   🟡 运行待审 · 在用 10 · 目录资源 10
      │  ├─ exit_confirm/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  ├─ first_purchase/   🟡 运行待审 · 在用 3 · 目录资源 3
      │  │  ├─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  ├─ decorations/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ rewards/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  ├─ imprint_choice/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ buttons/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  │  └─ decorations/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  ├─ legacy_runtime_controls/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  └─ buttons/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  ├─ loading/   🟢 当前运行 · 在用 3 · 目录资源 3
      │  │  ├─ progress/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  │  └─ standalone/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ main_hub/   🟢 当前运行 · 在用 13 · 目录资源 13
      │  │  ├─ backplates/   🟢 当前运行 · 在用 11 · 目录资源 11
      │  │  └─ standalone/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  ├─ max_level_success/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ buttons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ decorations/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  │  └─ icons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ piggy_bank/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  ├─ purchase_confirmation/   🟢 当前运行 · 在用 0 · 目录资源 0
      │  │  ├─ backplates/   🟢 当前运行 · 在用 0 · 目录资源 0
      │  │  └─ icons/   🟢 当前运行 · 在用 0 · 目录资源 0
      │  ├─ settings/   🟡 运行待审 · 在用 3 · 目录资源 3
      │  │  ├─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ controls/   🟡 运行待审 · 在用 2 · 目录资源 2
      │  ├─ settlement/   🟢 当前运行 · 在用 26 · 目录资源 26
      │  │  ├─ backplates/   🟢 当前运行 · 在用 9 · 目录资源 9
      │  │  ├─ decorations/   🟢 当前运行 · 在用 3 · 目录资源 3
      │  │  ├─ icons/   🟢 当前运行 · 在用 12 · 目录资源 12
      │  │  └─ tabs/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  └─ shop/   🟡 运行待审 · 在用 5 · 目录资源 5
      │     ├─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │     └─ icons/   🟡 运行待审 · 在用 4 · 目录资源 4
      └─ shared/   🟡 运行待审 · 在用 25 · 目录资源 25
         ├─ app/   🟢 当前运行 · 在用 1 · 目录资源 1
         │  └─ icons/   🟢 当前运行 · 在用 1 · 目录资源 1
         ├─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
         │  └─ panels/   🟡 运行待审 · 在用 1 · 目录资源 1
         ├─ buttons/   🟡 运行待审 · 在用 5 · 目录资源 5
         │  └─ states/   🟡 运行待审 · 在用 5 · 目录资源 5
         ├─ confirmation/   🟡 运行待审 · 在用 1 · 目录资源 1
         │  └─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
         ├─ decorations/   🟡 运行待审 · 在用 1 · 目录资源 1
         │  └─ titles/   🟡 运行待审 · 在用 1 · 目录资源 1
         └─ meta_icons/   🟢 当前运行 · 在用 16 · 目录资源 16
            ├─ atlas_regions/   🟢 当前运行 · 在用 15 · 目录资源 15
            └─ atlases/   🟢 当前运行 · 在用 1 · 目录资源 1
```

## 全项目资源目录树（全部 359 个目录）

<details>
<summary>展开完整目录树：运行资源、生产源、AI 原图与历史来源</summary>

```text
art/   虚拟父级 / virtual parent
├─ ai_generated/   ⚪ 历史来源 · 在用 0 · 目录资源 161
│  ├─ flyne/   🟣 AI原图 · 在用 0 · 目录资源 12
│  │  ├─ 2026-07-29/   🟣 AI原图 · 在用 0 · 目录资源 3
│  │  │  └─ 133603_crystal-perspective-restyle/   🟣 AI原图 · 在用 0 · 目录资源 3
│  │  │     └─ references/   🟣 AI原图 · 在用 0 · 目录资源 2
│  │  └─ 2026-08-12/   🟣 AI原图 · 在用 0 · 目录资源 9
│  │     ├─ 130100_imprint-choice-modal/   🟣 AI原图 · 在用 0 · 目录资源 3
│  │     │  └─ references/   🟣 AI原图 · 在用 0 · 目录资源 2
│  │     ├─ 130200_minimal-battle-hub/   🟣 AI原图 · 在用 0 · 目录资源 3
│  │     │  └─ references/   🟣 AI原图 · 在用 0 · 目录资源 2
│  │     └─ 130300_combat-hud-and-imprint/   🟣 AI原图 · 在用 0 · 目录资源 3
│  │        └─ references/   🟣 AI原图 · 在用 0 · 目录资源 2
│  ├─ imagegen/   🟣 AI原图 · 在用 0 · 目录资源 45
│  │  ├─ 2026-07-29/   🟣 AI原图 · 在用 0 · 目录资源 28
│  │  │  ├─ 150000_crystal-tower-perspective/   🟣 AI原图 · 在用 0 · 目录资源 13
│  │  │  │  └─ cutouts/   🟣 AI原图 · 在用 0 · 目录资源 10
│  │  │  ├─ battle-ui-hd-redraw-v01/   🟣 AI原图 · 在用 0 · 目录资源 2
│  │  │  ├─ chapter01-modal-ui-v01/   🟣 AI原图 · 在用 0 · 目录资源 11
│  │  │  ├─ core-battle-ui-chroma-v01/   🟣 AI原图 · 在用 0 · 目录资源 1
│  │  │  └─ core-battle-ui-hd-redraw-v01/   🟣 AI原图 · 在用 0 · 目录资源 1
│  │  ├─ 2026-08-08/   🟣 AI原图 · 在用 0 · 目录资源 9
│  │  │  └─ 235311_lobby_hd_reset/   🟣 AI原图 · 在用 0 · 目录资源 9
│  │  │     └─ references/   🟣 AI原图 · 在用 0 · 目录资源 1
│  │  ├─ 2026-08-09/   🟣 AI原图 · 在用 0 · 目录资源 3
│  │  │  └─ 085423_crystal_stage_background/   🟣 AI原图 · 在用 0 · 目录资源 3
│  │  │     └─ references/   🟣 AI原图 · 在用 0 · 目录资源 1
│  │  └─ 2026-08-13/   🟣 AI原图 · 在用 0 · 目录资源 5
│  │     └─ 131530_chapter01_ui_batch2_concepts/   🟣 AI原图 · 在用 0 · 目录资源 5
│  │        └─ references/   🟣 AI原图 · 在用 0 · 目录资源 2
│  ├─ production_prompts/   🟣 AI原图 · 在用 0 · 目录资源 0
│  ├─ slices/   🟣 AI原图 · 在用 0 · 目录资源 55
│  │  └─ 2026-07-29/   🟣 AI原图 · 在用 0 · 目录资源 55
│  │     ├─ core-battle-ui-chroma-textless-v01/   🟣 AI原图 · 在用 0 · 目录资源 11
│  │     │  ├─ bottom/   🟣 AI原图 · 在用 0 · 目录资源 6
│  │     │  └─ top/   🟣 AI原图 · 在用 0 · 目录资源 4
│  │     ├─ core-battle-ui-chroma-textless-v02/   🟣 AI原图 · 在用 0 · 目录资源 14
│  │     │  ├─ bottom/   🟣 AI原图 · 在用 0 · 目录资源 7
│  │     │  └─ top/   🟣 AI原图 · 在用 0 · 目录资源 6
│  │     ├─ core-battle-ui-chroma-textless-v03/   🟣 AI原图 · 在用 0 · 目录资源 12
│  │     │  ├─ bottom/   🟣 AI原图 · 在用 0 · 目录资源 6
│  │     │  └─ top/   🟣 AI原图 · 在用 0 · 目录资源 6
│  │     └─ core-battle-ui-hd-v01/   🟣 AI原图 · 在用 0 · 目录资源 18
│  │        ├─ bottom/   🟣 AI原图 · 在用 0 · 目录资源 4
│  │        ├─ core/   🟣 AI原图 · 在用 0 · 目录资源 2
│  │        ├─ runtime_bases/   🟣 AI原图 · 在用 0 · 目录资源 8
│  │        └─ top/   🟣 AI原图 · 在用 0 · 目录资源 4
│  └─ ui/   🟣 AI原图 · 在用 0 · 目录资源 49
│     ├─ 2026-07-30/   🟣 AI原图 · 在用 0 · 目录资源 43
│     │  ├─ battle-board-base-hd-v01/   🟣 AI原图 · 在用 0 · 目录资源 6
│     │  ├─ battle-bottom-hud-hd-v01/   🟣 AI原图 · 在用 0 · 目录资源 16
│     │  ├─ battle-bottom-hud-hd-v02/   🟣 AI原图 · 在用 0 · 目录资源 12
│     │  ├─ battle-top-hud-hd-v01/   🟣 AI原图 · 在用 0 · 目录资源 7
│     │  └─ item-choice-modal-v01/   🟣 AI原图 · 在用 0 · 目录资源 2
│     └─ 2026-08-05/   🟣 AI原图 · 在用 0 · 目录资源 6
│        └─ item-choice-modal-hd-v01/   🟣 AI原图 · 在用 0 · 目录资源 6
│           └─ 20260805_item_choice_modal_hires_v01/   🟣 AI原图 · 在用 0 · 目录资源 3
├─ production/   ⚪ 历史来源 · 在用 0 · 目录资源 625
│  ├─ characters/   🔵 生产源 · 在用 0 · 目录资源 78
│  │  └─ runtime_atlas_sources/   🔵 生产源 · 在用 0 · 目录资源 78
│  │     └─ 2026-08-20/   🔵 生产源 · 在用 0 · 目录资源 78
│  │        ├─ die/   🔵 生产源 · 在用 0 · 目录资源 19
│  │        ├─ slime_stage_01/   🔵 生产源 · 在用 0 · 目录资源 26
│  │        │  ├─ hit/   🔵 生产源 · 在用 0 · 目录资源 8
│  │        │  └─ walk/   🔵 生产源 · 在用 0 · 目录资源 18
│  │        └─ xingzou_boos/   🔵 生产源 · 在用 0 · 目录资源 33
│  ├─ fx/   🔵 生产源 · 在用 0 · 目录资源 36
│  │  ├─ crystal_tower/   🔵 生产源 · 在用 0 · 目录资源 0
│  │  │  └─ raw_imagegen/   🔵 生产源 · 在用 0 · 目录资源 0
│  │  └─ runtime_atlas_sources/   🔵 生产源 · 在用 0 · 目录资源 36
│  │     └─ 2026-08-20/   🔵 生产源 · 在用 0 · 目录资源 36
│  │        ├─ lightning_beam/   🔵 生产源 · 在用 0 · 目录资源 3
│  │        ├─ merge/   🔵 生产源 · 在用 0 · 目录资源 13
│  │        └─ portal/   🔵 生产源 · 在用 0 · 目录资源 20
│  ├─ lobby/   🔵 生产源 · 在用 0 · 目录资源 74
│  │  ├─ 2026-08-08_lobby_hd_reset_and_cutout_v01/   🔵 生产源 · 在用 0 · 目录资源 51
│  │  │  ├─ chroma/   🔵 生产源 · 在用 0 · 目录资源 6
│  │  │  ├─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 29
│  │  │  │  ├─ frames/   🔵 生产源 · 在用 0 · 目录资源 10
│  │  │  │  └─ icons/   🔵 生产源 · 在用 0 · 目录资源 15
│  │  │  ├─ previews/   🔵 生产源 · 在用 0 · 目录资源 2
│  │  │  ├─ qa/   🔵 生产源 · 在用 0 · 目录资源 13
│  │  │  │  └─ rejected/   🔵 生产源 · 在用 0 · 目录资源 3
│  │  │  └─ source/   🔵 生产源 · 在用 0 · 目录资源 1
│  │  ├─ 2026-08-09_crystal_stage_background_v01/   🔵 生产源 · 在用 0 · 目录资源 19
│  │  │  ├─ chroma/   🔵 生产源 · 在用 0 · 目录资源 1
│  │  │  ├─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 2
│  │  │  ├─ previews/   🔵 生产源 · 在用 0 · 目录资源 1
│  │  │  ├─ qa/   🔵 生产源 · 在用 0 · 目录资源 14
│  │  │  │  └─ rejected/   🔵 生产源 · 在用 0 · 目录资源 2
│  │  │  └─ source/   🔵 生产源 · 在用 0 · 目录资源 1
│  │  └─ 2026-08-16_main_hub_runtime_alignment_v01/   🔵 生产源 · 在用 0 · 目录资源 4
│  └─ ui/   🔵 生产源 · 在用 0 · 目录资源 437
│     ├─ benefits_popup/   🔵 生产源 · 在用 0 · 目录资源 17
│     │  └─ 2026-08-16_program_composition_cutouts_v01/   🔵 生产源 · 在用 0 · 目录资源 17
│     │     ├─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 8
│     │     │  ├─ backplates/   🔵 生产源 · 在用 0 · 目录资源 5
│     │     │  └─ icons/   🔵 生产源 · 在用 0 · 目录资源 3
│     │     ├─ previews/   🔵 生产源 · 在用 0 · 目录资源 1
│     │     ├─ qa/   🔵 生产源 · 在用 0 · 目录资源 4
│     │     └─ source/   🔵 生产源 · 在用 0 · 目录资源 4
│     ├─ chapter01/   🔵 生产源 · 在用 0 · 目录资源 191
│     │  ├─ 2026-08-13_centered_interfaces_complete_v02/   🔵 生产源 · 在用 0 · 目录资源 118
│     │  │  ├─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 104
│     │  │  │  ├─ elements/   🔵 生产源 · 在用 0 · 目录资源 94
│     │  │  │  │  ├─ common/   🔵 生产源 · 在用 0 · 目录资源 20
│     │  │  │  │  ├─ icons/   🔵 生产源 · 在用 0 · 目录资源 33
│     │  │  │  │  │  └─ settings/   🔵 生产源 · 在用 0 · 目录资源 9
│     │  │  │  │  └─ pages/   🔵 生产源 · 在用 0 · 目录资源 41
│     │  │  │  │     ├─ commerce/   🔵 生产源 · 在用 0 · 目录资源 12
│     │  │  │  │     ├─ daily/   🔵 生产源 · 在用 0 · 目录资源 9
│     │  │  │  │     ├─ pause/   🔵 生产源 · 在用 0 · 目录资源 2
│     │  │  │  │     └─ shop/   🔵 生产源 · 在用 0 · 目录资源 18
│     │  │  │  └─ frames/   🔵 生产源 · 在用 0 · 目录资源 10
│     │  │  ├─ previews/   🔵 生产源 · 在用 0 · 目录资源 10
│     │  │  │  └─ implementation_previews/   🔵 生产源 · 在用 0 · 目录资源 10
│     │  │  └─ qa/   🔵 生产源 · 在用 0 · 目录资源 4
│     │  ├─ 2026-08-13_centered_interfaces_complete_v03/   🔵 生产源 · 在用 0 · 目录资源 31
│     │  │  ├─ masters_alpha_2160x3840/   🔵 生产源 · 在用 0 · 目录资源 10
│     │  │  ├─ masters_chroma_2160x3840/   🔵 生产源 · 在用 0 · 目录资源 10
│     │  │  └─ qa/   🔵 生产源 · 在用 0 · 目录资源 11
│     │  │     └─ runtime_941x1672/   🔵 生产源 · 在用 0 · 目录资源 10
│     │  ├─ 2026-08-13_centered_interfaces_runtime_v04/   🔵 生产源 · 在用 0 · 目录资源 20
│     │  │  └─ qa/   🔵 生产源 · 在用 0 · 目录资源 20
│     │  │     ├─ edge/   🔵 生产源 · 在用 0 · 目录资源 10
│     │  │     └─ runtime_941x1672/   🔵 生产源 · 在用 0 · 目录资源 10
│     │  ├─ 2026-08-13_centered_interfaces_v01/   🔵 生产源 · 在用 0 · 目录资源 11
│     │  │  ├─ qa/   🔵 生产源 · 在用 0 · 目录资源 1
│     │  │  ├─ reference_composites/   🔵 生产源 · 在用 0 · 目录资源 10
│     │  │  └─ source/   🔵 生产源 · 在用 0 · 目录资源 0
│     │  └─ 2026-08-14_secondary_in_game_acceptance/   🔵 生产源 · 在用 0 · 目录资源 11
│     │     ├─ battle/   🔵 生产源 · 在用 0 · 目录资源 2
│     │     └─ hub/   🔵 生产源 · 在用 0 · 目录资源 9
│     ├─ daily_program_composition/   🔵 生产源 · 在用 0 · 目录资源 68
│     │  ├─ 2026-08-16_cutouts_v01/   🔵 生产源 · 在用 0 · 目录资源 37
│     │  │  ├─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 23
│     │  │  │  ├─ backplates/   🔵 生产源 · 在用 0 · 目录资源 14
│     │  │  │  └─ icons/   🔵 生产源 · 在用 0 · 目录资源 9
│     │  │  ├─ previews/   🔵 生产源 · 在用 0 · 目录资源 4
│     │  │  ├─ qa/   🔵 生产源 · 在用 0 · 目录资源 4
│     │  │  └─ source/   🔵 生产源 · 在用 0 · 目录资源 6
│     │  └─ 2026-08-16_cutouts_v02/   🔵 生产源 · 在用 0 · 目录资源 31
│     │     ├─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 26
│     │     │  ├─ backplates/   🔵 生产源 · 在用 0 · 目录资源 16
│     │     │  └─ icons/   🔵 生产源 · 在用 0 · 目录资源 10
│     │     ├─ previews/   🔵 生产源 · 在用 0 · 目录资源 4
│     │     └─ qa/   🔵 生产源 · 在用 0 · 目录资源 1
│     ├─ daily_signin/   🔵 生产源 · 在用 0 · 目录资源 46
│     │  └─ 2026-08-14_cutouts_v01/   🔵 生产源 · 在用 0 · 目录资源 46
│     │     ├─ chroma/   🔵 生产源 · 在用 0 · 目录资源 3
│     │     ├─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 14
│     │     ├─ daily_signin_cutouts_v01/   🔵 生产源 · 在用 0 · 目录资源 19
│     │     │  └─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 14
│     │     ├─ previews/   🔵 生产源 · 在用 0 · 目录资源 1
│     │     ├─ qa/   🔵 生产源 · 在用 0 · 目录资源 5
│     │     └─ source/   🔵 生产源 · 在用 0 · 目录资源 4
│     ├─ daily_tasks/   🔵 生产源 · 在用 0 · 目录资源 25
│     │  └─ 2026-08-14_hd_reset_v01/   🔵 生产源 · 在用 0 · 目录资源 25
│     │     ├─ chroma/   🔵 生产源 · 在用 0 · 目录资源 3
│     │     ├─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 11
│     │     ├─ previews/   🔵 生产源 · 在用 0 · 目录资源 2
│     │     ├─ qa/   🔵 生产源 · 在用 0 · 目录资源 5
│     │     └─ source/   🔵 生产源 · 在用 0 · 目录资源 4
│     ├─ purchase_confirmation/   🔵 生产源 · 在用 0 · 目录资源 18
│     │  └─ 2026-08-20_bundle_cutouts_v01/   🔵 生产源 · 在用 0 · 目录资源 18
│     │     ├─ chroma/   🔵 生产源 · 在用 0 · 目录资源 2
│     │     ├─ cutouts/   🔵 生产源 · 在用 0 · 目录资源 8
│     │     │  ├─ backplates/   🔵 生产源 · 在用 0 · 目录资源 6
│     │     │  └─ icons/   🔵 生产源 · 在用 0 · 目录资源 2
│     │     ├─ previews/   🔵 生产源 · 在用 0 · 目录资源 1
│     │     ├─ qa/   🔵 生产源 · 在用 0 · 目录资源 4
│     │     └─ source/   🔵 生产源 · 在用 0 · 目录资源 3
│     └─ runtime_atlas_sources/   🔵 生产源 · 在用 0 · 目录资源 72
│        └─ 2026-08-20/   🔵 生产源 · 在用 0 · 目录资源 72
│           ├─ board_glyphs/   🔵 生产源 · 在用 0 · 目录资源 36
│           ├─ board_tiles/   🔵 生产源 · 在用 0 · 目录资源 5
│           ├─ card_icons/   🔵 生产源 · 在用 0 · 目录资源 16
│           └─ meta_icons/   🔵 生产源 · 在用 0 · 目录资源 15
└─ ui_slices/   ⚪ 历史来源 · 在用 0 · 目录资源 51
   ├─ 2026-07-30/   ⚪ 历史来源 · 在用 0 · 目录资源 21
   │  └─ item-choice-modal-v01/   ⚪ 历史来源 · 在用 0 · 目录资源 21
   │     ├─ _raw_crops/   ⚪ 历史来源 · 在用 0 · 目录资源 7
   │     └─ production/   ⚪ 历史来源 · 在用 0 · 目录资源 13
   └─ 2026-08-05/   ⚪ 历史来源 · 在用 0 · 目录资源 30
      ├─ item-choice-modal-backplates-v01/   ⚪ 历史来源 · 在用 0 · 目录资源 18
      └─ loading-bar-v01/   ⚪ 历史来源 · 在用 0 · 目录资源 12
art_source/   ⚪ 历史来源 · 在用 0 · 目录资源 73
├─ fx_references/   ⚪ 历史来源 · 在用 0 · 目录资源 73
│  ├─ 弹道效果全景循环_12帧_v01/   ⚪ 历史来源 · 在用 0 · 目录资源 15
│  │  └─ frames/   ⚪ 历史来源 · 在用 0 · 目录资源 12
│  ├─ 爆炸影响_参考还原_v01/   ⚪ 历史来源 · 在用 0 · 目录资源 29
│  │  └─ frames_rgba/   ⚪ 历史来源 · 在用 0 · 目录资源 25
│  └─ 爆炸影响_参考还原_v02_严格保真/   ⚪ 历史来源 · 在用 0 · 目录资源 29
│     └─ frames_rgba/   ⚪ 历史来源 · 在用 0 · 目录资源 25
└─ source_sheets/   ⚪ 历史来源 · 在用 0 · 目录资源 0
assets/   虚拟父级 / virtual parent
└─ runtime/   ⚪ 历史来源 · 在用 276 · 目录资源 463
   ├─ audio/   🟢 运行资源 · 在用 2 · 目录资源 2
   ├─ characters/   🟢 运行资源 · 在用 14 · 目录资源 14
   │  ├─ monsters/   🟢 运行资源 · 在用 14 · 目录资源 14
   │  │  ├─ atlases/   🟢 运行资源 · 在用 5 · 目录资源 5
   │  │  ├─ die/   🟢 运行资源 · 在用 0 · 目录资源 0
   │  │  └─ slime_stage_01/   🟢 运行资源 · 在用 0 · 目录资源 0
   │  │     ├─ hit/   🟢 运行资源 · 在用 0 · 目录资源 0
   │  │     └─ walk/   🟢 运行资源 · 在用 0 · 目录资源 0
   │  └─ xingzou boos/   🟢 运行资源 · 在用 0 · 目录资源 0
   ├─ fx/   🟢 运行资源 · 在用 25 · 目录资源 25
   │  ├─ crystal_tower/   🟢 运行资源 · 在用 3 · 目录资源 3
   │  ├─ elements/   🟢 运行资源 · 在用 20 · 目录资源 20
   │  │  ├─ critical/   🟢 运行资源 · 在用 4 · 目录资源 4
   │  │  ├─ fire/   🟢 运行资源 · 在用 4 · 目录资源 4
   │  │  ├─ ice/   🟢 运行资源 · 在用 4 · 目录资源 4
   │  │  ├─ lightning/   🟢 运行资源 · 在用 3 · 目录资源 3
   │  │  │  ├─ atlases/   🟢 运行资源 · 在用 1 · 目录资源 1
   │  │  │  └─ beam/   🟢 运行资源 · 在用 0 · 目录资源 0
   │  │  ├─ poison/   🟢 运行资源 · 在用 4 · 目录资源 4
   │  │  └─ shared/   🟢 运行资源 · 在用 1 · 目录资源 1
   │  ├─ merge/   🟢 运行资源 · 在用 1 · 目录资源 1
   │  │  └─ atlases/   🟢 运行资源 · 在用 1 · 目录资源 1
   │  └─ portal/   🟢 运行资源 · 在用 1 · 目录资源 1
   │     └─ atlases/   🟢 运行资源 · 在用 1 · 目录资源 1
   └─ ui/   🟢 运行资源 · 在用 235 · 目录资源 422
      ├─ battle/   🟠 旧包 · 在用 0 · 目录资源 12
      │  └─ prompts/   🟠 旧包 · 在用 0 · 目录资源 12
      │     └─ imprint_choice/   🟠 旧包 · 在用 0 · 目录资源 12
      │        ├─ button/   🟠 旧包 · 在用 0 · 目录资源 3
      │        ├─ icon/   🟠 旧包 · 在用 0 · 目录资源 0
      │        ├─ overlay/   🟠 旧包 · 在用 0 · 目录资源 5
      │        ├─ panel/   🟠 旧包 · 在用 0 · 目录资源 3
      │        └─ slot/   🟠 旧包 · 在用 0 · 目录资源 1
      ├─ cards/   🟠 旧包 · 在用 0 · 目录资源 4
      │  ├─ backs/   🟠 旧包 · 在用 0 · 目录资源 3
      │  ├─ frames/   🟠 旧包 · 在用 0 · 目录资源 1
      │  └─ icons/   🟠 旧包 · 在用 0 · 目录资源 0
      ├─ components/   🟢 当前运行 · 在用 72 · 目录资源 72
      │  ├─ board_glyphs/   🟢 当前运行 · 在用 37 · 目录资源 37
      │  │  ├─ atlas_regions/   🟢 当前运行 · 在用 36 · 目录资源 36
      │  │  └─ atlases/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ board_tiles/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  ├─ atlas_regions/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  └─ atlases/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ card_backs/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  └─ textures/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ card_icons/   🟢 当前运行 · 在用 17 · 目录资源 17
      │  │  ├─ atlas_regions/   🟢 当前运行 · 在用 16 · 目录资源 16
      │  │  └─ atlases/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ crystal_tower/   🟢 当前运行 · 在用 9 · 目录资源 9
      │  │  └─ textures/   🟢 当前运行 · 在用 9 · 目录资源 9
      │  └─ rating_stars/   🟢 当前运行 · 在用 2 · 目录资源 2
      │     └─ icons/   🟢 当前运行 · 在用 2 · 目录资源 2
      ├─ daily_program_composition_v01/   🟠 旧包 · 在用 0 · 目录资源 25
      │  ├─ backplates/   🟠 旧包 · 在用 0 · 目录资源 16
      │  └─ icons/   🟠 旧包 · 在用 0 · 目录资源 9
      ├─ daily_signin_hd_v01/   🟠 旧包 · 在用 0 · 目录资源 15
      ├─ daily_tasks_hd_v01/   🟠 旧包 · 在用 0 · 目录资源 19
      ├─ interfaces/   🟡 运行待审 · 在用 138 · 目录资源 138
      │  ├─ battle/   🟢 当前运行 · 在用 24 · 目录资源 24
      │  │  ├─ board/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  │  └─ standalone/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ combat_feedback/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  │  └─ icons/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  ├─ energy_hud/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  │  └─ icons/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  ├─ standalone/   🟢 当前运行 · 在用 4 · 目录资源 4
      │  │  ├─ top_hud/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  │  ├─ backplates/   🟢 当前运行 · 在用 3 · 目录资源 3
      │  │  │  ├─ buttons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  │  └─ icons/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  │  └─ tutorial/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │     └─ icons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ battle_pause/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  ├─ benefits/   🟡 运行待审 · 在用 8 · 目录资源 8
      │  │  ├─ backplates/   🟡 运行待审 · 在用 5 · 目录资源 5
      │  │  └─ icons/   🟡 运行待审 · 在用 3 · 目录资源 3
      │  ├─ chapter_node_complete/   🟢 当前运行 · 在用 4 · 目录资源 4
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ buttons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  └─ decorations/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  ├─ crystal_card_choice/   🟢 当前运行 · 在用 4 · 目录资源 4
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ buttons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  └─ decorations/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  ├─ daily_program/   🟡 运行待审 · 在用 26 · 目录资源 26
      │  │  ├─ backplates/   🟡 运行待审 · 在用 16 · 目录资源 16
      │  │  └─ icons/   🟡 运行待审 · 在用 10 · 目录资源 10
      │  ├─ exit_confirm/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  ├─ first_purchase/   🟡 运行待审 · 在用 3 · 目录资源 3
      │  │  ├─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  ├─ decorations/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ rewards/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  ├─ imprint_choice/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ buttons/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  │  └─ decorations/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  ├─ legacy_runtime_controls/   🟢 当前运行 · 在用 6 · 目录资源 6
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  └─ buttons/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  ├─ loading/   🟢 当前运行 · 在用 3 · 目录资源 3
      │  │  ├─ progress/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  │  └─ standalone/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ main_hub/   🟢 当前运行 · 在用 13 · 目录资源 13
      │  │  ├─ backplates/   🟢 当前运行 · 在用 11 · 目录资源 11
      │  │  └─ standalone/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  ├─ max_level_success/   🟢 当前运行 · 在用 5 · 目录资源 5
      │  │  ├─ backplates/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ buttons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  │  ├─ decorations/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  │  └─ icons/   🟢 当前运行 · 在用 1 · 目录资源 1
      │  ├─ piggy_bank/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  ├─ purchase_confirmation/   🟢 当前运行 · 在用 0 · 目录资源 0
      │  │  ├─ backplates/   🟢 当前运行 · 在用 0 · 目录资源 0
      │  │  └─ icons/   🟢 当前运行 · 在用 0 · 目录资源 0
      │  ├─ settings/   🟡 运行待审 · 在用 3 · 目录资源 3
      │  │  ├─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │  │  └─ controls/   🟡 运行待审 · 在用 2 · 目录资源 2
      │  ├─ settlement/   🟢 当前运行 · 在用 26 · 目录资源 26
      │  │  ├─ backplates/   🟢 当前运行 · 在用 9 · 目录资源 9
      │  │  ├─ decorations/   🟢 当前运行 · 在用 3 · 目录资源 3
      │  │  ├─ icons/   🟢 当前运行 · 在用 12 · 目录资源 12
      │  │  └─ tabs/   🟢 当前运行 · 在用 2 · 目录资源 2
      │  └─ shop/   🟡 运行待审 · 在用 5 · 目录资源 5
      │     ├─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
      │     └─ icons/   🟡 运行待审 · 在用 4 · 目录资源 4
      ├─ screens/   🟠 旧包 · 在用 0 · 目录资源 14
      │  ├─ main_hub_v2/   🟠 旧包 · 在用 0 · 目录资源 10
      │  │  ├─ frames/   🟠 旧包 · 在用 0 · 目录资源 10
      │  │  └─ icons/   🟠 旧包 · 在用 0 · 目录资源 0
      │  ├─ skill_choice/   🟠 旧包 · 在用 0 · 目录资源 3
      │  └─ wave_choice/   🟠 旧包 · 在用 0 · 目录资源 1
      ├─ secondary/   🟠 旧包 · 在用 0 · 目录资源 14
      ├─ secondary_centered_v04/   🟠 旧包 · 在用 0 · 目录资源 84
      │  ├─ elements/   🟠 旧包 · 在用 0 · 目录资源 79
      │  │  ├─ common/   🟠 旧包 · 在用 0 · 目录资源 11
      │  │  ├─ icons/   🟠 旧包 · 在用 0 · 目录资源 32
      │  │  │  └─ settings/   🟠 旧包 · 在用 0 · 目录资源 9
      │  │  └─ pages/   🟠 旧包 · 在用 0 · 目录资源 36
      │  │     ├─ commerce/   🟠 旧包 · 在用 0 · 目录资源 10
      │  │     ├─ daily/   🟠 旧包 · 在用 0 · 目录资源 9
      │  │     ├─ pause/   🟠 旧包 · 在用 0 · 目录资源 2
      │  │     └─ shop/   🟠 旧包 · 在用 0 · 目录资源 15
      │  └─ frames/   🟠 旧包 · 在用 0 · 目录资源 5
      └─ shared/   🟡 运行待审 · 在用 25 · 目录资源 25
         ├─ app/   🟢 当前运行 · 在用 1 · 目录资源 1
         │  └─ icons/   🟢 当前运行 · 在用 1 · 目录资源 1
         ├─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
         │  └─ panels/   🟡 运行待审 · 在用 1 · 目录资源 1
         ├─ buttons/   🟡 运行待审 · 在用 5 · 目录资源 5
         │  └─ states/   🟡 运行待审 · 在用 5 · 目录资源 5
         ├─ confirmation/   🟡 运行待审 · 在用 1 · 目录资源 1
         │  └─ backplates/   🟡 运行待审 · 在用 1 · 目录资源 1
         ├─ decorations/   🟡 运行待审 · 在用 1 · 目录资源 1
         │  └─ titles/   🟡 运行待审 · 在用 1 · 目录资源 1
         └─ meta_icons/   🟢 当前运行 · 在用 16 · 目录资源 16
            ├─ atlas_regions/   🟢 当前运行 · 在用 15 · 目录资源 15
            └─ atlases/   🟢 当前运行 · 在用 1 · 目录资源 1
shaders/   🟢 运行资源 · 在用 4 · 目录资源 6
```

</details>

## 逐目录对照与修改入口

- [`directory_structure_register_detailed_2026-08-21.csv`](directory_structure_register_detailed_2026-08-21.csv) 保留全部 `359` 个目录的一行式对照，可按“当前目录、父目录、状态、对应目录、直接修改、图集规则”筛选。
- 运行 UI 的修改入口遵循：`assets/runtime/ui/interfaces/**`、`components/**`、`shared/**` 是成品定位区；生产源目录才是美术修改区。
- `assets/runtime/ui/` 中未进入上述三层的目录均是 `🟠 旧包`，只用于审核、来源追溯和历史回退判断。

## 字段说明

- **直属文件**：仅当前目录下一层文件，不含子目录；不计 `.import`、`.uid`。
- **目录内资源**：该目录及其全部子目录在资源总账中的有效资源数量。
- **对应运行或生产目录**：当前运行目录优先展示生产修改入口；生产目录优先展示当前运行去向；旧 UI 包展示其当前替代入口。模块级候选不等于逐文件替代关系。
- **直接修改**与**图集规则**完整字段请使用同名 CSV 过滤查看。

## 不允许的操作

1. 不要把新资源放回 `battle/`、`cards/`、`screens/`、`secondary_centered_v04/` 等旧 UI 包。
2. 不要因“未发现引用”直接删除目录或文件；先通过 `runtime_unreferenced_review_queue_2026-08-20.csv` 审核。
3. 不要把生产图、AI 原图、QA 图放入 `assets/runtime/**`。
4. 不要手动破坏图集与 AtlasTexture TRES 的对应关系。
