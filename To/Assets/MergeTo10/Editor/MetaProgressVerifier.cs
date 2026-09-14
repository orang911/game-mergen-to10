using System;
using MergeTo10.Core;
namespace MergeTo10.Editor
{
 public static class MetaProgressVerifier {
  static void Check(bool value,string label){if(!value)throw new Exception("Meta: "+label);}
  public static void Verify(){
   var loss=RunSettlement.Calculate(false,0,0,0,0,1,0,1,false);
   Check(loss.BaseCoins==10&&loss.Coins==10&&loss.Crystals==1,"minimum settlement reward");
   var win=RunSettlement.Calculate(true,45,3,1,2,4,10,30,true);
   Check(win.BaseCoins==128&&win.Coins==256&&win.Crystals==18,"win settlement source formula");
   var meta=new MetaProgress();Check(meta.SyncDay("2026-09-11"),"day accepted");
   Check(meta.ClaimTask(3)&&!meta.ClaimTask(3)&&meta.State.Crystals==20,"login once");
   Check(!meta.ClaimActivity(),"unearned chest rejected");
   for(int i=0;i<30;i++){meta.RecordMerge();meta.RecordKill();}
   meta.RecordSettlement(100);Check(meta.State.Piggy==20,"piggy 20 percent");
   Check(meta.ClaimTask(0)&&meta.ClaimTask(1)&&meta.ClaimTask(2),"tasks earned");
   Check(meta.ActivityPoints==100&&meta.ClaimActivity()&&!meta.ClaimActivity(),"activity once");
   Check(meta.State.Coins==180&&meta.State.Crystals==30,"task totals");
   Check(meta.ClaimSign()&&!meta.ClaimSign()&&meta.State.Crystals==50,"signin once");
   string before=meta.Export();Check(!meta.SyncDay("2026-09-10")&&meta.Export()==before,"clock rollback preserves state");
   Check(meta.SyncDay("2026-09-12")&&meta.SignPreview==2&&meta.ClaimSign(),"consecutive day");
   Check(meta.State.Coins==210&&meta.ActivityPoints==0,"daily reset without wallet reset");
   meta.SyncDay("2026-09-14");Check(meta.SignPreview==1,"signin gap");
   var loaded=new MetaProgress();loaded.Restore(meta.Export());Check(loaded.Export()==meta.Export(),"snapshot roundtrip");
   Check(loaded.Purchase("coins_10000")=="insufficient","insufficient wallet");
   string unchanged=loaded.Export();Check(loaded.Purchase("benefits_bundle")=="payment_failed"&&loaded.Export()==unchanged,"no adapter no charge");
   loaded.LocalPurchase=id=>true;Check(loaded.Purchase("double_coin")=="ok"&&loaded.State.DoubleCoin&&loaded.State.RemoveAds,"legacy bundle alias");
   Check(loaded.Purchase("remove_ads")=="owned","bundle duplicate blocked");
   loaded.Grant(new MetaReward(0,1000));
   for(int i=0;i<3;i++)Check(loaded.Purchase("coins_10000")=="ok","coin daily purchase");
   unchanged=loaded.Export();Check(loaded.Purchase("coins_10000")=="limit"&&loaded.Export()==unchanged,"daily limit atomic");
   var fragments=new MetaProgress();fragments.GrantFragments("ascension_hammer",55);
   Check(fragments.State.Levels[0]==5&&fragments.State.Fragments[0]==0&&fragments.State.Coins==100,"max level overflow");
   fragments.GrantFragments("ascension_hammer",5);Check(fragments.State.Coins==200,"max level additional fragments");
   fragments.Grant(new MetaReward(0,750));
   for(int i=0;i<3;i++)Check(fragments.Purchase("frag_imprint_unity_dial")=="ok","imprint purchase");
   Check(fragments.State.Levels[1]==1&&fragments.State.Fragments[1]==5&&fragments.Purchase("frag_imprint_unity_dial")=="limit","imprint accumulation");
   Check(fragments.Purchase("frag_unknown")=="missing","unknown product");
  }
 }
}
