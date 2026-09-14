using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class NavigationSettingsView:MonoBehaviour {
  GameUiSurface ui;M2BattleDemo combat;Action closed;
  public bool Visible=>ui!=null;
  void Awake(){combat=GetComponent<M2BattleDemo>();}
  public void Show(Action onClose,bool fromBattle=false){
   Hide(false);closed=onClose;ui=new GameUiSurface("NavigationSettingsCanvas",1300,fromBattle?.68f:.45f);
   var panel=ui.Art(ui.Root,"settings_panel",214,478,514,716);panel.raycastTarget=true;
   Text(panel.transform,"设置",31,150,18,214,58);
   ui.Art(panel.transform,"settings_divider",67,80,380,18);
   Toggle(panel.transform,"音乐","music",113,new Rect(26,18,39,45));
   Toggle(panel.transform,"音效","sound",205,new Rect(23,22,45,38));
   Toggle(panel.transform,"震动","vibration",297,new Rect(22,18,47,46));
   RowAction(panel.transform,"帮助与反馈","help",411,new Rect(23,18,45,46),"帮助与反馈功能已预留");
   RowAction(panel.transform,"隐私 / 用户协议","privacy",502,new Rect(25,18,42,47),"隐私与用户协议为本地测试占位");
   ui.Art(panel.transform,"settings_divider",67,600,380,18);
   // Destructive clear is not wired until the complete navigation/profile reset contract exists.
   var clear=Text(panel.transform,"清空本地数据",24,105,624,304,60);clear.color=new Color(.65f,.45f,.45f);
   ui.Shade.gameObject.EnsureComponent<Button>().onClick.AddListener(()=>Hide(true));ui.Complete();
  }
  RectTransform Row(Transform parent,float y){
   var row=GameUiSurface.Rect(parent,"SettingsRow",31,y,452,82);
   ui.Art(row,"settings_row",0,0,452,82);
   ui.Art(row,"settings_patch_icon",16,13,64,56);ui.Art(row,"settings_patch_control",320,11,120,60);return row;
  }
  Text Text(Transform parent,string copy,int size,float x,float y,float w,float h){
   return ui.Label(parent,copy,size,new Color(.09f,.20f,.36f),x,y,w,h,700);
  }
  void Toggle(Transform parent,string title,string id,float y,Rect icon){
   var row=Row(parent,y);ui.Art(row,"settings_"+id,icon.x,icon.y,icon.width,icon.height);
   Text(row,title,28,88,0,220,82).alignment=TextAnchor.MiddleLeft;
   bool value=Read(id);var art=ui.Art(row,"settings_switch_"+(value?"on":"off"),336,16,96,51);
   Button(row,326,9,116,66,()=>{
    bool next=!Read(id);SetSetting(id,next);
    var replacement=ui.Art(row,"settings_switch_"+(next?"on":"off"),336,16,96,51);Destroy(art.gameObject);art=replacement;
   });
  }
  bool Read(string id)=>id=="music"?combat.Meta.State.Music:id=="sound"?combat.Meta.State.Sound:combat.Meta.State.Vibration;
  public bool SetSetting(string id,bool enabled){
   switch(id){case "music":combat.Meta.State.Music=enabled;break;case "sound":combat.Meta.State.Sound=enabled;break;case "vibration":combat.Meta.State.Vibration=enabled;break;default:return false;}
   if(combat.HitAudio)combat.HitAudio.Muted=!combat.Meta.State.Sound;GetComponent<M1BoardDemo>().SoundEnabled=combat.Meta.State.Sound;
   GetComponent<CampaignPersistence>()?.SaveStable();return true;
  }
  void RowAction(Transform parent,string title,string id,float y,Rect icon,string notice){
   var row=Row(parent,y);ui.Art(row,"settings_"+id,icon.x,icon.y,icon.width,icon.height);ui.Art(row,"settings_arrow_right",410,27,18,29);
   Text(row,title,25,88,0,300,82).alignment=TextAnchor.MiddleLeft;
   Button(row,0,0,452,82,()=>{var message=Text(ui.Root,notice,20,210,1200,520,60);StartCoroutine(ClearNotice(message.gameObject));});
  }
  IEnumerator ClearNotice(GameObject notice){yield return new WaitForSecondsRealtime(2);if(notice)Destroy(notice);}
  static void Button(Transform parent,float x,float y,float w,float h,UnityEngine.Events.UnityAction action){
   var image=GameUiSurface.Rect(parent,"Hit",x,y,w,h).gameObject.EnsureComponent<Image>();image.color=Color.clear;var button=image.gameObject.EnsureComponent<Button>();button.targetGraphic=image;button.transition=Selectable.Transition.None;button.onClick.AddListener(action);
  }
  public void Hide(bool notify){StopAllCoroutines();ui?.Dispose();ui=null;var callback=closed;closed=null;if(notify)callback?.Invoke();}
  void OnDisable(){Hide(false);}
  void OnDestroy(){Hide(false);}
 }
}
