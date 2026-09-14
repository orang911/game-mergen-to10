using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
namespace MergeTo10.Core
{
 public sealed class BattlePath
 {
  public readonly Vector2[] Points;
  public readonly float Length;
  public float Goal=>Mathf.Clamp01((Length-64)/Length);
  public BattlePath()
  {
   float[] xy={240,60,220,82,230,110,275,135,1150,135,1215,145,1260,175,1280,230,1280,1510,1260,1585,1200,1655,180,1655,110,1625,82,1550,82,600,105,515,175,455,300,450,560,450};
   Points=new Vector2[xy.Length/2];
   for(int i=0;i<Points.Length;i++){Points[i]=new Vector2(44.11f,344.67f)+new Vector2(xy[i*2],xy[i*2+1])*(941f/1536);if(i>0)Length+=Vector2.Distance(Points[i-1],Points[i]);}
  }
  public Vector2 At(double progress)
  {
   double distance=progress*Length;
   for(int i=1;i<Points.Length;i++){float length=Vector2.Distance(Points[i-1],Points[i]);if(distance<=length||i==Points.Length-1)return Vector2.Lerp(Points[i-1],Points[i],(float)(distance/length));distance-=length;}
   return Points[0];
  }
 }
 public sealed class BattleMonster
 {
  public double Hp,MaxHp,Progress,Speed=80*4.0/3,HitStop,Stun,Ice;
  public bool Reached,Immune;
  public bool Annihilated {get;private set;}
  public void Annihilate(){if(Alive){Annihilated=true;Hp=0;}}
  public bool Alive=>Hp>0&&!Reached;
  public event Action<double> Damaged;
  public event Action<double,bool> DamageFeedback;
  [Serializable] public sealed class Layer {public double Remaining,Power;}
  [Serializable] public sealed class Snapshot {
   public double Hp,MaxHp,Progress,Speed,HitStop,Stun,Ice,PoisonTick;
   public bool Reached,Immune,Annihilated;
   public Layer[] Poison,Burn;
  }
  public Snapshot Capture()=>new Snapshot{Hp=Hp,MaxHp=MaxHp,Progress=Progress,Speed=Speed,HitStop=HitStop,Stun=Stun,Ice=Ice,
   PoisonTick=poisonTick,Reached=Reached,Immune=Immune,Annihilated=Annihilated,
   Poison=Poison.Select(l=>new Layer{Remaining=l.Remaining,Power=l.Power}).ToArray(),
   Burn=Burn.Select(l=>new Layer{Remaining=l.Remaining,Power=l.Power}).ToArray()};
  public static BattleMonster Restore(Snapshot state){
   if(state==null)throw new ArgumentNullException(nameof(state));
   double[] numbers={state.Hp,state.MaxHp,state.Progress,state.Speed,state.HitStop,state.Stun,state.Ice,state.PoisonTick};
   if(numbers.Any(v=>double.IsNaN(v)||double.IsInfinity(v)||v<0)||state.MaxHp<=0||state.Hp>state.MaxHp||state.Progress>1||state.PoisonTick>1||state.Poison==null||state.Burn==null||state.Poison.Length>4||state.Burn.Length>4)
    throw new ArgumentException("Invalid monster snapshot");
   var monster=new BattleMonster(state.MaxHp){Hp=state.Hp,Progress=state.Progress,Speed=state.Speed,HitStop=state.HitStop,
    Stun=state.Stun,Ice=state.Ice,poisonTick=state.PoisonTick,Reached=state.Reached,Immune=state.Immune,Annihilated=state.Annihilated};
   foreach(var pair in new[]{(state.Poison,monster.Poison),(state.Burn,monster.Burn)})foreach(var layer in pair.Item1){
    if(layer==null||double.IsNaN(layer.Remaining)||double.IsInfinity(layer.Remaining)||layer.Remaining<0||double.IsNaN(layer.Power)||double.IsInfinity(layer.Power)||layer.Power<0)throw new ArgumentException("Invalid status layer");
    pair.Item2.Add(new Layer{Remaining=layer.Remaining,Power=layer.Power});
   }
   // Godot keeps poison tick progress, but resets the burn floating-number accumulator.
   return monster;
  }
  public readonly List<Layer> Poison=new List<Layer>(),Burn=new List<Layer>();
  double poisonTick,burnFeedback,burnFeedbackTime;
  public BattleMonster(double hp){Hp=MaxHp=hp;}
  public void Damage(double amount,bool direct=true)
  {
   if(!Alive)return;if(direct&&amount>0)HitStop=Math.Max(HitStop,.1);
   double old=Hp;Hp=Math.Max(0,Hp-amount);if(old>Hp)Damaged?.Invoke(old-Hp);
   if(direct&&old>Hp)DamageFeedback?.Invoke(old-Hp,true);
  }
  public void Apply(MergeAttack part)
  {
   if(!Alive)return;
   if(part.Element==AttackElement.Ice){Ice=2;return;}
   if(part.Element==AttackElement.Lightning){Stun=1;return;}
   if(part.Element!=AttackElement.Fire&&part.Element!=AttackElement.Poison)return;
   var layer=new Layer{Remaining=part.Effects["duration"],Power=part.Damage*(part.Element==AttackElement.Poison?part.Effects["dps_ratio"]:part.Effects["splash_damage_ratio"]*.5)};
   AddStatusLayer(part.Element==AttackElement.Poison,layer);
  }
  public void AddStatusLayer(bool poison,Layer layer){
   if(!Alive)return;
   var list=poison?Poison:Burn;
   if(list==Poison&&list.Count==0)poisonTick=0;
   if(list==Burn&&list.Count==0){burnFeedback=0;burnFeedbackTime=0;}
   if(list.Count<4)list.Add(layer);else{int replace=0;for(int i=1;i<list.Count;i++)if(list[i].Remaining<list[replace].Remaining)replace=i;list[replace]=layer;}
  }
  public void Tick(double delta,BattlePath path)
  {
   if(!Alive)return;bool stopped=HitStop>0||Stun>0;HitStop=Math.Max(0,HitStop-delta);
   double remaining=delta;
   while(remaining>.000001&&Poison.Count>0)
   {
    double expiry=Poison.Where(l=>l.Remaining>.000001).Select(l=>l.Remaining).DefaultIfEmpty(double.PositiveInfinity).Min();
    double step=Math.Min(remaining,Math.Min(Math.Max(.000001,1-poisonTick),expiry));if(step<=.000001)break;
    foreach(var layer in Poison)layer.Remaining=Math.Max(0,layer.Remaining-step);
    poisonTick+=step;remaining-=step;
    if(poisonTick>=1-.000001){poisonTick=0;double old=Hp;Damage(Poison.Sum(l=>l.Power),false);if(old>Hp)DamageFeedback?.Invoke(old-Hp,false);if(!Alive)return;}
    Poison.RemoveAll(l=>l.Remaining<=.000001);
   }
   double burn=0;foreach(var layer in Burn){burn+=layer.Power*Math.Min(delta,layer.Remaining);layer.Remaining=Math.Max(0,layer.Remaining-delta);}
   Burn.RemoveAll(l=>l.Remaining<=.000001);
   double beforeBurn=Hp;Damage(burn,false);burnFeedback+=beforeBurn-Hp;burnFeedbackTime+=delta;
   if(burnFeedbackTime>=1||Burn.Count==0||!Alive){
    if(burnFeedback>0)DamageFeedback?.Invoke(burnFeedback,false);
    burnFeedback=0;burnFeedbackTime=0;
   }
   if(!Alive)return;
   Ice=Math.Max(0,Ice-delta);Stun=Math.Max(0,Stun-delta);
   if(stopped)return;Progress+=Speed*(Ice>0?.4:1)/path.Length*delta;
   if(Progress>=path.Goal){Progress=path.Goal;Reached=true;}
  }
 }
}
