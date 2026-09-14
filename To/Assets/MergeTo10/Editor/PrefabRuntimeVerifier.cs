using System;
using System.IO;
using System.Linq;
using System.Reflection;
using MergeTo10.Runtime;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering;
using Object=UnityEngine.Object;

namespace MergeTo10.Editor {
 public static class PrefabRuntimeVerifier {
  const string Pending="MergeTo10.PrefabVerify";
  static string output,error;static int phase,checks;static double start,next;static M2BattleDemo combat;
  static void Check(bool value,string label){checks++;if(!value)throw new Exception(label);}
  static void Call(object owner,string method,params object[] args)=>owner.GetType().GetMethod(method,BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic).Invoke(owner,args);
  static void Log(string text,string stack,LogType kind){if((kind==LogType.Exception||kind==LogType.Error)&&!stack.Contains("UnityEditor.Search.SearchDatabase"))error=text+"\n"+stack;}
  public static void Validate(){
   output=Environment.GetEnvironmentVariable("PREFAB_OUTPUT");Directory.CreateDirectory(output);PlayerSettings.companyName="MergeTo10PrefabValidation";
   foreach(var guid in AssetDatabase.FindAssets("t:Prefab",new[]{PrefabAuthoringTools.Root})){
    var path=AssetDatabase.GUIDToAssetPath(guid);var asset=AssetDatabase.LoadAssetAtPath<GameObject>(path);
    Check(asset,"Cannot load "+path);
    foreach(var t in asset.GetComponentsInChildren<Transform>(true))Check(GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(t.gameObject)==0,"Missing script "+path+"/"+t.name);
    foreach(var r in asset.GetComponentsInChildren<SpriteRenderer>(true))Check(r.sprite&&AssetDatabase.Contains(r.sprite),"Transient sprite "+path+"/"+r.name);
   }
   EditorSceneManager.OpenScene("Assets/MergeTo10/Scenes/NavigationIntegration.unity");
   var root=Object.FindFirstObjectByType<M2BattleDemo>();Check(PrefabUtility.IsPartOfPrefabInstance(root),"Main scene must use GameCore prefab");
   var persistence=root.GetComponent<CampaignPersistence>();var serialized=new SerializedObject(persistence);serialized.FindProperty("PathOverride").stringValue=Path.Combine(output,"fixture_profile.json");serialized.ApplyModifiedPropertiesWithoutUndo();PrefabUtility.RecordPrefabInstancePropertyModifications(persistence);
   SessionState.SetInt(Pending+"Checks",checks);SessionState.SetString(Pending+"Output",output);SessionState.SetBool(Pending,true);EditorApplication.isPlaying=true;
  }
  [InitializeOnLoadMethod] static void Resume(){if(!SessionState.GetBool(Pending,false))return;output=SessionState.GetString(Pending+"Output","");checks=SessionState.GetInt(Pending+"Checks",0);start=EditorApplication.timeSinceStartup;next=0;phase=0;error=null;Application.logMessageReceived+=Log;EditorApplication.update+=Tick;}
  static GameObject Ui(string name){
   var go=GameObject.Find(name);Check(go,"Missing visible "+name);Check(go.GetComponent<UiPrefabInstance>(),"Not prefab-backed "+name);
   Check(go.GetComponentsInChildren<Canvas>(false).Length==1,"Duplicated canvas "+name);
   foreach(var node in go.GetComponentsInChildren<PrefabUiNode>())Check(node.Baked,"Unexpected regenerated node "+name+"/"+node.name+" key="+node.BindingKey);
   return go;
  }
  static void Snap(string name){
   var camera=Object.FindFirstObjectByType<Camera>();float oldSize=camera.orthographicSize,oldAspect=camera.aspect;camera.orthographicSize=8.36f;camera.aspect=941f/1672;
   var canvases=Object.FindObjectsByType<Canvas>(FindObjectsSortMode.None).Where(c=>c.isRootCanvas&&c.isActiveAndEnabled).ToArray();
   var modes=canvases.Select(c=>c.renderMode).ToArray();var cameras=canvases.Select(c=>c.worldCamera).ToArray();
   foreach(var canvas in canvases){canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=camera;canvas.planeDistance=1;}
   Canvas.ForceUpdateCanvases();var rt=RenderTexture.GetTemporary(470,836,24);var old=RenderTexture.active;var tex=new Texture2D(470,836,TextureFormat.RGB24,false);
   try{RenderPipeline.SubmitRenderRequest(camera,new RenderPipeline.StandardRequest{destination=rt});RenderTexture.active=rt;tex.ReadPixels(new Rect(0,0,470,836),0,0);tex.Apply();File.WriteAllBytes(Path.Combine(output,name+".png"),tex.EncodeToPNG());}
   finally{RenderTexture.active=old;RenderTexture.ReleaseTemporary(rt);Object.DestroyImmediate(tex);camera.orthographicSize=oldSize;camera.aspect=oldAspect;for(int i=0;i<canvases.Length;i++){canvases[i].renderMode=modes[i];canvases[i].worldCamera=cameras[i];}}
  }
  static void Tick(){try{
   if(error!=null)throw new Exception(error);if(EditorApplication.timeSinceStartup-start>180)throw new Exception("Prefab validation timeout phase "+phase);
   if(phase==15&&!EditorApplication.isPlayingOrWillChangePlaymode){Finish(null);return;}if(!EditorApplication.isPlaying||EditorApplication.timeSinceStartup<next)return;
   if(!combat){combat=Object.FindFirstObjectByType<M2BattleDemo>();if(!combat)return;}
   var owner=combat.gameObject;var navigation=owner.GetComponent<NavigationIntegration>();var commerce=owner.GetComponent<CommerceView>();
   if(phase==0){
    Check(owner.GetComponent<CampaignPersistence>().PathOverride==Path.Combine(output,"fixture_profile.json"),"Test profile override survives prefab reload");var loading=owner.GetComponent<LoadingView>();if(!loading||!loading.Visible)return;Ui("LoadingCanvas");
    foreach(string method in new[]{"ShowClearConfirmation","ShowError","ShowRecovery"}){
     Call(loading,method);var dialog=GameObject.Find("LoadingDialog");Check(dialog&&dialog.GetComponent<UiPrefabInstance>(),method+" prefab instance");
     foreach(var node in dialog.GetComponentsInChildren<PrefabUiNode>())Check(node.Baked,method+" reused "+node.name);
     if(method=="ShowClearConfirmation")GameObject.Find("ClearCancelButton").GetComponent<Button>().onClick.Invoke();else Call(loading,"CloseDialog");
    }
    phase++;return;
   }
   if(!navigation.Ready||owner.GetComponent<LoadingView>().Visible)return;
   switch(phase){
    case 1:
     Ui("MainHubCanvas");Snap("01_hub");
     Check(owner.GetComponent<M1BoardDemo>().Stage.GetComponentsInChildren<CellView>().Length==25,"Exactly 25 live cells; actual="+owner.GetComponent<M1BoardDemo>().Stage.GetComponentsInChildren<CellView>().Length);
     Check(owner.GetComponent<M1BoardDemo>().Stage.GetComponentsInChildren<Transform>().All(t=>t.name!="EditorPreview"),"Editor previews removed");
     var library=owner.GetComponentInChildren<PrefabSceneLibrary>();Check(library.Interfaces.Length>=16,"All interface templates in scene");
     var template=library.Interfaces.First(e=>e.Id=="MainHubCanvas").Template;var coin=template.GetComponentsInChildren<Text>(true).First(t=>t.name=="CoinValue");
     coin.rectTransform.anchoredPosition+=new Vector2(9,0);coin.fontSize+=3;var custom=new GameObject("AuthoringProbe",typeof(RectTransform));custom.transform.SetParent(coin.transform,false);
     owner.GetComponent<MainHubView>().Show(combat);var live=GameObject.Find("CoinValue").GetComponent<Text>();
     Check(live.rectTransform.anchoredPosition==coin.rectTransform.anchoredPosition,"Authored position survives binding");Check(live.fontSize==coin.fontSize,"Authored font size survives binding");Check(live.transform.Find("AuthoringProbe"),"Added animation child survives binding");
     coin.rectTransform.anchoredPosition-=new Vector2(9,0);coin.fontSize-=3;Object.Destroy(custom);owner.GetComponent<MainHubView>().Show(combat);
     owner.GetComponent<NavigationSettingsView>().Show(null);break;
    case 2:Ui("NavigationSettingsCanvas");owner.GetComponent<NavigationSettingsView>().SetSetting("sound",false);owner.GetComponent<NavigationSettingsView>().Hide(false);owner.GetComponent<DailyProgressView>().Show();break;
    case 3:Ui("DailyProgressCanvas");Snap("02_daily");owner.GetComponent<DailyProgressView>().Hide();owner.GetComponent<CrystalUpgradeView>().Show();break;
    case 4:Ui("CrystalUpgradeCanvas");owner.GetComponent<CrystalUpgradeView>().Hide();commerce.ShowBenefits();break;
    case 5:Ui("CommerceCanvas");Snap("03_benefits");commerce.RequestPurchase("benefits_bundle");break;
    case 6:Ui("CommerceCanvas");commerce.CancelPurchase();commerce.ShowPiggy();break;
    case 7:Ui("CommerceCanvas");combat.Meta.State.Piggy=100;commerce.RequestPurchase("piggy_bank");break;
    case 8:Ui("CommerceCanvas");commerce.CancelPurchase();commerce.Hide();navigation.EnterBattle();break;
    case 9:if(owner.GetComponent<M1BoardDemo>().Busy)return;Ui("BattleHudCanvas");Ui("EnergyHudCanvas");Snap("04_battle");owner.GetComponent<BattlePauseView>().Show();break;
    case 10:Ui("BattlePauseCanvas");owner.GetComponent<BattlePauseView>().Resume();owner.GetComponent<ExitConfirmationView>().Show(()=>{},()=>{});break;
    case 11:Ui("ExitConfirmationCanvas");owner.GetComponent<ExitConfirmationView>().Cancel();Call(combat,"SetGate",M2BattleDemo.ChapterGate.NodeComplete);break;
    case 12:Ui("ChapterNodeCanvas");Call(combat,"SetGate",M2BattleDemo.ChapterGate.CrystalReward);break;
    case 13:Ui("CrystalChoiceCanvas");Snap("05_crystal_choice");Call(combat,"SetGate",M2BattleDemo.ChapterGate.None);Call(owner.GetComponent<ImprintChoiceView>(),"Show");break;
    case 14:Ui("ImprintChoiceCanvas");Snap("06_imprint");Call(owner.GetComponent<ImprintChoiceView>(),"Hide");phase=15;EditorApplication.isPlaying=false;return;
   }
   phase++;next=EditorApplication.timeSinceStartup+.8;
  }catch(Exception ex){Finish(ex);}}
  static void Finish(Exception failure){SessionState.SetBool(Pending,false);EditorApplication.update-=Tick;Application.logMessageReceived-=Log;File.WriteAllText(Path.Combine(output,"prefab-runtime-result.txt"),failure==null?"PASS "+checks+" checks: serialized assets, actual prefab scene startup, no regenerated UI hierarchy, 25 cells, editor-preview cleanup, authored position/font/additional child retained, all implemented interfaces and screenshots, clean Play-mode teardown. Player/device pending.":"FAIL phase "+phase+" "+failure);EditorApplication.Exit(failure==null?0:1);}
 }
}
