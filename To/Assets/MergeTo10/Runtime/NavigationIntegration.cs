using System.Collections;
using UnityEngine;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(MainHubView),typeof(BattleHudView),typeof(BattlePauseView))]
 [RequireComponent(typeof(NavigationSettingsView))]
 [RequireComponent(typeof(ExitConfirmationView))]
 [RequireComponent(typeof(DailyProgressView))]
 [RequireComponent(typeof(CrystalUpgradeView))]
 [RequireComponent(typeof(CommerceView))]
 [RequireComponent(typeof(CampaignPersistence))]
 public sealed class NavigationIntegration:MonoBehaviour {
  M2BattleDemo combat;MainHubView hub;M2BattleDemo.SessionSnapshot parked;
  bool previousDebug;public bool Ready {get;private set;}
  public bool InHub=>hub&&hub.Visible;
  void Awake(){
   combat=GetComponent<M2BattleDemo>();previousDebug=combat.ShowDebugPanel;
   combat.NavigationSuspended=true;combat.ShowDebugPanel=false;
   if(!GetComponent<LoadingView>())gameObject.AddComponent<LoadingView>();
  }
  IEnumerator Start(){
   combat=GetComponent<M2BattleDemo>();hub=GetComponent<MainHubView>();
   if(!GetComponent<CrystalUpgradeView>())gameObject.AddComponent<CrystalUpgradeView>();
   if(!GetComponent<CommerceView>())gameObject.AddComponent<CommerceView>();
   while(!combat.Ready||GetComponent<M1BoardDemo>().Busy)yield return null;
   var disk=GetComponent<CampaignPersistence>();
   if(disk){while(!disk.Ready)yield return null;}
   var loading=GetComponent<LoadingView>();
   while(loading&&!loading.CanEnter)yield return null;
   combat.ShowDebugPanel=false;
   hub.EntryAvailable=name=>name=="DoubleCoinButton"||name=="RemoveAdsButton"||name=="PiggyButton"||name=="CrystalUpgradeButton"||name=="StageButton"||name=="SettingsButton"||name=="TasksButton"||name=="SigninButton"||name=="MissionTasksButton"||name=="LockedShopButton";
   hub.EntryRequested=name=>{if(name=="DoubleCoinButton"||name=="RemoveAdsButton")GetComponent<CommerceView>().ShowBenefits();else if(name=="PiggyButton")GetComponent<CommerceView>().ShowPiggy();else if(name=="StageButton")EnterBattle();else if(name=="SettingsButton")GetComponent<NavigationSettingsView>().Show(null);else if(name=="TasksButton"||name=="SigninButton"||name=="MissionTasksButton")GetComponent<DailyProgressView>().Show();else if(name=="LockedShopButton")hub.ShowLockedNotice();};
   var existingEntry=hub.EntryRequested;
   hub.EntryRequested=name=>{if(name=="CrystalUpgradeButton")GetComponent<CrystalUpgradeView>().Show();else existingEntry(name);};
   GetComponent<BattlePauseView>().SettingsRequested=()=>{
    GetComponent<BattlePauseView>().Resume();combat.SetPaused(true);
    GetComponent<NavigationSettingsView>().Show(()=>{combat.SetPaused(false);GetComponent<BattlePauseView>().Show();},true);
   };
   GetComponent<BattlePauseView>().ExitRequested=()=>{
    GetComponent<BattlePauseView>().Resume();combat.SetPaused(true);
    GetComponent<ExitConfirmationView>().Show(()=>{
     combat.CheckpointForHubExit();combat.SetPaused(false);OpenHub();
    },()=>{combat.SetPaused(false);GetComponent<BattlePauseView>().Show();});
   };
   Ready=true;OpenHub();loading.Finish();
  }
  public bool OpenHub(){
   if(!Ready||combat.Frozen||GetComponent<M1BoardDemo>().Busy||InHub)return false;
   parked=combat.CaptureSession();
   SetModals(false);
   combat.NavigationSuspended=true;combat.SetPaused(true);combat.ShowDebugPanel=false;
   GetComponent<CampaignPersistence>()?.SaveStable();hub.Show(combat);return true;
  }
  public void EnterBattle(){
   if(!Ready||!InHub)return;
   parked.Meta=combat.Meta.Export();hub.Hide();combat.NavigationSuspended=false;
   SetModals(true);combat.RestoreSession(parked);
   combat.HitAudio.Muted=!combat.Meta.State.Sound;GetComponent<M1BoardDemo>().SoundEnabled=combat.Meta.State.Sound;
   combat.ShowDebugPanel=false;
  }
  void SetModals(bool value){
   foreach(var view in new Behaviour[]{GetComponent<ChapterNodeView>(),GetComponent<CrystalChoiceView>(),GetComponent<ImprintChoiceView>(),GetComponent<BattlePauseView>()})
    if(view)view.enabled=value;
  }
  void OnDestroy(){if(combat){combat.NavigationSuspended=false;combat.ShowDebugPanel=previousDebug;combat.SetPaused(false);}}
 }
}
