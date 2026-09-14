using System;
using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 // Precise port of frozen loading_view.tscn/gd. Background covers; controls fit 941x1672.
 public sealed class LoadingView:MonoBehaviour {
  GameUiSurface ui,notice;CampaignPersistence disk;CanvasGroup group;
  RectTransform clip;Image background;Text percent,status;GameObject dialog;
  float elapsed,fade;bool finishing,confirmedRecovery;
  public bool Visible=>ui!=null;
  public bool ConfirmationVisible=>dialog;
  public float Progress {get;private set;}
  public bool CanEnter=>Visible&&!finishing&&!dialog&&elapsed>=2.5f&&disk&&disk.Ready&&disk.Error.Length==0&&(!disk.Recovered||confirmedRecovery);
  void Awake(){disk=GetComponent<CampaignPersistence>();Build();}
  void Build(){
   ui?.Dispose();ui=new GameUiSurface("LoadingCanvas",2000,1);
   group=ui.CanvasObject.EnsureComponent<CanvasGroup>();
   background=ui.Art(ui.CanvasObject.transform,"loading_background_clean_hd_941x1672_v01",0,0,941,1672);
   background.transform.SetSiblingIndex(1);
   background.rectTransform.anchorMin=background.rectTransform.anchorMax=background.rectTransform.pivot=Vector2.one*.5f;
   background.rectTransform.anchoredPosition=Vector2.zero;
   ui.Art(ui.Root,"ui_loading_track_empty_576x48_1x_v01",182.5f,1420,576,48);
   clip=GameUiSurface.Rect(ui.Root,"LoadingFillClip",182.5f,1420,0,48);clip.gameObject.EnsureComponent<RectMask2D>();
   ui.Art(clip,"ui_loading_fill_green_full_576x48_1x_v01",0,0,576,48);
   percent=Copy(ui.Root,"0%",26,182.5f,1420,576,48);percent.name="LoadingPercent";
   status=Copy(ui.Root,"正在加载…",28,182.5f,1485,576,48);
   Button(ui,ui.Root,"ClearLocalDataButton","清空本地数据",24,1594,166,48,ShowClearConfirmation,true);
   ui.Complete();elapsed=fade=0;finishing=false;Progress=0;
  }
  Text Copy(Transform parent,string text,int size,float x,float y,float w,float h){
   var label=ui.Label(parent,text,size,Color.white,x,y,w,h);
   var outline=label.gameObject.EnsureComponent<Outline>();outline.effectColor=new Color(.055f,.11f,.075f);outline.effectDistance=new Vector2(2,-2);return label;
  }
  static Button Button(GameUiSurface surface,Transform parent,string name,string text,float x,float y,float w,float h,Action action,bool flat=false){
   var rect=GameUiSurface.Rect(parent,name,x,y,w,h);var image=rect.gameObject.EnsureComponent<Image>();image.color=flat?new Color(0,0,0,.01f):new Color(.1f,.35f,.56f);
   var button=rect.gameObject.EnsureComponent<Button>();button.targetGraphic=image;button.onClick.AddListener(()=>action());
   surface.Label(rect,text,flat?20:26,Color.white,4,0,w-8,h);return button;
  }
  void Update(){
   if(!disk)disk=GetComponent<CampaignPersistence>();
   if(ui==null){UpdateSaveNotice();return;}
   var screen=(RectTransform)ui.CanvasObject.transform;
   float scale=Mathf.Max(screen.rect.width/941,screen.rect.height/1672);
   background.rectTransform.sizeDelta=new Vector2(941,1672)*scale;
   if(finishing){fade+=Time.unscaledDeltaTime;group.alpha=1-Mathf.Pow(Mathf.Clamp01(fade/.18f),2);if(fade>=.18f){ui.Dispose();ui=null;}return;}
   if(disk&&disk.Error.Length>0){status.text=disk.Ready?"本地数据保存失败":"本地数据读取失败";if(!dialog)ShowError();return;}
   if(disk&&disk.Recovered&&!confirmedRecovery){if(!dialog)ShowRecovery();return;}
   if(dialog)return;
   status.text="正在加载…";
   elapsed=Mathf.Min(2.5f,elapsed+Time.unscaledDeltaTime);
   float value=elapsed<=1.75f?85*elapsed/1.75f:elapsed<=2.25f?85+10*(elapsed-1.75f)/.5f:95+5*(elapsed-2.25f)/.25f;
   Progress=disk&&disk.Ready?value:Mathf.Min(95,value);
   clip.sizeDelta=new Vector2(576*Progress/100,48);percent.text=Mathf.RoundToInt(Progress)+"%";
   if(disk&&disk.Ready&&elapsed>=2.5f)disk.SaveStable();
  }
  public void Finish(){if(!CanEnter)return;finishing=true;}
  RectTransform Panel(string title,string message,string prefabId){
   CloseDialog();
   var overlay=GameUiSurface.Subtree(ui.Root,prefabId,"LoadingDialog",0,0,941,1672);dialog=overlay.gameObject;
   var shade=overlay.gameObject.EnsureComponent<Image>();shade.color=new Color(0,0,0,.6f);
   var panel=GameUiSurface.Rect(overlay,"Panel",160.5f,676,620,320);var bg=panel.gameObject.EnsureComponent<Image>();bg.color=new Color(.1f,.19f,.29f);
   Copy(panel,title,32,20,16,580,50);Copy(panel,message,25,32,78,556,144);return panel;
  }
  public void ShowClearConfirmation(){
   if(!Visible||finishing)return;
   var panel=Panel("清空本地数据","将清空本机的章节进度、卡片等级、货币与新手记录。是否确认清空？","LoadingClearDialog");
   Button(ui,panel,"ClearCancelButton","取消",38,246,240,54,CloseDialog);
   Button(ui,panel,"ClearConfirmButton","确认清空",342,246,240,54,()=>{
    if(!disk||!disk.ResetLocalData()){CloseDialog();ShowError();return;}
    CloseDialog();confirmedRecovery=false;Build();
   });dialog.GetComponent<UiPrefabInstance>()?.CompleteBinding();
  }
  void ShowError(){
   var panel=Panel("本地数据暂时不可用",disk&&disk.Ready?"保存未成功，请检查可用空间与访问权限后重试。":"未能读取本地记录，现有文件已保留。请重试，或确认清空后重新开始。","LoadingErrorDialog");
   Button(ui,panel,"LoadRetryButton","重试",38,246,240,54,()=>{CloseDialog();if(disk){if(disk.Ready)disk.SaveStable();else disk.RetryLoad();}});
   Button(ui,panel,"LoadResetButton","清空本地数据",342,246,240,54,ShowClearConfirmation);dialog.GetComponent<UiPrefabInstance>()?.CompleteBinding();
  }
  void ShowRecovery(){
   var panel=Panel("已恢复本地记录","已从有效的备用记录恢复进度，部分最近操作可能未保存。原文件已保留。","LoadingRecoveryDialog");
   Button(ui,panel,"RecoveryContinueButton","继续",190,246,240,54,()=>{confirmedRecovery=true;CloseDialog();});dialog.GetComponent<UiPrefabInstance>()?.CompleteBinding();
  }
  void CloseDialog(){if(dialog){dialog.SetActive(false);Destroy(dialog);}dialog=null;}
  void UpdateSaveNotice(){
   if(!disk||disk.Error.Length==0){notice?.Dispose();notice=null;return;}
   if(notice!=null)return;
   notice=new GameUiSurface("SaveErrorCanvas",2200,0);notice.Shade.raycastTarget=false;
   var panel=GameUiSurface.Rect(notice.Root,"SaveErrorPanel",70,90,801,100);var bg=panel.gameObject.EnsureComponent<Image>();bg.color=new Color(.12f,.2f,.3f,.97f);
   notice.Label(panel,"本地保存失败，请检查空间后重试",25,Color.white,16,4,570,90);
   Button(notice,panel,"SaveRetryButton","重试",600,22,175,56,()=>disk.SaveStable());notice.Complete();
  }
  void OnDestroy(){ui?.Dispose();notice?.Dispose();}
 }
}
