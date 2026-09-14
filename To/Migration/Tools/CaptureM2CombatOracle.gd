extends SceneTree
# Read-only frozen classes executed from WorkingGodot.
var output := ""
func _init() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output="):
            output=argument.trim_prefix("--output=")
    call_deferred("_run")
func _event(e: MergeAttackEvent) -> Dictionary:
    var params: Array=[]
    for key in e.effect_params:
        if e.effect_params[key] is int or e.effect_params[key] is float:
            params.append({"key":key,"value":e.effect_params[key]})
    return {"source":e.source_level,"result":e.result_level,"attack_level":e.attack_level,
        "element":e.element_key,"tier":e.element_tier,"count":e.merge_count,"attacks":e.attack_count,
        "targets":e.target_count,"damage":e.damage,"total":e.total_damage,"params":params}
func _run() -> void:
    if output.is_empty():
        quit(1)
        return
    var cases: Array=[]
    for source in range(1,36):
        for count in range(2,26):
            cases.append(_event(MergeAttackEvent.from_merge(source,source+1,count,Vector2(20,40),3)))
    var batches: Array=[]
    for seed_index in range(200):
        var batch:=MergeChainBatch.new()
        var raw: Array=[]
        for i in range(1+seed_index%5):
            var source:=1+(seed_index*7+i*(5 if seed_index%2==0 else 11))%35
            var count:=2+(seed_index*3+i*5)%24
            var e:=MergeAttackEvent.from_merge(source,source+1,count,Vector2(20,40),3)
            batch.add_event(e,i>0)
            raw.append(_event(e))
        batch.finalize_combo()
        var events: Array=[]
        for e in batch.events:
            events.append(_event(e))
        batches.append({"raw":raw,"events":events,"combo":batch.combo_level,"multiplier":batch.combo_multiplier,"key":batch.combo_key})
    DirAccess.make_dir_recursive_absolute(output.get_base_dir())
    var file:=FileAccess.open(output,FileAccess.WRITE)
    if file==null:
        quit(2)
        return
    file.store_string(JSON.stringify({"cases":cases,"batches":batches},"\t"))
    file.close()
    print("M2_ORACLE cases=",cases.size()," batches=",batches.size())
    quit(0)
