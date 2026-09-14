using System;
using MergeTo10.Core;
namespace MergeTo10.Editor
{
 public static class CampaignVerifier {
  static void Check(bool value,string message){if(!value)throw new Exception("Campaign: "+message);}
  public static void Verify(){
   ImprintVerifier.Verify();
   MetaProgressVerifier.Verify();
   SnapshotVerifier.Verify();
   CrystalProgressVerifier.Verify();
   var data=CampaignData.Load();Check(data.waves.Length==32,"12 chapter +20 continuation");
   Check(data.waves[0].tutorial_placeholder,"scripted tutorial");
   Check(data.waves[10].spawn_sequence[0].overrides.hp==120&&data.waves[11].spawn_sequence[0].overrides.hp==300,"boss hp");
   var flow=new CampaignFlow(data);flow.Start(0,new Random(1));flow.Tick(10,false,true);
   Check(flow.State.Scripted&&!flow.State.AwaitingReward,"tutorial cannot auto clear");flow.CompleteTutorial();
   Check(flow.State.AwaitingReward&&flow.State.Cleared==1,"tutorial handoff");flow.Continue(new Random(1));
   Check(flow.State.Index==1&&flow.State.Total==5,"first chapter wave");
   string before=flow.Export();flow.Tick(10,true,true);Check(flow.Export()==before,"freeze preserves spawn state");
   int emitted=0;flow.Spawned+=spawn=>emitted++;
   flow.Tick(.016,false,true);Check(emitted==1&&!flow.State.AwaitingReward,"spawn excludes stale clear");
   for(int i=0;i<1000&&!flow.State.AwaitingReward;i++)flow.Tick(.016,false,true);
   Check(emitted==5&&flow.State.AwaitingReward,"wave spawn and clear");
   var saved=flow.Export();var restored=new CampaignFlow(data);restored.Restore(saved);
   Check(restored.State.Index==1&&restored.State.AwaitingReward,"awaiting transition restore");
   for(int index=10;index<=11;index++){
    flow.Start(index,new Random(1));int count=0;flow.Spawned+=Count;void Count(CampaignSpawn spawn){count++;}
    flow.Tick(.01,false,false);Check(count==1,"boss first");flow.Tick(1,false,false);Check(count==1,"boss delay retained");
    flow.Tick(.11,false,false);Check(count==2,"boss escort delay");flow.Spawned-=Count;
   }
   var energy=new SkillEnergy();int requests=0;energy.ChoiceRequested+=()=>requests++;
   energy.Add(100);Check(!energy.ChoiceReady&&requests==0,"wait for motes");energy.FinishFx();
   Check(energy.ChoiceReady&&requests==1,"motes enable choice");Check(energy.Choose("ascension_hammer"),"valid pending");
   energy.Add(100);energy.FinishFx();Check(!energy.ChoiceReady&&requests==1,"single pending slot");
   Check(energy.Consume().pending=="ascension_hammer"&&requests==2,"consume releases full energy choice");
   var full=new CampaignFlow(data);full.Start(0,new Random(91));full.CompleteTutorial();
   int cleared=0;full.Cleared+=_=>cleared++;
   while(!full.State.Completed){
    full.Continue(new Random(91+full.State.Index));int frames=0;
    while(full.State.Running&&frames++<10000)full.Tick(.016,false,true);
    Check(frames<10000,"campaign wave terminates "+full.State.Index);
   }
   Check(cleared==31&&full.State.Cleared==32,"entire chapter and continuation terminate");
  }
 }
}
