# Merge To 10 Godot Migration

This folder is now a Godot 4.x project.

## Entry

- Main scene: `res://scenes/main.tscn`
- Main script: `res://scripts/main_game.gd`
- Block script: `res://scripts/block.gd`

## Ported Gameplay

- 5x5 board
- Tap adjacent same-level groups to select
- Tap a selected block again to merge the whole group into that block
- Score formula from the Cocos project: `(merge_count - 1) * level * 2`
- Gravity fall and random refill
- Higher random refill range after the current max level passes 4
- Level 10 success popup and block removal
- No-move game-over popup
- Continue/revive by clearing the lowest-level blocks
- Restart, return to main menu, mute, click sound, merge sound
- Best score persistence via `user://merge_to_10.cfg`

## Source Asset Use

The migrated project reads the original Cocos images and sounds directly from:

- `assets/textrues/`
- `assets/sound/`

Old Cocos build/cache/source directories have `.gdignore` files so Godot does not waste time importing them.

