using System;
using System.IO;
using System.Collections.Generic;
using MergeTo10.Core;
using MergeTo10.Runtime;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
namespace MergeTo10.Editor {
 public static class LoadingPersistenceVerifier {
  const string Pending="LoadingPersistenceValidation";
  static string output,error,path,good;static int phase,checks,wait;static double started,until,seconds;static float progress;
  static M2BattleDemo combat;static CampaignPersistence disk;static NavigationIntegration nav;static LoadingView loading;
  public static void Validate(){
   output=Environment.GetEnvironmentVariable("M2_EDITOR_OUTPUT");if(string.IsNullOrEmpty(output))throw new Exception("Output required");
   Directory.CreateDirectory(output);SessionState.SetString(Pending+"Output",output);
   EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
   SessionState.SetBool(Pending,true);EditorApplication.isPlaying=true;
  }
  [InitializeOnLoadMethod]static void Resume(){
   if(!SessionState.GetBool(Pending,false))return;
   output=SessionState.GetString(Pending+"Output","");path=Path.Combine(output,"player.json");started=EditorApplication.timeSinceStartup;
   EditorApplication.update+=Tick;Application.logMessageReceived+=Log;
  }
  static void Log(string text,string stack,LogType type){if((type==LogType.Error||type==LogType.Exception)&&stack.Contains("MergeTo10"))error=text+"\n"+stack;}
  static void Check(bool value,string message){checks++;if(!value)throw new Exception(message);File.AppendAllText(Path.Combine(output,"checks.txt"),"PASS "+message+"\n");}
  static void Spawn(){
   var go=new GameObject("LoadingPersistenceTest");go.AddComponent<M1BoardDemo>();combat=go.AddComponent<M2BattleDemo>();combat.CampaignMode=true;
   go.AddComponent<ChapterNodeView>();go.AddComponent<CrystalChoiceView>();go.AddComponent<EnergyHudView>();go.AddComponent<ImprintChoiceView>();
   disk=go.AddComponent<CampaignPersistence>();disk.PathOverride=path;nav=go.AddComponent<NavigationIntegration>();loading=go.GetComponent<LoadingView>();
  }
  static void Click(string name){
   var go=GameObject.Find(name);Check(go,"button exists: "+name);var b=go.GetComponent<Button>();Check(b&&b.IsInteractable(),"button enabled: "+name);
   Canvas.ForceUpdateCanvases();var r=b.GetComponent<RectTransform>();var p=RectTransformUtility.WorldToScreenPoint(null,r.TransformPoint(r.rect.center));
   var data=new PointerEventData(EventSystem.current){position=p,button=PointerEventData.InputButton.Left};var hits=new List<RaycastResult>();EventSystem.current.RaycastAll(data,hits);
   Check(hits.Count>0&&ExecuteEvents.GetEventHandler<IPointerClickHandler>(hits[0].gameObject)==go,"top raycast: "+name);
   ExecuteEvents.Execute(go,data,ExecuteEvents.pointerClickHandler);
  }
  static void Remove(){UnityEngine.Object.Destroy(combat.gameObject);combat=null;disk=null;nav=null;loading=null;wait=4;}
  static void Core(string json){
   var file=Path.Combine(output,"core.json");var store=new ProfileStore(file);
   Check(store.Load(out _)==null,"missing profile is new");store.Save(json);Check(store.Load(out _)==json,"envelope roundtrip");
   store.Save(json);File.WriteAllText(file,"broken");Check(store.Load(out bool recovered,CampaignPersistence.ValidatePayload)==json&&recovered,"corrupt primary falls back to validated backup");
   store.Save(json);Check(Directory.GetFiles(output,"core.json.corrupt_*").Length==1,"corrupt primary archived before healing");
   var invalid=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(json);invalid.Checkpoint=JsonUtility.FromJson<M2BattleDemo.CampaignSnapshot>(JsonUtility.ToJson(invalid.Current));invalid.Checkpoint.Board=null;
   store.Save(JsonUtility.ToJson(invalid));Check(store.Load(out recovered,CampaignPersistence.ValidatePayload)==json&&recovered,"semantic corruption in checkpoint falls back");
   store.Save(json);Check(new ProfileStore(file+".backup").Load(out _)==json,"semantic invalid primary does not poison backup");
   string incomplete=Path.Combine(output,"interrupted.json");new ProfileStore(incomplete+".pending").Save(json);
   Check(new ProfileStore(incomplete).Load(out recovered,CampaignPersistence.ValidatePayload)==json&&recovered,"completed pending write recovered after interrupted first save");
   File.WriteAllText(incomplete+".pending","broken");bool rejected=false;try{new ProfileStore(incomplete).Load(out _,CampaignPersistence.ValidatePayload);}catch(InvalidDataException){rejected=true;}Check(rejected,"incomplete pending file never becomes fresh profile");
   invalid=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(json);invalid.Current.Board=null;
   string before=JsonUtility.ToJson(combat.CaptureSession());rejected=false;try{combat.RestoreSession(invalid);}catch(ArgumentException){rejected=true;}
   Check(rejected&&before==JsonUtility.ToJson(combat.CaptureSession()),"invalid restore leaves live session untouched");
   var original=combat.CaptureSession();var choice=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(JsonUtility.ToJson(original));
   choice.Gate=M2BattleDemo.ChapterGate.CrystalReward;choice.Current.BossRewardCommitted=false;choice.CrystalOffers=new[]{"twin_lens","fire_conduit","rapid_clockwork"};
   combat.RestoreSession(choice);
   var choiceStore=new ProfileStore(Path.Combine(output,"crystal_choices.json"));choiceStore.Save(JsonUtility.ToJson(combat.CaptureSession()));
   combat.RestoreSession(JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(choiceStore.Load(out _,CampaignPersistence.ValidatePayload)));
   Check(string.Join(",",combat.CrystalChoices)=="twin_lens,fire_conduit,rapid_clockwork","crystal offers and order survive disk restore");
   combat.RestoreSession(original);combat.SetPaused(true);
   combat.BeginSettlement();Check(!disk.SaveStable()&&disk.HasPendingSave,"frozen merge defers saving");combat.EndSettlement();Check(disk.SaveStable(),"deferred save commits at stable boundary");
   combat.Meta.Grant(new MetaReward(3));disk.SendMessage("OnApplicationPause",true);var pause=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(new ProfileStore(path).Load(out _));var pauseMeta=new MetaProgress();pauseMeta.Restore(pause.Meta);
   Check(pauseMeta.State.Coins==combat.Meta.State.Coins,"application pause flushes stable profile");
   combat.RestoreSession(original);combat.SetPaused(true);disk.SaveStable();
  }
  static void Tick(){
   try{
    if(EditorApplication.timeSinceStartup-started>160)throw new Exception("Watchdog phase "+phase);
    if(error!=null)throw new Exception(error);if(!EditorApplication.isPlaying)return;if(wait>0){wait--;return;}
    double now=EditorApplication.timeSinceStartup;
    switch(phase){
     case 0:Spawn();phase++;return;
     case 1:
      if(disk.Error.Length>0)throw new Exception(disk.Error+"\n"+JsonUtility.ToJson(combat.CaptureSession()));
      if(!disk.Ready)return;
      Check(loading.Visible&&!nav.Ready,"loading precedes navigation");Check(disk.IsNewProfile,"first launch identified");
      Check(combat.Meta.State.Coins==1804&&combat.Meta.State.Crystals==120,"fresh wallet matches Godot");
      Click("ClearLocalDataButton");progress=loading.Progress;seconds=combat.CombatSeconds;until=now+.4;phase++;return;
     case 2:
      if(now<until)return;Check(loading.Progress==progress&&!nav.Ready,"clear confirmation suspends loading");Check(combat.CombatSeconds==seconds,"loading does not advance combat");
      Click("ClearCancelButton");phase++;return;
     case 3:
      if(!nav.Ready||loading.Visible)return;
      Check(nav.InHub&&combat.Paused,"loaded navigation lands in paused hub");Check(File.Exists(path),"first launch persisted before entry");
      combat.Meta.Grant(new MetaReward(79,9));combat.Meta.State.Sound=false;combat.Meta.ClaimSign();Check(disk.SaveStable(),"wallet/settings/sign-in saved");
      good=File.ReadAllText(path);string json=new ProfileStore(path).Load(out _);Core(json);
      var saved=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(json);var meta=new MetaProgress();meta.Restore(saved.Meta);
      Check(meta.State.Coins==1883&&meta.State.Crystals==149&&!meta.State.Sound&&meta.State.SignDay==meta.State.Day,"all profile fields persisted together");
      Remove();phase++;return;
     case 4:Spawn();phase++;return;
     case 5:
      if(!nav.Ready||loading.Visible)return;
      Check(!disk.IsNewProfile&&!disk.Recovered&&nav.InHub,"returning launch restores into hub");
      Check(combat.Meta.State.Coins==1883&&!combat.Meta.State.Sound&&!combat.Meta.ClaimSign(),"restart retains settings/wallet and prevents duplicate sign-in");
      nav.EnterBattle();Check(!nav.InHub&&!combat.Paused,"continue enters restored battle");combat.SetPaused(true);Check(nav.OpenHub(),"restored battle can return to hub");
      Check(disk.SaveStable(),"resumed state saved");good=File.ReadAllText(path);File.WriteAllText(path+".backup",good);Remove();phase++;return;
     case 6:File.WriteAllText(path,"corrupt");Spawn();phase++;return;
     case 7:
      if(!disk.Ready||!GameObject.Find("RecoveryContinueButton"))return;
      Check(disk.Recovered&&!nav.Ready,"recovery requires visible acknowledgement");Click("RecoveryContinueButton");phase++;return;
     case 8:
      if(!nav.Ready||loading.Visible)return;
      Check(combat.Meta.State.Coins==1883,"backup recovery preserves wallet");Check(Directory.GetFiles(output,"player.json.corrupt_*").Length>0,"runtime keeps damaged original evidence");Remove();phase++;return;
     case 9:File.WriteAllText(path,"corrupt primary");File.WriteAllText(path+".backup","corrupt backup");Spawn();phase++;return;
     case 10:
      if(!GameObject.Find("LoadRetryButton"))return;
      Check(!disk.Ready&&!nav.Ready&&combat.Paused,"both corrupt stops navigation and combat");Check(File.ReadAllText(path)=="corrupt primary","failed load never overwrites damaged files");
      Click("LoadRetryButton");until=now+.15;phase++;return;
     case 11:
      if(now<until||!GameObject.Find("LoadRetryButton"))return;
      File.WriteAllText(path,good);Click("LoadRetryButton");phase++;return;
     case 12:
      if(!nav.Ready||loading.Visible)return;
      Check(disk.Ready&&disk.Error==""&&combat.Meta.State.Coins==1883,"retry repairs without restarting game");
      File.Move(path,path+".blocked_original");Directory.CreateDirectory(path);combat.Meta.Grant(new MetaReward(1));
      Check(!disk.SaveStable()&&disk.Error.Length>0,"write failure exposed without discarding memory");phase++;return;
     case 13:
      if(!GameObject.Find("SaveRetryButton"))return;
      // The only deleted directory is the empty collision created in the previous test step.
      Directory.Delete(path,false);File.Move(path+".blocked_original",path);Click("SaveRetryButton");
      Check(disk.Error==""&&combat.Meta.State.Coins==1884,"save retry succeeds and retains pending wallet");Remove();phase++;return;
     case 14:Spawn();phase++;return;
     case 15:
      if(!disk.Ready)return;Click("ClearLocalDataButton");phase=151;return;
     case 151:
      Click("ClearConfirmButton");
      Check(Directory.Exists(disk.LastResetArchive),"confirmed clear archives previous profile");
      Check(combat.Meta.State.Coins==1804&&combat.Meta.State.Crystals==120&&combat.Meta.State.Sound&&combat.Meta.State.SignDay=="","confirmed clear resets wallet/settings/sign-in");
      Check(loading.Progress==0&&!nav.Ready,"confirmed clear restarts full loading presentation");phase=16;return;
     case 16:
      if(!nav.Ready||loading.Visible)return;
      Check(nav.InHub&&disk.SaveStable(),"cleared profile boots and saves normally");
      var final=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(new ProfileStore(path).Load(out _));var finalMeta=new MetaProgress();finalMeta.Restore(final.Meta);
      Check(finalMeta.State.Coins==1804&&!finalMeta.State.DoubleCoin,"old profile not resurrected after clear");Remove();phase++;return;
     case 17:Finish(null);return;
    }
   }catch(Exception ex){Finish(ex.ToString());}
  }
  static void Finish(string failure){
   SessionState.SetBool(Pending,false);EditorApplication.update-=Tick;Application.logMessageReceived-=Log;
   File.WriteAllText(Path.Combine(output,"loading-persistence-result.txt"),failure==null?"PASS checks="+checks+"; first/returning boot, real raycast confirmation/cancel/retry, backup and pending recovery, nested validation, no duplicate sign-in, save failure retry, archived reset, navigation. Editor only; tutorial and device acceptance pending.":"FAIL phase="+phase+" "+failure);
   EditorApplication.Exit(failure==null?0:1);
  }
 }
}
