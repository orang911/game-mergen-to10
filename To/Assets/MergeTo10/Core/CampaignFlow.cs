using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using Random=System.Random;
namespace MergeTo10.Core
{
 [Serializable] public sealed class CampaignData {
  public string chapter_id,title;public CampaignWave[] waves;
  public static CampaignData Load()=>JsonUtility.FromJson<CampaignData>(Resources.Load<TextAsset>("Campaign/chapter").text);
 }
 [Serializable] public sealed class CampaignWave {
  public string id,node_id,chapter_reward,display_label;
  public bool tutorial_placeholder,segment_end,chapter_final,continuation,allow_random_energy_imprint;
  public int small,medium,large,visual_tier=1,continuation_index;
  public double hp_multiplier=1,spawn_interval=1;
  public CampaignSpawn[] spawn_sequence;
 }
 [Serializable] public sealed class CampaignSpawn {
  public string monster_type="small";public double hp_multiplier=1,delay_after=-1;public int visual_tier=1;
  public MonsterOverrides overrides;
 }
 [Serializable] public sealed class MonsterOverrides {
  public float hp,speed,scale;public int durability_damage;public string appearance_id;public bool is_boss;
 }
 [Serializable] public sealed class CampaignWaveState {
  public int Index=-1,Total,Cleared,ScriptedRemaining,Pattern,Pending;
  public bool Running,Spawning,AwaitingReward,Completed,Scripted;
  public double Timer,MemberTimer;public List<CampaignSpawn> Queue=new List<CampaignSpawn>();
 }
 // Separate from the existing 20-wave fixture: no silent replacement of legacy tests.
 public sealed class CampaignFlow {
  public readonly CampaignData Data;public CampaignWaveState State{get;private set;}=new CampaignWaveState();
  public CampaignWave Current=>State.Index>=0&&State.Index<Data.waves.Length?Data.waves[State.Index]:null;
  public event Action<CampaignSpawn> Spawned;
  public event Action<int> Started,Cleared;
  public CampaignFlow(CampaignData data){Data=data??throw new ArgumentNullException(nameof(data));}
  public void Start(int index,Random random){
   if(index<0||index>=Data.waves.Length)throw new ArgumentOutOfRangeException(nameof(index));
   int cleared=State.Cleared;State=new CampaignWaveState{Index=index,Cleared=cleared};
   var wave=Current;
   if(wave.tutorial_placeholder){State.Scripted=true;State.ScriptedRemaining=State.Total=5;Started?.Invoke(index);return;}
   State.Running=State.Spawning=true;
   if(wave.spawn_sequence!=null&&wave.spawn_sequence.Length>0){
    foreach(var spawn in wave.spawn_sequence)State.Queue.Add(Clone(spawn));
   }else{
    int[] counts={wave.small,wave.medium,wave.large};string[] types={"small","medium","large"};
    for(int type=0;type<3;type++)for(int i=0;i<counts[type];i++)
     State.Queue.Add(new CampaignSpawn{monster_type=types[type],hp_multiplier=wave.hp_multiplier,visual_tier=wave.visual_tier});
    for(int i=State.Queue.Count-1;i>0;i--){int j=random.Next(i+1);var item=State.Queue[i];State.Queue[i]=State.Queue[j];State.Queue[j]=item;}
   }
   State.Total=State.Queue.Count;Started?.Invoke(index);
  }
  static CampaignSpawn Clone(CampaignSpawn item)=>JsonUtility.FromJson<CampaignSpawn>(JsonUtility.ToJson(item));
  public void CompleteTutorial(){
   if(!State.Scripted)return;State.Scripted=false;State.ScriptedRemaining=0;CompleteWave();
  }
  public void Tick(double delta,bool frozen,bool monstersClear){
   if(delta<0||double.IsNaN(delta)||double.IsInfinity(delta))throw new ArgumentOutOfRangeException(nameof(delta));
   if(frozen||!State.Running||State.Scripted||State.Completed||State.AwaitingReward)return;
   bool emitted=false;
   if(State.Spawning){
    if(State.Pending>0){State.MemberTimer-=delta;if(State.MemberTimer<=0)emitted=Emit();}
    else{
     State.Timer-=delta;
     if(State.Timer<=0){
      if(State.Queue.Count==0)State.Spawning=false;
      else{
       bool sequence=Current.spawn_sequence!=null&&Current.spawn_sequence.Length>0;
       State.Pending=Math.Min(sequence?1:State.Pattern+1,State.Queue.Count);
       if(!sequence)State.Pattern=(State.Pattern+1)%4;
       emitted=Emit();
      }
     }
    }
   }
   if(!emitted&&!State.Spawning&&monstersClear)CompleteWave();
  }
  bool Emit(){
   if(State.Pending<=0||State.Queue.Count==0){State.Pending=0;State.Spawning=State.Queue.Count>0;return false;}
   var spawn=State.Queue[0];State.Queue.RemoveAt(0);State.Pending--;
   if(State.Pending>0)State.MemberTimer=.08;
   else if(State.Queue.Count==0)State.Spawning=false;
   else State.Timer=Math.Max(.05,spawn.delay_after>=0?spawn.delay_after:Math.Max(.35,Current.spawn_interval));
   Spawned?.Invoke(spawn);return true;
  }
  void CompleteWave(){
   State.Running=false;State.Cleared++;
   if(State.Index==Data.waves.Length-1)State.Completed=true;else State.AwaitingReward=true;
   Cleared?.Invoke(State.Index);
  }
  public void Continue(Random random){if(State.AwaitingReward)Start(State.Index+1,random);}
  public string Export()=>JsonUtility.ToJson(State);
  public void Restore(string json){
   var restored=JsonUtility.FromJson<CampaignWaveState>(json);
   if(restored==null||restored.Index<0||restored.Index>=Data.waves.Length||restored.Queue==null||restored.Scripted||restored.Index==0||
    restored.Total<0||restored.Cleared<0||double.IsNaN(restored.Timer)||double.IsInfinity(restored.Timer)||
    restored.Queue.Any(s=>s==null||s.visual_tier<1||s.visual_tier>3||double.IsNaN(s.hp_multiplier)||double.IsInfinity(s.hp_multiplier)||s.hp_multiplier<=0||
     (s.monster_type!="small"&&s.monster_type!="medium"&&s.monster_type!="large")))throw new ArgumentException("Invalid campaign snapshot");
   State=restored;
   // Godot restore intentionally resets batch cadence; preserve that behavior.
   State.Pattern=State.Pending=0;State.MemberTimer=0;
   Started?.Invoke(State.Index);
  }
 }
}
