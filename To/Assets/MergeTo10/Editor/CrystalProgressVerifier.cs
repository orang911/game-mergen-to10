using System;
using MergeTo10.Core;
using UnityEngine;
namespace MergeTo10.Editor
{
 public static class CrystalProgressVerifier {
  static void Check(bool value,string label){if(!value)throw new Exception("Crystal: "+label);}
  public static void Verify(){
   var rules=CardRules.Load();Check(rules.cards.Length==12&&rules.baseAttack.Length==9,"active source catalog");
   foreach(var card in rules.cards)Check(Resources.Load<Texture2D>("Campaign/"+card.id)!=null,"original card icon "+card.id);
   var crystal=new CrystalProgress(rules);Check(crystal.Damage==1,"level one rounded damage");
   crystal.NotifyMerge(3);Check(crystal.State.Level==1,"merge upgrades disabled by default");
   string before=crystal.Export();Check(!crystal.Tick(10,true,true)&&crystal.Export()==before,"frozen timer");
   Check(!crystal.Tick(.89,true,false)&&crystal.Tick(.02,true,false),"first attack timer");
   Check(crystal.Apply("fire_conduit",5)&&crystal.Apply("fire_conduit",1)&&crystal.State.Elements[0]==5,"element never downgraded");
   crystal.Apply("poison_tank",2);var monster=new BattleMonster(100);
   crystal.ApplyInstalled(monster,10);Check(Math.Abs(monster.Burn[0].Power-2.2)<1e-8&&Math.Abs(monster.Poison[0].Power-1.3)<1e-8,"card-specific status damage");
   for(int i=0;i<10;i++)crystal.ApplyInstalled(monster,10);
   Check(monster.Burn.Count==4&&monster.Poison.Count==4,"global stack limit");
   crystal.Apply("star_boiler",5);Check(Math.Abs(crystal.State.DamageMultiplier-1.26)<1e-8,"additive damage");
   for(int i=0;i<100;i++)crystal.Apply("rapid_clockwork",5);
   Check(crystal.Interval==.24,"minimum attack interval");
   for(int i=0;i<6;i++)crystal.Apply("piercing_cannon",i==0?5:1);
   Check(crystal.State.PierceTargets==3&&crystal.State.PierceRatio==.55,"pierce capped and ratio retained");
   crystal.Apply("twin_lens",5);Check(crystal.State.ExtraTargets==2,"source extra-target state retained");
   var restored=new CrystalProgress(rules);restored.Restore(crystal.Export());
   // Source restore clamps very small speed multipliers to .1.
   Check(restored.State.SpeedMultiplier==.1&&restored.State.Elements[0]==5,"source restore clamps");
  }
 }
}
