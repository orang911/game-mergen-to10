extends Control
class_name CardView

signal pressed

const BASE_SIZE := Vector2(257.0, 377.0)
const GREEN_KEY_SHADER := preload("res://shaders/ui_green_key.gdshader")
const STAR_ACTIVE_TEXTURE := preload("res://assets/runtime/ui/components/rating_stars/icons/star_active.png")
const STAR_SLOT_TEXTURE := preload("res://assets/runtime/ui/components/rating_stars/icons/star_slot.png")
const NEW_TEXTURE := preload("res://assets/runtime/ui/cards/frames/badge_new.png")

# These coordinates are measured against the 257x377 card-face mockup.
const TITLE_POS := Vector2(12.0, 8.0)
const TITLE_SIZE := Vector2(233.0, 50.0)
const ICON_POS := Vector2(32.0, 68.0)
const ICON_SIZE := Vector2(193.0, 120.0)
const DESCRIPTION_POS := Vector2(22.0, 207.0)
const DESCRIPTION_SIZE := Vector2(213.0, 108.0)
const STAR_POS := Vector2(45.0, 334.0)
const STAR_SIZE := Vector2(30.0, 30.0)
const STAR_STEP := 36.5
const NEW_BADGE_POS := Vector2(188.0, -1.0)
const NEW_BADGE_SIZE := Vector2(89.0, 67.0)

var card_id := ""
var card_level := 1
var is_new_card := false

var _inner: Control
var _front_layer: Control
var _back: TextureRect
var _button: Button
var _fit_scale := Vector2.ONE
var _revealed := false
var _interactable := false


func setup(new_card_id: String, level: int, show_new_badge: bool) -> void:
	card_id = new_card_id
	card_level = clampi(level, 1, GameConfig.MAX_CARD_LEVEL)
	is_new_card = show_new_badge
	_build()
	_fit_to_rect()
	show_back()


func set_interactable(enabled: bool) -> void:
	_interactable = enabled
	if _button:
		_button.disabled = not enabled
		_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW


func show_back() -> void:
	_revealed = false
	if _front_layer:
		_front_layer.visible = false
	if _back:
		_back.visible = true
	set_interactable(false)


func reveal(duration: float = 0.36) -> void:
	if _revealed or _inner == null:
		return
	var half := maxf(0.06, duration * 0.5)
	var close_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Use an ease-out curve for both halves: the card turns quickly at the
	# start of each half and settles gently at the midpoint/final face.
	close_tween.tween_property(_inner, "scale", Vector2(0.0, _fit_scale.y * 1.025), half).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await close_tween.finished
	_back.visible = false
	_front_layer.visible = true
	_revealed = true
	var open_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	open_tween.tween_property(_inner, "scale", _fit_scale, half).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await open_tween.finished


func is_revealed() -> bool:
	return _revealed


func _build() -> void:
	for child in get_children():
		child.queue_free()

	_inner = Control.new()
	_inner.name = "CardTransform"
	_inner.size = BASE_SIZE
	_inner.pivot_offset = BASE_SIZE * 0.5
	_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inner)

	_build_front()
	_build_back()

	_button = Button.new()
	_button.name = "CardHitArea"
	_button.flat = true
	_button.text = ""
	_button.focus_mode = Control.FOCUS_NONE
	_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_button.disabled = true
	_button.pressed.connect(func():
		if _interactable and _revealed:
			pressed.emit()
	)
	add_child(_button)


func _build_front() -> void:
	_front_layer = Control.new()
	_front_layer.name = "Front"
	_front_layer.size = BASE_SIZE
	_front_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner.add_child(_front_layer)

	var face := _texture(CardCatalog.get_front_texture(card_id), TextureRect.STRETCH_SCALE)
	face.name = "Face"
	face.size = BASE_SIZE
	face.material = _green_key_material()
	_front_layer.add_child(face)

	var definition := CardCatalog.get_definition(card_id)
	var icon := _texture(str(definition.get("icon", "")), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	icon.name = "Icon"
	var icon_rect := _get_icon_rect()
	_set_rect(icon, icon_rect.position, icon_rect.size)
	_front_layer.add_child(icon)

	var item_name := str(definition.get("item_name", card_id))
	var title := _label(item_name, _title_font_size(item_name), Color.WHITE, 4)
	title.name = "ItemName"
	_set_rect(title, TITLE_POS, TITLE_SIZE)
	_front_layer.add_child(title)

	var description_text := str(definition.get("description", ""))
	var description := _label(description_text, _description_font_size(description_text), Color.WHITE, 3)
	description.name = "Description"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_set_rect(description, DESCRIPTION_POS, DESCRIPTION_SIZE)
	_front_layer.add_child(description)

	_build_stars()
	if is_new_card:
		var badge := TextureRect.new()
		badge.name = "NewBadge"
		badge.texture = NEW_TEXTURE
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.material = _green_key_material()
		_set_rect(badge, NEW_BADGE_POS, NEW_BADGE_SIZE)
		_front_layer.add_child(badge)


func _build_back() -> void:
	_back = _texture(CardCatalog.get_back_texture(card_id), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_back.name = "Back"
	_back.size = BASE_SIZE
	_back.material = _green_key_material()
	_inner.add_child(_back)


func _build_stars() -> void:
	for i in range(GameConfig.MAX_CARD_LEVEL):
		var star_pos := STAR_POS + Vector2(i * STAR_STEP, 0.0)
		var slot := TextureRect.new()
		slot.name = "StarSlot_%d" % (i + 1)
		slot.texture = STAR_SLOT_TEXTURE
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(slot, star_pos, STAR_SIZE)
		_front_layer.add_child(slot)

		if i < card_level:
			var active := TextureRect.new()
			active.name = "StarActive_%d" % (i + 1)
			active.texture = STAR_ACTIVE_TEXTURE
			active.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			active.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			active.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_set_rect(active, star_pos, STAR_SIZE)
			_front_layer.add_child(active)


func _fit_to_rect() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		size = BASE_SIZE
	var uniform_scale := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	_fit_scale = Vector2.ONE * uniform_scale
	var fitted_size := BASE_SIZE * uniform_scale
	var fitted_offset := (size - fitted_size) * 0.5
	_inner.position = fitted_offset + BASE_SIZE * 0.5 * (_fit_scale - Vector2.ONE)
	_inner.scale = _fit_scale
	pivot_offset = size * 0.5


func _get_icon_rect() -> Rect2:
	# The ballista source includes intentional empty canvas space on its left and
	# bottom. This larger source rect reproduces its visible size in the mockup.
	if card_id == "thunder_ballista":
		return Rect2(Vector2(33.0, 79.0), Vector2(179.0, 116.0))
	return Rect2(ICON_POS, ICON_SIZE)


func _title_font_size(value: String) -> int:
	if value.length() <= 4:
		return 28
	if value.length() == 5:
		return 26
	return 24


func _description_font_size(value: String) -> int:
	var longest_line := 0
	for line in value.split("\n"):
		longest_line = maxi(longest_line, line.length())
	if longest_line <= 10:
		return 21
	if longest_line <= 13:
		return 19
	return 18


func _texture(path: String, mode: TextureRect.StretchMode) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(path) as Texture2D if not path.is_empty() else null
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = mode
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _label(value: String, font_size: int, color: Color, outline: int) -> Label:
	var node := Label.new()
	node.text = value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0.035, 0.055, 0.11, 1.0))
	node.add_theme_constant_override("outline_size", outline)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _set_rect(node: Control, pos: Vector2, node_size: Vector2) -> void:
	node.position = pos
	node.size = node_size
	node.pivot_offset = node_size * 0.5


func _green_key_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GREEN_KEY_SHADER
	return material
