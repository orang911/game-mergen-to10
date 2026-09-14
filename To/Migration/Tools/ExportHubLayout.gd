extends SceneTree
var output := "D:/UGit/T0/To/Assets/MergeTo10/Resources/Campaign/"
var items := []
var serial := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(941, 1672)
	var hub = load("res://scenes/ui/main_hub.tscn").instantiate()
	root.add_child(hub)
	hub.layout_for_viewport(Vector2(941,1672))
	hub.set_interactive(true)
	await process_frame
	visit(hub)
	var fill = hub.get_node("DesignRoot/MissionProgressFillClip/Fill")
	fill.visible=true
	visit(fill)
	var frames = hub.FOREST_ISLAND_LOOP
	var frame_count: int = frames.get_frame_count(&"default")
	for index in range(frame_count):
		frames.get_frame_texture(&"default",index).get_image().save_png(output+"hub_forest_"+str(index)+".png")
	var file := FileAccess.open(output+"hub_layout.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"items":items,"forestFrames":frame_count,"forestFps":frames.get_animation_speed(&"default")},"\t"))
	print("Exported live lobby widgets: ",items.size())
	quit()
func visit(node: Node) -> void:
	if node is Control and not node.is_visible_in_tree():
		return
	if node is Control:
		var rect: Rect2 = node.get_global_rect()
		var entry := {"name":str(node.name),"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y,"kind":"","key":"","text":"","font":24,"align":1,"color":[1,1,1,1],"border":[0,0,0,0],"outline":0,"aspect":false}
		var texture: Texture2D = null
		if node is TextureRect:
			texture=node.texture
			entry.aspect=node.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		elif node is NinePatchRect:
			texture=node.texture
			entry.border=[node.patch_margin_left,node.patch_margin_bottom,node.patch_margin_right,node.patch_margin_top]
		elif node is Button:
			entry.kind="button"
			var style=node.get_theme_stylebox("normal")
			if style is StyleBoxTexture:
				texture=style.texture
				entry.border=[style.texture_margin_left,style.texture_margin_bottom,style.texture_margin_right,style.texture_margin_top]
		elif node is Label:
			entry.kind="text"
			entry.text=node.text
			entry.font=node.get_theme_font_size("font_size")
			entry.align=node.horizontal_alignment
			entry.outline=node.get_theme_constant("outline_size")
		var tint: Color = node.modulate*node.self_modulate
		if node is Label:
			tint*=node.get_theme_color("font_color")
		entry.color=[tint.r,tint.g,tint.b,tint.a]
		if texture:
			entry.key="hub_piece_"+str(serial)
			serial+=1
			texture.get_image().save_png(output+entry.key+".png")
			if entry.kind=="":
				entry.kind="image"
		if entry.kind!="":
			items.append(entry)
	for child in node.get_children():
		visit(child)
