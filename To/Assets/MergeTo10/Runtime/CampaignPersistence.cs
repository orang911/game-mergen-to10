using System;
using System.IO;
using System.Collections;
using UnityEngine;
using MergeTo10.Core;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class CampaignPersistence:MonoBehaviour {
  public string PathOverride="";
  public string Error {get;private set;}="";
  public bool Ready {get;private set;}
  public bool IsNewProfile {get;private set;}
  public bool Recovered {get;private set;}
  public bool Loading {get;private set;}=true;
  public bool HasPendingSave=>pendingSave;
  public string SavePath=>store?.FilePath??"";
  public string LastResetArchive {get;private set;}="";
  M2BattleDemo combat;M1BoardDemo board;ProfileStore store;double nextSave,nextDay;
  string lastStable,freshSession;bool pendingSave,subscribed;
  void RequestSave(){pendingSave=true;nextSave=0;}
  IEnumerator Start(){
   combat=GetComponent<M2BattleDemo>();board=GetComponent<M1BoardDemo>();
   while(!combat.Ready||board.Busy)yield return null;
   if(!combat.CampaignMode){Loading=false;Error="当前场景不支持章节存档。";yield break;}
   freshSession=JsonUtility.ToJson(combat.CaptureSession());
   RetryLoad();
  }
  public bool RetryLoad(){
   if(Ready||freshSession==null)return false;
   Loading=true;Error="";
   try{
    store=new ProfileStore(string.IsNullOrEmpty(PathOverride)?Path.Combine(Application.persistentDataPath,"unity_campaign_v1.json"):PathOverride);
    var json=store.Load(out bool recovered,ValidatePayload);
    IsNewProfile=json==null;Recovered=recovered;
    if(json==null){var fresh=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(freshSession);if(GetComponent<NavigationIntegration>())fresh.Meta=JsonUtility.ToJson(new MetaState{Coins=1804,Crystals=120});json=JsonUtility.ToJson(fresh);}
    combat.RestoreSession(JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(json));
    lastStable=IsNewProfile||recovered?null:json;
    Ready=true;Loading=false;
    if(!subscribed){combat.PersistRequested+=RequestSave;combat.Meta.Changed+=RequestSave;subscribed=true;}
    SyncDay();pendingSave=true;
    if(GetComponent<NavigationIntegration>()){combat.NavigationSuspended=true;combat.SetPaused(true);}
    return true;
   }catch(Exception error){Loading=false;Ready=false;SetError(error);combat.NavigationSuspended=true;combat.SetPaused(true);return false;}
  }
  public static void ValidatePayload(string json)=>M2BattleDemo.ValidateSession(JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(json));
  void SyncDay(){string day=DateTime.Now.ToString("yyyy-MM-dd",System.Globalization.CultureInfo.InvariantCulture);if(combat.Meta.State.Day!=day)combat.Meta.SyncDay(day);nextDay=Time.realtimeSinceStartupAsDouble+30;}
  void LateUpdate(){
   if(!Ready)return;
   if(Time.realtimeSinceStartupAsDouble>=nextDay)SyncDay();
   if(Time.realtimeSinceStartupAsDouble<nextSave)return;
   SaveStable();nextSave=Time.realtimeSinceStartupAsDouble+2;
  }
  public bool SaveStable(){
   if(!Ready||!combat||!combat.CampaignMode||combat.Campaign==null||!board||board.Busy||combat.Frozen||combat.Gate==M2BattleDemo.ChapterGate.Reviving){if(Ready)pendingSave=true;return false;}
   try{
    string json=JsonUtility.ToJson(combat.CaptureSession());
    if(json!=lastStable){ValidatePayload(json);store.Save(json);lastStable=json;}
    Error="";pendingSave=false;return true;
   }catch(Exception error){pendingSave=true;SetError(error);return false;}
  }
  void SetError(Exception error){Error=error.Message;Debug.LogWarning("Unity local data: "+error);}
  public bool ResetLocalData(){
   if(store==null||freshSession==null)return false;
   // Called only by LoadingView's explicit confirmation, before navigation is ready.
   var navigation=GetComponent<NavigationIntegration>();if(navigation&&navigation.Ready)return false;
   try{
    var fresh=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(freshSession);
    fresh.Meta=JsonUtility.ToJson(new MetaState{Coins=1804,Crystals=120});
    string json=JsonUtility.ToJson(fresh);ValidatePayload(json);
    LastResetArchive=store.Reset(json);
    Ready=false;bool loaded=RetryLoad();if(loaded)IsNewProfile=true;return loaded;
   }catch(Exception error){SetError(error);return false;}
  }
  void OnApplicationFocus(bool focused){if(!focused)SaveStable();else if(Ready)SyncDay();}
  void OnApplicationPause(bool paused){if(paused)SaveStable();else if(Ready)SyncDay();}
  void OnApplicationQuit(){SaveStable();}
  void OnDestroy(){if(combat&&subscribed){combat.PersistRequested-=RequestSave;combat.Meta.Changed-=RequestSave;}}
 }
}
