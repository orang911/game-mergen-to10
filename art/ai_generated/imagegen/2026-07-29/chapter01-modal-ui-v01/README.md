# Chapter 01 Modal UI — v01

本目录包含 `25_chapter01_modal_ui_audit_2026-07-29` 的弹窗优化效果图。全部遵循当前游戏的轻度草地、浅色石材、圆润水晶城堡 UI 语言；图片仅用于效果确认，文字由程序实现。

| 文件 | 使用时机 |
| --- | --- |
| `20260729_chapter01_modal_01_first_merge_guidance_v01.png` | 首次三合成引导 |
| `20260729_chapter01_modal_02_crystal_damage_warning_v01.png` | 水晶首次受损提示 |
| `20260729_chapter01_modal_03_crystal_awaken_reward_v01.png` | 获得晶核与水晶唤醒 |
| `20260729_chapter01_modal_04_crystal_guard_message_v01.png` | 水晶自动攻击说明（非阻断） |
| `20260729_chapter01_modal_05_imprint_choice_selected_v01.png` | 印记二选一与已选状态 |
| `20260729_chapter01_modal_06_node_transition_v01.png` | 章节节点完成 / 前往下一节点 |
| `20260729_chapter01_modal_07_crystal_reward_v01.png` | 小 Boss 后晶核装备奖励 |
| `20260729_chapter01_modal_08_chapter_completion_v01.png` | 第一章完成决策 |
| `20260729_chapter01_modal_09_failure_decision_v01.png` | 水晶破碎后的失败决策 |
| `20260729_chapter01_modal_10_revive_feedback_v01.png` | 复活成功自动回战反馈 |
| `20260729_chapter01_modal_11_exit_settlement_v01.png` | 重新开始 / 返回大厅后的离局结算 |

流程约束：失败时先显示 `09`；选择复活后显示 `10` 并自动回战；只有选择重新开始或返回大厅后才显示 `11`。结算页的奖励区域优先级高于战绩数据。
