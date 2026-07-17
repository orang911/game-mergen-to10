extends Control
class_name MergeAttackPromptView

const DISPLAY_SIZE := Vector2(640.0, 64.0)
const NUMBER_RECT := Rect2(435.0, 3.0, 160.0, 58.0)
const START_OFFSET := Vector2(0.0, 24.0)
const ENTER_DURATION := 0.18
const HOLD_DURATION := 0.30
const EXIT_DURATION := 0.27

@onready var _background: TextureRect = $Background
@onready var _attack_value: Label = $AttackValue


func play(texture: Texture2D, attack_value: int, target_position: Vector2) -> void:
	_background.texture = texture
	_attack_value.text = str(attack_value)
	position = target_position + START_OFFSET
	pivot_offset = DISPLAY_SIZE * 0.5
	scale = Vector2(0.96, 0.96)
	modulate.a = 0.0

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "position", target_position, ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 1.0, ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2.ONE, ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.set_parallel(false)
	t.tween_interval(HOLD_DURATION)
	t.tween_property(self, "modulate:a", 0.0, EXIT_DURATION)
	t.tween_callback(queue_free)
