extends Control
class_name CrystalChoiceCardViewV2

const UiTypographyScript := preload("res://scripts/ui_typography.gd")

signal pressed

const BASE_SIZE := Vector2(225.0, 420.0)
const CARD_TEXTURE := preload("res://assets/runtime/ui/interfaces/crystal_card_choice/backplates/ui_choice_card_with_slot_blank_450x840_2x_v01.png")
const NEW_BADGE_TEXTURE := preload("res://assets/runtime/ui/interfaces/crystal_card_choice/decorations/ui_badge_corner_blank_96x96_2x_v01.png")
const STAR_ACTIVE_TEXTURE := preload("res://assets/runtime/ui/components/rating_stars/icons/star_active.png")
const STAR_SLOT_TEXTURE := preload("res://assets/runtime/ui/components/rating_stars/icons/star_slot.png")
const GREEN_KEY_SHADER := preload("res://shaders/ui_green_key.gdshader")

const ICON_RECT := Rect2(54.0, 7.0, 117.0, 110.0)
const NAME_RECT := Rect2(12.0, 128.0, 201.0, 52.0)
const STAR_POS := Vector2(16.0, 222.0)
const STAR_SIZE := Vector2(29.0, 29.0)
const STAR_STEP := 41.0
const DESCRIPTION_RECT := Rect2(16.0, 266.0, 193.0, 125.0)
const NEW_BADGE_RECT := Rect2(174.0, -10.0, 56.0, 56.0)

var card_id := ""
var card_level := 1
var is_new_card := false

var _inner: Control
var _front: Control
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
	if _front:
		_front.visible = false
	if _back:
		_back.visible = true
	set_interactable(false)


func reveal(duration: float = 0.34) -> void:
	if _revealed or _inner == null:
		return
	var half := maxf(0.06, duration * 0.5)
	var close_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	close_tween.tween_property(_inner, "scale", Vector2(0.0, _fit_scale.y * 1.02), half).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await close_tween.finished
	if not is_instance_valid(_inner):
		return
	_back.visible = false
	_front.visible = true
	_revealed = true
	var open_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	open_tween.tween_property(_inner, "scale", _fit_scale, half).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


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
	_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	_button.disabled = true
	_button.pressed.connect(func():
		if _interactable and _revealed:
			pressed.emit()
	)
	add_child(_button)


func _build_front() -> void:
	_front = Control.new()
	_front.name = "Front"
	_front.size = BASE_SIZE
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner.add_child(_front)

	var face := TextureRect.new()
	face.name = "Backplate"
	face.texture = CARD_TEXTURE
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(face, Vector2.ZERO, BASE_SIZE)
	_front.add_child(face)

	var definition := CardCatalog.get_definition(card_id)
	var icon := _texture_from_path(str(definition.get("icon", "")))
	icon.name = "Icon"
	_set_rect(icon, ICON_RECT.position, ICON_RECT.size)
	_front.add_child(icon)

	var item_name := str(definition.get("item_name", card_id))
	var name_label := _label(item_name, _name_font_size(item_name), Color(0.23, 0.075, 0.018, 1.0), 3, 850)
	name_label.name = "ItemName"
	name_label.add_theme_color_override("font_outline_color", Color(1.0, 0.96, 0.84, 1.0))
	_set_rect(name_label, NAME_RECT.position, NAME_RECT.size)
	_front.add_child(name_label)

	_build_stars()

	var description_text := str(definition.get("description", ""))
	var description := _label(description_text, _description_font_size(description_text), Color(0.20, 0.075, 0.035, 1.0), 0, 700)
	description.name = "Description"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description.clip_text = true
	description.add_theme_constant_override("line_spacing", 2)
	_set_rect(description, DESCRIPTION_RECT.position, DESCRIPTION_RECT.size)
	_front.add_child(description)

	if is_new_card:
		var badge := TextureRect.new()
		badge.name = "NewBadge"
		badge.texture = NEW_BADGE_TEXTURE
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(badge, NEW_BADGE_RECT.position, NEW_BADGE_RECT.size)
		_front.add_child(badge)
		var badge_label := _label("新", 24, Color.WHITE, 4)
		badge_label.name = "Label"
		_set_rect(badge_label, Vector2.ZERO, badge.size)
		badge.add_child(badge_label)


func _build_back() -> void:
	_back = _texture_from_path(CardCatalog.get_back_texture(card_id))
	_back.name = "Back"
	_back.material = _green_key_material()
	_set_rect(_back, Vector2.ZERO, BASE_SIZE)
	_inner.add_child(_back)


func _build_stars() -> void:
	for index in range(GameConfig.MAX_CARD_LEVEL):
		var star_position := STAR_POS + Vector2(float(index) * STAR_STEP, 0.0)
		var slot := TextureRect.new()
		slot.name = "StarSlot_%d" % (index + 1)
		slot.texture = STAR_SLOT_TEXTURE
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(slot, star_position, STAR_SIZE)
		_front.add_child(slot)
		if index < card_level:
			var active := TextureRect.new()
			active.name = "StarActive_%d" % (index + 1)
			active.texture = STAR_ACTIVE_TEXTURE
			active.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			active.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			active.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_set_rect(active, star_position, STAR_SIZE)
			_front.add_child(active)


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


func _name_font_size(value: String) -> int:
	if value.length() <= 4:
		return 32
	if value.length() <= 6:
		return 29
	return 25


func _description_font_size(value: String) -> int:
	var longest_line := 0
	for line in value.split("\n"):
		longest_line = maxi(longest_line, line.length())
	# Cards are authored at 225 px and displayed around 1.26x larger. Keeping
	# the base copy at 15–18 px prevents an eleven-character Chinese line from
	# leaving a single orphan glyph on the following row after scaling.
	if longest_line <= 9:
		return 18
	if longest_line <= 11:
		return 17
	return 15


func _texture_from_path(path: String) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _label(value: String, font_size: int, color: Color, outline_size: int, font_weight: int = 800) -> Label:
	var node := Label.new()
	node.text = value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0.14, 0.055, 0.02, 1.0))
	node.add_theme_constant_override("outline_size", outline_size)
	UiTypographyScript.apply(node, font_weight)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _set_rect(node: Control, position: Vector2, node_size: Vector2) -> void:
	node.position = position
	node.size = node_size
	node.pivot_offset = node_size * 0.5


func _green_key_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GREEN_KEY_SHADER
	return material
