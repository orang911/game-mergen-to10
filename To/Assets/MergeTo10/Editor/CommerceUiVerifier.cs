using System;
using System.IO;
using System.Collections.Generic;
using MergeTo10.Core;
using MergeTo10.Runtime;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.Rendering;
using UnityEngine.UI;

namespace MergeTo10.Editor {
 public static class CommerceUiVerifier {
  static bool prepared; static string output,error; static int phase,checks; static double start,next;
  static M2BattleDemo combat; static CommerceView view; static MainHubView hub; static CampaignPersistence disk;
  static int wallet; static double seconds; static int screenshotWait; static RenderTexture target; static Camera camera; static string screenshotName;
  const string Pending="CommerceValidationPending";
  public static void Validate() {
   output=Environment.GetEnvironmentVariable("M2_EDITOR_OUTPUT");
   if(string.IsNullOrEmpty(output))throw new Exception("M2_EDITOR_OUTPUT required");
   Directory.CreateDirectory(output);SessionState.SetString("CommerceOutput",output);
   EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
   var go=new GameObject("CommerceValidation");go.AddComponent<M1BoardDemo>();go.AddComponent<M2BattleDemo>().CampaignMode=true;
   go.AddComponent<ChapterNodeView>();go.AddComponent<CrystalChoiceView>();go.AddComponent<EnergyHudView>();go.AddComponent<ImprintChoiceView>();
   go.AddComponent<CampaignPersistence>().PathOverride=Path.Combine(output,"commerce_test_save.json");
   go.AddComponent<NavigationIntegration>();
   SessionState.SetBool(Pending,true);EditorApplication.isPlaying=true;
  }
  [InitializeOnLoadMethod] static void Resume() {
   if(!SessionState.GetBool(Pending,false))return;
   output=SessionState.GetString("CommerceOutput","");start=EditorApplication.timeSinceStartup;next=start;phase=checks=0;error=null;prepared=false;
   Application.logMessageReceived+=Log;EditorApplication.update+=Tick;
  }
  static void Log(string message,string stack,LogType kind){if((kind==LogType.Error||kind==LogType.Exception)&&stack.Contains("MergeTo10"))error=message+"\n"+stack;}
  static void Check(bool condition,string message){checks++;if(!condition)throw new Exception(message);}
  static T Find<T>(string name) where T:Component {var go=GameObject.Find(name);Check(go!=null,"Missing "+name);var c=go.GetComponent<T>();Check(c!=null,"Missing component "+name);return c;}
  static void Click(string name) {
   var button=Find<Button>(name);Check(button.IsInteractable(),name+" should be enabled");Canvas.ForceUpdateCanvases();
   var rect=button.GetComponent<RectTransform>();var canvas=button.GetComponentInParent<Canvas>();
   var point=RectTransformUtility.WorldToScreenPoint(canvas.renderMode==RenderMode.ScreenSpaceOverlay?null:canvas.worldCamera,rect.TransformPoint(rect.rect.center));
   ClickPoint(point,button.gameObject);
  }
  static void ClickPoint(Vector2 point,GameObject expected) {
   var e=new PointerEventData(EventSystem.current){position=point,button=PointerEventData.InputButton.Left};
   var hits=new List<RaycastResult>();EventSystem.current.RaycastAll(e,hits);Check(hits.Count>0,"UI raycast hit");
   var clicked=ExecuteEvents.GetEventHandler<IPointerClickHandler>(hits[0].gameObject);
   Check(clicked==expected,"Top raycast expected "+expected.name+", actual "+(clicked?clicked.name:hits[0].gameObject.name));
   ExecuteEvents.Execute(clicked,e,ExecuteEvents.pointerDownHandler);ExecuteEvents.Execute(clicked,e,ExecuteEvents.pointerUpHandler);ExecuteEvents.Execute(clicked,e,ExecuteEvents.pointerClickHandler);
  }
  static void Dismiss(){var shade=GameObject.Find("CommerceCanvas").transform.Find("Shade").gameObject;ClickPoint(new Vector2(5,5),shade);Check(!view.Visible,"outside tap closes page");}
  static void Snap(string name,int width=941,int height=1672) {
   var assembly=typeof(UnityEditor.Editor).Assembly;
   var sizesType=assembly.GetType("UnityEditor.GameViewSizes");
   var singleton=typeof(ScriptableSingleton<>).MakeGenericType(sizesType);
   var sizes=singleton.GetProperty("instance").GetValue(null);
   var group=sizesType.GetMethod("GetGroup").Invoke(sizes,new object[]{0});
   var sizeType=assembly.GetType("UnityEditor.GameViewSize");
   var enumType=assembly.GetType("UnityEditor.GameViewSizeType");
   var size=Activator.CreateInstance(sizeType,System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.Public|System.Reflection.BindingFlags.NonPublic,null,new object[]{Enum.ToObject(enumType,1),width,height,"Commerce QA"},null);
   group.GetType().GetMethod("AddCustomSize").Invoke(group,new[]{size});
   int count=(int)group.GetType().GetMethod("GetTotalCount").Invoke(group,null);
   var viewType=assembly.GetType("UnityEditor.GameView");var window=EditorWindow.GetWindow(viewType);
   viewType.GetProperty("selectedSizeIndex",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.Public|System.Reflection.BindingFlags.NonPublic).SetValue(window,count-1);
      window.Focus();window.Repaint();
   screenshotName=name;screenshotWait=12;
  }
  static void SaveScreenshot() {
   if(view.Visible){var canvas=GameObject.Find("CommerceCanvas");var shade=canvas.transform.Find("Shade").GetComponent<Image>();File.AppendAllText(Path.Combine(output,"render_diagnostics.txt"),screenshotName+": shade rect="+shade.rectTransform.rect+" color="+shade.color+" cull="+shade.canvasRenderer.cull+" material="+shade.material.name+"\n");}
   screenshotWait=-1;
   var runner=combat.gameObject.AddComponent<CommerceScreenshotCapture>();
   runner.Run(Path.Combine(output,screenshotName+".png"),()=>screenshotWait=0);
  }
  static void Saved(bool owned,int piggy,int coins) {
   Check(disk.SaveStable(),"stable lobby save succeeds");
   var snapshot=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(new ProfileStore(disk.PathOverride).Load(out _));var meta=new MetaProgress();meta.Restore(snapshot.Meta);
   Check(meta.State.DoubleCoin==owned&&meta.State.RemoveAds==owned&&meta.State.Piggy==piggy&&meta.State.Coins==coins,"disk roundtrip wallet/ownership/piggy");
  }
  static void Tick() {
   try{
    double now=EditorApplication.timeSinceStartup;if(now-start>90)throw new Exception("Commerce watchdog phase "+phase);
    if(error!=null)throw new Exception(error);if(!EditorApplication.isPlaying)return;
    if(screenshotWait<0)return;if(screenshotWait>0){if(--screenshotWait==0)SaveScreenshot();return;}if(now<next)return;
    if(!combat){combat=UnityEngine.Object.FindFirstObjectByType<M2BattleDemo>();if(!combat)return;}
    if(!combat.Ready||!combat.GetComponent<NavigationIntegration>().Ready)return;
    if(!view){view=combat.GetComponent<CommerceView>();hub=combat.GetComponent<MainHubView>();disk=combat.GetComponent<CampaignPersistence>();}
    if(!prepared){prepared=true;Snap("00_hub");return;}
    switch(phase) {
     case 0:
      Check(view!=null&&hub.Visible&&disk.Ready,"existing navigation bootstraps commerce and persistence");
      combat.Meta.Restore(JsonUtility.ToJson(new MetaState{Coins=1804,Crystals=120,Day="2026-09-14"}));
      seconds=combat.CombatSeconds;Click("DoubleCoinButton");break;
     case 1:
      Check(view.PageId=="benefits","double coin opens shared bundle");
      Check(Find<Canvas>("CommerceCanvas").sortingOrder>Find<Canvas>("MainHubCanvas").sortingOrder,"commerce above hub");
      Check(Find<Text>("BenefitCopy_double_coin").text=="挑战结算金币 +100%","bundle copy");Snap("01_benefits");break;
     case 2:
      Click("BenefitsPurchaseButton");Check(view.PageId=="purchase_confirm","buy opens confirmation");break;
     case 3:Snap("02_benefits_confirm");break;
     case 4:Click("PurchaseCancelButton");Check(!combat.Meta.State.DoubleCoin&&view.PageId=="benefits","cancel makes no purchase");break;
     case 5:Dismiss();Click("RemoveAdsButton");break;
     case 6:Check(view.PageId=="benefits","remove ads opens same bundle");Click("BenefitsPurchaseButton");break;
     case 7:
      combat.Meta.LocalPurchase=id=>false;Click("PurchaseConfirmButton");
      Check(view.LastPurchaseResult=="payment_failed"&&!combat.Meta.State.DoubleCoin&&combat.Meta.State.Coins==1804&&view.PageId=="purchase_confirm","failure preserves ownership/wallet/confirmation");Snap("03_purchase_failure");break;
     case 8:
      combat.Meta.LocalPurchase=null;Click("PurchaseConfirmButton");view.ConfirmPurchase();
      Check(view.LastPurchaseResult=="ok"&&view.PageId=="benefits"&&combat.Meta.State.DoubleCoin&&combat.Meta.State.RemoveAds,"one confirmed local purchase grants both benefits");
      Check(!Find<Button>("BenefitsPurchaseButton").interactable,"owned button disabled");Saved(true,0,1804);break;
     case 9:Snap("04_benefits_owned");break;
     case 10:Dismiss();Click("PiggyButton");break;
     case 11:
      Check(view.PageId=="piggy"&&GameObject.Find("PiggyBankSelectedFrame_1"),"empty piggy stage");Click("PiggyBankPurchaseButton");
      Check(view.PageId=="piggy"&&Find<Text>("CommerceNotice").text=="当前尚未积累","empty piggy notice without confirmation");Snap("05_piggy_empty");break;
     case 12:combat.Meta.RecordSettlement(3400);break;
     case 13:
      Check(combat.Meta.State.Piggy==680&&GameObject.Find("PiggyBankSelectedFrame_2"),"live accumulation updates selected stage");
      Check(Mathf.Abs(Find<Image>("PiggyBankProgressFill").rectTransform.sizeDelta.x-394*.68f)<.01f,"live progress width");Snap("06_piggy_progress");break;
     case 14:Click("PiggyBankPurchaseButton");break;
     case 15:Check(Find<Text>("PurchasePrice").text=="¥12","piggy confirmation price");Snap("07_piggy_confirm");break;
     case 16:Click("PurchaseCancelButton");Check(combat.Meta.State.Piggy==680&&combat.Meta.State.Coins==1804,"piggy cancel preserves funds");break;
     case 17:combat.Meta.RecordSettlement(1600);break;
     case 18:Check(combat.Meta.State.Piggy==1000&&GameObject.Find("PiggyBankSelectedFrame_3"),"full piggy stage");Snap("08_piggy_full");break;
     case 19:Click("PiggyBankPurchaseButton");break;
     case 20:
      wallet=combat.Meta.State.Coins;Click("PurchaseConfirmButton");view.ConfirmPurchase();
      Check(combat.Meta.State.Coins==wallet+1000&&combat.Meta.State.Piggy==0&&view.PurchasedState,"piggy grants once and resets storage");
      Check(!Find<Button>("PiggyBankPurchaseButton").interactable&&GameObject.Find("PiggyBankSelectedFrame_4"),"purchased stage and disabled claim");Saved(true,0,wallet+1000);break;
     case 21:Snap("09_piggy_purchased");break;
     case 22:Dismiss();Click("PiggyButton");break;
     case 23:
      Check(!view.PurchasedState&&GameObject.Find("PiggyBankSelectedFrame_1"),"reopening purchased piggy shows empty state");
      combat.Meta.RecordSettlement(500);break;
     case 24:Click("PiggyBankPurchaseButton");break;
     case 25:
      wallet=combat.Meta.State.Coins;Click("PurchaseConfirmButton");Check(combat.Meta.State.Coins==wallet+100&&combat.Meta.State.Piggy==0,"partial piggy redemption is allowed by source");break;
     case 26:Dismiss();Click("RemoveAdsButton");break;
     case 27:Snap("10_benefits_tall",720,1600);break;
     case 28:Snap("11_benefits_tablet",768,1024);break;
     case 29:Dismiss();Click("PiggyButton");break;
     case 30:Snap("12_piggy_tall",720,1600);break;
     case 31:Snap("13_piggy_tablet",768,1024);break;
     case 32:
      Dismiss();Check(combat.Paused&&combat.NavigationSuspended&&combat.CombatSeconds==seconds,"all pages preserve paused lobby combat");
      for(int i=0;i<5;i++){view.ShowBenefits();view.ShowPiggy();view.Hide();}
      Check(!GameObject.Find("CommerceCanvas"),"repeated open/close removes active commerce canvases");
      Click("CrystalUpgradeButton");break;
     case 33:
      Check(Find<Canvas>("CrystalUpgradeCanvas").sortingOrder>Find<Canvas>("MainHubCanvas").sortingOrder,"crystal previous layer fix remains valid");
      Click("Back");Check(!combat.GetComponent<CrystalUpgradeView>().Visible,"crystal real raycast back");
      Finish(null);return;
    }
    phase++;next=now+.3;
   }catch(Exception e){Finish(e);}
  }
  static void Finish(Exception failure) {
   SessionState.SetBool(Pending,false);EditorApplication.update-=Tick;Application.logMessageReceived-=Log;
   File.WriteAllText(Path.Combine(output,"commerce-result.txt"),failure==null?"PASS checks="+checks+"; real UI raycast routes, both bundle entries, confirmation/cancel/failure/retry, ownership, four piggy stages, full and partial redemption, repeat prevention, disk roundtrip, paused combat, screenshots at 3 ratios, crystal layering/back. Local simulation only; no build or physical-device acceptance.":"FAIL phase="+phase+"\n"+failure);
   if(failure!=null)Debug.LogException(failure);EditorApplication.Exit(failure==null?0:1);
  }
 }
}
