using System;
using System.Linq;
using UnityEngine;
namespace MergeTo10.Core
{
 [Serializable] public sealed class CardDefinition {public string id,type,item_name,skill_name,description,icon;}
 [Serializable] public sealed class CardRules {
  public CardDefinition[] cards;
  public int[] baseAttack,extraTargets;
  public double[] damageUp,interval,pierceRatio,fireDps,fireDuration,poisonDps,poisonDuration,thunderRatio;
  public static CardRules Load()=>JsonUtility.FromJson<CardRules>(Resources.Load<TextAsset>("Campaign/cards").text);
 }
 [Serializable] public sealed class CrystalState {
  public int Level=1,ExtraTargets,PierceTargets;
  public bool Awakened=true;
  public double Timer=.9,DamageMultiplier=1,SpeedMultiplier=1,PierceRatio;
  public int[] Elements=new int[4]; // fire, ice, poison, lightning (source application order)
 }
 public sealed class CrystalProgress {
  public readonly CardRules Rules;
  public CrystalState State{get;private set;}=new CrystalState();
  public bool MergeUpgradesEnabled; // Frozen GameConfig default false.
  public CrystalProgress(CardRules rules){Rules=rules??throw new ArgumentNullException(nameof(rules));}
  public double Interval=>Math.Max(.24,1.8*State.SpeedMultiplier);
  public int Damage=>(int)Math.Floor(Rules.baseAttack[State.Level-1]*.3*State.DamageMultiplier+.5);
  public void NotifyMerge(int result){if(MergeUpgradesEnabled&&(result==3||result==5||result==7))State.Level=Math.Min(9,State.Level+1);}
  public bool Tick(double delta,bool running,bool frozen){
   if(delta<0||double.IsNaN(delta)||double.IsInfinity(delta))throw new ArgumentException("Invalid delta");
   if(!running||frozen||!State.Awakened)return false;
   State.Timer-=delta;if(State.Timer>0)return false;State.Timer=Interval;return true;
  }
  public void Awaken(){if(!State.Awakened){State.Awakened=true;State.Timer=1.8;}}
  public bool Apply(string card,int quality){
   int q=Math.Max(1,Math.Min(5,quality))-1;
   switch(card){
    case "fire_conduit":State.Elements[0]=Math.Max(State.Elements[0],q+1);break;
    case "frost_prism":State.Elements[1]=Math.Max(State.Elements[1],q+1);break;
    case "poison_tank":State.Elements[2]=Math.Max(State.Elements[2],q+1);break;
    case "thunder_spire":State.Elements[3]=Math.Max(State.Elements[3],q+1);break;
    case "star_boiler":State.DamageMultiplier+=Rules.damageUp[q];break;
    case "rapid_clockwork":State.SpeedMultiplier*=Rules.interval[q];break;
    case "twin_lens":State.ExtraTargets+=Rules.extraTargets[q];break;
    case "piercing_cannon":State.PierceTargets=Math.Min(3,State.PierceTargets+1);State.PierceRatio=Math.Max(State.PierceRatio,Rules.pierceRatio[q]);break;
    default:return false;
   }
   return true;
  }
  // ExtraTargets is intentionally retained as source state. The frozen charged
  // shot does not consume it; inventing extra shots here would change gameplay.
  public void ApplyInstalled(BattleMonster target,double damage){
   if(!target.Alive)return;
   for(int element=0;element<4;element++){
    int q=State.Elements[element]-1;if(q<0)continue;
    if(element==1){target.Ice=2;continue;}if(element==3){target.Stun=1;continue;}
    var layer=new BattleMonster.Layer{Remaining=element==0?Rules.fireDuration[q]:Rules.poisonDuration[q],Power=damage*(element==0?Rules.fireDps[q]:Rules.poisonDps[q])};
    target.AddStatusLayer(element==2,layer);
   }
  }
  public string Export()=>JsonUtility.ToJson(State);
  public void Restore(string json){
   var state=JsonUtility.FromJson<CrystalState>(json);
   if(state==null||state.Elements?.Length!=4||state.Elements.Any(v=>v<0||v>5))throw new ArgumentException("Invalid crystal snapshot");
   var numbers=new[]{state.Timer,state.DamageMultiplier,state.SpeedMultiplier,state.PierceRatio};
   if(numbers.Any(v=>double.IsNaN(v)||double.IsInfinity(v)))throw new ArgumentException("Nonfinite crystal snapshot");
   state.Level=Math.Max(1,Math.Min(9,state.Level));state.Timer=Math.Max(0,state.Timer);
   state.DamageMultiplier=Math.Max(.1,state.DamageMultiplier);state.SpeedMultiplier=Math.Max(.1,state.SpeedMultiplier);
   state.ExtraTargets=Math.Max(0,state.ExtraTargets);state.PierceTargets=Math.Max(0,state.PierceTargets);state.PierceRatio=Math.Max(0,state.PierceRatio);State=state;
  }
 }
}
