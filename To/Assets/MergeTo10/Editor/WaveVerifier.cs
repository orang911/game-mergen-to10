using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using UnityEngine;
using MergeTo10.Core;
namespace MergeTo10.Editor
{
 public static class WaveVerifier
 {
  [Serializable] class Oracle {public Wave[] waves;public Trace[] traces;}
  [Serializable] class Wave {public int small,medium,large,visual_tier;public double hp_multiplier,spawn_interval;}
  [Serializable] class Trace {public double delta;public int[] frames;}
  public static void Verify(string path)
  {
   var oracle=JsonUtility.FromJson<Oracle>(File.ReadAllText(path));
   if(oracle.waves.Length!=20)throw new Exception("20 waves required");
   for(int i=0;i<20;i++)
   {
    var source=oracle.waves[i];var counts=WaveFlow.Counts(i+1);
    if(!counts.SequenceEqual(new[]{source.small,source.medium,source.large}))throw new Exception("Wave counts "+i);
    var wave=new WaveFlow();wave.Start(i,new System.Random(1));var spawned=new List<WaveFlow.Spawn>();wave.Spawned+=s=>spawned.Add(s);
    for(int f=0;f<20000&&wave.Spawning;f++)wave.Tick(1.0/60,false,false);
    if(spawned.Count!=counts.Sum())throw new Exception("Spawn totals "+i);
    foreach(var s in spawned)if(s.Tier!=source.visual_tier||Math.Abs(s.HpMultiplier-source.hp_multiplier)>1e-8)throw new Exception("Spawn stats "+i);
    wave.Tick(1,false,true);if(i==19?!wave.Completed:!wave.AwaitingReward)throw new Exception("Clear boundary "+i);
    int before=wave.Index;wave.Tick(10,false,true);if(wave.Index!=before)throw new Exception("Auto advanced reward");
   }
   foreach(var t in oracle.traces)
   {
    var flow=new WaveFlow();flow.Start(0,new System.Random(1));
    var frames=new List<int>();int frame=0;flow.Spawned+=s=>frames.Add(frame);
    for(frame=0;frame<3000&&flow.Spawning;frame++)flow.Tick(t.delta,frame>=10&&frame<70,false);
    if(!frames.SequenceEqual(t.frames))throw new Exception("Godot spawn frame mismatch delta="+t.delta+" actual="+string.Join(",",frames)+" source="+string.Join(",",t.frames));
   }
   var check=new WaveFlow();check.Start(0,new System.Random(2));
   check.Tick(100,true,true);if(check.Remaining!=15||check.AwaitingReward)throw new Exception("Frozen spawn/clear");
  }
 }
}

