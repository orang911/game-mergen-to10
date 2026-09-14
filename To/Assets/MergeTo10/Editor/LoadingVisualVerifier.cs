using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using MergeTo10.Runtime;
namespace MergeTo10.Editor {
 public static class LoadingVisualVerifier {
  const string Pending="LoadingVisualPending";
  static string output,error;static int phase,wait;static double started;static M2BattleDemo combat;static LoadingView loading;static string file;
  public static void Validate(){
   output=Environment.GetEnvironmentVariable("M2_EDITOR_OUTPUT");Directory.CreateDirectory(output);SessionState.SetString(Pending+"Output",output);
   EditorSceneManager.OpenScene("Assets/MergeTo10/Scenes/NavigationIntegration.unity");
   var persistence=UnityEngine.Object.FindFirstObjectByType<CampaignPersistence>();persistence.PathOverride=Path.Combine(output,"visual_profile.json");PrefabUtility.RecordPrefabInstancePropertyModifications(persistence);EditorUtility.SetDirty(persistence);
   SessionState.SetBool(Pending,true);EditorApplication.isPlaying=true;
  }
  [InitializeOnLoadMethod]static void Resume(){if(!SessionState.GetBool(Pending,false))return;output=SessionState.GetString(Pending+"Output","");started=EditorApplication.timeSinceStartup;EditorApplication.update+=Tick;Application.logMessageReceived+=Log;}
  static void Log(string text,string stack,LogType type){if((type==LogType.Error||type==LogType.Exception)&&stack.Contains("MergeTo10"))error=text+"\n"+stack;}
  static void Snap(string name,int width=941,int height=1672){
   if(loading)loading.enabled=false;
   var assembly=typeof(UnityEditor.Editor).Assembly;var sizesType=assembly.GetType("UnityEditor.GameViewSizes");var singleton=typeof(ScriptableSingleton<>).MakeGenericType(sizesType);var sizes=singleton.GetProperty("instance").GetValue(null);var group=sizesType.GetMethod("GetGroup").Invoke(sizes,new object[]{0});
   var sizeType=assembly.GetType("UnityEditor.GameViewSize");var enumType=assembly.GetType("UnityEditor.GameViewSizeType");var size=Activator.CreateInstance(sizeType,System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.Public|System.Reflection.BindingFlags.NonPublic,null,new object[]{Enum.ToObject(enumType,1),width,height,"Loading QA"},null);
   group.GetType().GetMethod("AddCustomSize").Invoke(group,new[]{size});int count=(int)group.GetType().GetMethod("GetTotalCount").Invoke(group,null);
   var viewType=assembly.GetType("UnityEditor.GameView");var window=EditorWindow.GetWindow(viewType);viewType.GetProperty("selectedSizeIndex",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.Public|System.Reflection.BindingFlags.NonPublic).SetValue(window,count-1);
   viewType.GetProperty("drawGizmos",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.Public|System.Reflection.BindingFlags.NonPublic)?.SetValue(window,false);
   window.Focus();window.Repaint();
   // Layout uses Update even while presentation is held by the confirmation.
   if(loading)loading.enabled=true;
   file=Path.Combine(output,name+".png");wait=16;
  }
  static void Tick(){try{
   if(EditorApplication.timeSinceStartup-started>100)throw new Exception("Visual watchdog "+phase);if(error!=null)throw new Exception(error);if(!EditorApplication.isPlaying)return;
   if(wait<0)return;if(wait>0){if(--wait==0){wait=-1;combat.gameObject.AddComponent<CommerceScreenshotCapture>().Run(file,()=>wait=0);}return;}
   if(!combat){combat=UnityEngine.Object.FindFirstObjectByType<M2BattleDemo>();if(!combat)return;loading=combat.GetComponent<LoadingView>();}
   if(!combat.Ready||!combat.GetComponent<CampaignPersistence>().Ready||!loading)return;
   switch(phase){
    case 0:loading.ShowClearConfirmation();Snap("01_clear_confirmation");phase++;break;
    case 1:Snap("02_clear_confirmation_tall",720,1600);phase++;break;
    case 2:Snap("03_clear_confirmation_tablet",768,1024);phase++;break;
    case 3:
     GameObject.Find("LoadingDialog").GetComponent<UnityEngine.UI.Image>().enabled=false;
     GameObject.Find("LoadingDialog").transform.Find("Panel").gameObject.SetActive(false);
     Snap("04_loading_tablet",768,1024);phase++;break;
    case 4:Snap("05_loading_tall",720,1600);phase++;break;
    case 5:Snap("06_loading",941,1672);phase++;break;
    case 6:
     // Invoke the same cancel listener after the visual capture, then verify real scene entry.
     GameObject.Find("LoadingDialog").transform.Find("Panel").gameObject.SetActive(true);
     GameObject.Find("ClearCancelButton").GetComponent<UnityEngine.UI.Button>().onClick.Invoke();phase++;break;
    case 7:if(!combat.GetComponent<NavigationIntegration>().Ready||loading.Visible)return;Snap("07_hub_after_loading");phase++;break;
    case 8:
     if(EditorBuildSettings.scenes.Length<1||EditorBuildSettings.scenes[0].path!="Assets/MergeTo10/Scenes/NavigationIntegration.unity")throw new Exception("Wrong default build scene");
     Finish(null);break;
   }
  }catch(Exception ex){Finish(ex.ToString());}}
  static void Finish(string failure){SessionState.SetBool(Pending,false);EditorApplication.update-=Tick;Application.logMessageReceived-=Log;File.WriteAllText(Path.Combine(output,"loading-visual-result.txt"),failure==null?"PASS actual NavigationIntegration scene: loading/cancel/hub; configured first build scene; captures at 941x1672, 720x1600, 768x1024. Editor only, no player build/device acceptance.":"FAIL "+failure);EditorApplication.Exit(failure==null?0:1);}
 }
}
