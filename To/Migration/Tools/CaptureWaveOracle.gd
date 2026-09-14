extends SceneTree
var output:=""
func _init():
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
    call_deferred("_run")
func _run():
    var traces:Array=[]
    for delta in [1.0/60.0,1.0/30.0,0.20]:
        var system:=WaveSystem.new()
        system.setup(GameConfig.get_level_waves())
        system.start_first_wave()
        var state:Dictionary={"frame":0}
        var frames:Array=[]
        system.spawn_requested.connect(func(_kind,_hp,_tier,_overrides): frames.append(state["frame"]))
        for frame in range(3000):
            state["frame"]=frame
            system.settlement_frozen=frame>=10 and frame<70
            system._process(delta)
            if not system.spawning: break
        traces.append({"delta":delta,"frames":frames})
        system.free()
    var file:=FileAccess.open(output,FileAccess.WRITE)
    if file==null: quit(2); return
    file.store_string(JSON.stringify({"waves":GameConfig.get_level_waves(),"traces":traces},"\t"))
    file.close()
    quit(0)

