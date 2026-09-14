using System;
using System.IO;
using System.Linq;
using MergeTo10.Core;
using UnityEngine;
namespace MergeTo10.Editor
{
 public static class M2CoreVerifier
 {
  [Serializable] class Oracle {public Sample[] cases;public Batch[] batches;}
  [Serializable] class Parameter {public string key;public double value;}
  [Serializable] class Sample {public int source,result,attack_level,tier,count,attacks,targets;public string element;public double damage,total;public Parameter[] @params;}
  [Serializable] class Batch {public Sample[] raw,events;public int combo;public double multiplier;public string key;}
  static int checks;
  static void Check(bool ok,string label){checks++;if(!ok)throw new Exception("M2: "+label);}
  static void Near(double a,double b,string label){Check(Math.Abs(a-b)<=1e-10*Math.Max(1,Math.Abs(b)),label+" actual="+a+" expected="+b);}
  static MergeAttack Make(Sample s)=>new MergeAttack(s.source,s.result,s.count,20,40,3);
  static void Compare(MergeAttack a,Sample s)
  {
   Check(a.SourceLevel==s.source&&a.ResultLevel==s.result&&a.AttackLevel==s.attack_level,"levels");
   Check(a.ElementKey==s.element&&a.Tier==s.tier,"element/tier");
   Check(a.MergeCount==s.count&&a.AttackCount==s.attacks&&a.TargetCount==s.targets,"counts");
   Near(a.Damage,s.damage,"damage");Near(a.TotalDamage,s.total,"total");
   Check(a.Effects.Count==s.@params.Length,"parameter count");
   foreach(var p in s.@params){Check(a.Effects.ContainsKey(p.key),"parameter "+p.key);Near(a.Effects[p.key],p.value,p.key);}
   Near(a.OriginX,20,"origin x");Near(a.OriginY,40,"origin y");Check(a.Row==3,"row");
  }
  public static string Verify(string path)
  {
   checks=0;var oracle=JsonUtility.FromJson<Oracle>(File.ReadAllText(path));
   Check(oracle.cases.Length==840&&oracle.batches.Length==200,"oracle coverage");
   foreach(var s in oracle.cases)Compare(Make(s),s);
   bool duplicates=false,five=false;
   foreach(var b in oracle.batches)
   {
    var batch=new MergeAttackBatch(b.raw.Select(Make));
    Check(batch.Events.Count==b.events.Length&&batch.RawEvents.Count==b.raw.Length,"batch sizes");
    Check(batch.ComboKey==b.key&&batch.ComboLevel==b.combo,"combo key/level");Near(batch.ComboMultiplier,b.multiplier,"combo multiplier");
    for(int i=0;i<b.events.Length;i++)
    {
     Compare(batch.Events[i],b.events[i]);
     Check(batch.Events[i].Contributions.Count==b.raw.Count(s=>s.element==b.events[i].element),"raw contribution count");
    }
    duplicates|=batch.RawEvents.Count>batch.Events.Count;five|=batch.Events.Count==5;
   }
   Check(duplicates&&five,"duplicates and five elements covered");
   var ice=new MergeAttackBatch(new[]{new MergeAttack(2,3,2),new MergeAttack(7,8,4)}).Events[0];
   Near(ice.IceDamageForTarget(0),38,"ice shared target");Near(ice.IceDamageForTarget(1),32,"ice larger group only");
   Near(ice.IceDamageForTarget(3),0,"ice no recycled spare shots");
   var crit=new MergeAttackBatch(new[]{new MergeAttack(4,5,2),new MergeAttack(9,10,3)}).Events[0];
   int rolls=0;double[] fixedRolls={0,.25,.29,.30,1};
   Near(crit.ResolvePrimaryDamage(()=>fixedRolls[rolls++]),21+100.0/3*4,"critical raw shot rolls");
   Check(rolls==5,"critical rolls not collapsed");
   var clock=new CombatClock();clock.Advance(100,0,false,false);
   clock.Advance(100.5,.02,false,true);Near(clock.AttackTime,.5,"freeze preserves attack clock");Near(clock.SimulationTime,0,"freeze stops simulation");
   clock.Advance(120.5,10,true,false);Near(clock.AttackTime,.5,"pause excludes wall time");
   clock.Advance(120.75,.03,false,false);Near(clock.AttackTime,.75,"resume without catchup");Near(clock.SimulationTime,.03,"frame simulation separate");
   clock.Reset();clock.Advance(200,0,false,false);Near(clock.AttackTime,0,"clock reset");
   return "PASS M2 foundation assertions="+checks+" rawCases=840 batches=200. Combat rendering, statuses, wave simulation and device parity NOT certified.";
  }
 }
}

