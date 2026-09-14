extends SceneTree
func _initialize() -> void:
	var font = ThemeDB.fallback_font
	var data: PackedByteArray = font.data
	if data.is_empty():
		push_error("Godot fallback font has no exportable data")
		quit(1)
		return
	var file := FileAccess.open("D:/UGit/T0/To/Migration/Tools/resonance_default.woff2", FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	print("Exported fallback font: ", font.get_font_name(), " bytes=", data.size())
	quit()
