extends SceneTree
# Runs against WorkingGodot. Uses the frozen visual classes, not a recreation of their shaders.
const BlockScript = preload("res://scripts/block.gd")
const ShadowScript = preload("res://scripts/board_shadow_layer.gd")
var output := ""
var viewport: SubViewport
func _init() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--capture-dir="):
            output=argument.trim_prefix("--capture-dir=")
    call_deferred("_run")

func _run() -> void:
    if output.is_empty():
        quit(1)
        return
    DirAccess.make_dir_recursive_absolute(output)
    _write_oracle()
    if DisplayServer.get_name()=="headless":
        quit(0)
        return
    viewport=SubViewport.new()
    viewport.size=Vector2i(470,836)
    viewport.world_2d=World2D.new()
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var layer := Control.new()
    viewport.add_child(layer)
    var design := Vector2(941,1672)
    var factor := minf(470.0/941.0,836.0/1672.0)
    layer.position=(Vector2(viewport.size)-design*factor)*0.5
    layer.scale=Vector2.ONE*factor
    _texture(layer,"res://assets/runtime/ui/interfaces/battle/standalone/battle_background.png",Vector2.ZERO,Vector2(viewport.size)/factor,0)
    _texture(layer,"res://assets/runtime/ui/interfaces/battle/board/standalone/battle_board_backdrop.png",Vector2(136,688.36),Vector2(653.68,649.39),6)
    var board := Control.new()
    layer.add_child(board)
    board.position=Vector2(137.55,690.79)
    board.size=Vector2(633,633)
    board.pivot_offset=Vector2(316.5,633)
    board.scale=Vector2.ONE*0.95
    board.z_as_relative=false
    board.z_index=8
    var shadow=ShadowScript.new()
    shadow.z_as_relative=false
    shadow.z_index=7
    board.add_child(shadow)
    shadow.configure(Vector2(633,633))
    var textures := {}
    for color in ["green","blue","yellow","purple","red"]:
        textures[color]=load("res://assets/runtime/ui/components/board_tiles/atlas_regions/block_%s.tres" % color)
    var values := [2,2,2,2,2,2,1,1,1,3,3,2,2,2,2,3,2,3,2,3,2,1,3,3,3]
    for index in range(25):
        var block=BlockScript.new()
        board.add_child(block)
        block.setup(values[index],textures)
        block.board_site=Vector2i(index%5,index/5)
        block.position=Vector2(37.5+(index%5)*113,32.5+(4-index/5)*113)
    await create_timer(0.3).timeout
    await RenderingServer.frame_post_draw
    viewport.get_texture().get_image().save_png(output.path_join("godot-initial.png"))
    shadow.visible=false
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    viewport.get_texture().get_image().save_png(output.path_join("godot-without-shadow.png"))
    var source_block:MergeBlock
    for child in board.get_children():
        if child is MergeBlock:
            if child.board_site==Vector2i(2,2):
                source_block=child
            child.visible=false
    var ghost=load("res://scripts/merge_trail_ghost.gd").new()
    ghost.setup_from_block(source_block)
    board.add_child(ghost)
    var progress:float=Tween.interpolate_value(0.0,1.0,0.10,0.18*1.12,Tween.TRANS_QUAD,Tween.EASE_OUT)
    var ghost_scale:float=Tween.interpolate_value(1.0,-0.26,0.10,0.18*1.12,Tween.TRANS_SINE,Tween.EASE_OUT)
    ghost.position=source_block.position+Vector2(113,0)*progress
    ghost.scale=Vector2.ONE*0.96*ghost_scale
    ghost.pivot_offset=Vector2.ONE*58
    ghost.trail_alpha=0.38
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    viewport.get_texture().get_image().save_png(output.path_join("godot-ghost-probe.png"))
    print("M1_GODOT_REFERENCE_OK")
    quit(0)

func _texture(parent:Node,path:String,position:Vector2,size:Vector2,order:int) -> void:
    var view := TextureRect.new()
    view.texture=load(path)
    view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    view.position=position
    view.size=size
    view.z_index=order
    parent.add_child(view)

func _write_oracle() -> void:
    var samples:Array=[]
    for action in [0.045,0.12,0.18,0.30]:
        for delay in [0.0,0.12,0.50]:
            var travel := maxf(0.12,float(action)*1.12)
            var fade_in := minf(0.06,travel*0.45)
            for age in [0.0,delay-0.01,delay,delay+0.025,delay+0.06,delay+travel*0.5,delay+travel,delay+travel+0.045,delay+travel+0.09,delay+travel+0.18,delay+travel+0.3]:
                var elapsed := maxf(0,float(age)-float(delay))
                var progress:float=Tween.interpolate_value(0.0,1.0,minf(elapsed,travel),travel,Tween.TRANS_QUAD,Tween.EASE_OUT)
                var scale:float=Tween.interpolate_value(1.0,-0.26,minf(elapsed,travel),travel,Tween.TRANS_SINE,Tween.EASE_OUT)
                var opacity:float
                if elapsed<=travel:
                    opacity=Tween.interpolate_value(0.0,0.38,minf(elapsed,fade_in),fade_in,Tween.TRANS_SINE,Tween.EASE_OUT)
                else:
                    opacity=Tween.interpolate_value(0.38,-0.38,minf(elapsed-travel,0.18),0.18,Tween.TRANS_SINE,Tween.EASE_IN)
                samples.append({"age":age,"delay":delay,"duration":action,"progress":progress,"scale":scale,"opacity":opacity})
    var file := FileAccess.open(output.path_join("feedback_oracle.json"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"samples":samples},"  "))
    file.close()
