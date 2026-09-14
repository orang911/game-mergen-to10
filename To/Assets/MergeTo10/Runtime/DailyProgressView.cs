using System;
using MergeTo10.Core;
using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class DailyProgressView:MonoBehaviour {
  GameUiSurface ui;M2BattleDemo combat;RectTransform root;
  static readonly Color Ink=new Color(.09f,.20f,.36f);
  public bool Visible=>ui!=null;
  public void Show(){
   Hide();combat=GetComponent<M2BattleDemo>();combat.Meta.SyncDay(DateTime.Now.ToString("yyyy-MM-dd",System.Globalization.CultureInfo.InvariantCulture));
   ui=new GameUiSurface("DailyProgressCanvas",1300,.45f);root=GameUiSurface.Rect(ui.Root,"DailyCombined",13,78,915,1513);
   var blocker=root.gameObject.EnsureComponent<Image>();blocker.color=Color.clear;
   Art(root,"daily_task_panel_shell_complete_v03",-6,0,927,1041);
   Text(root,"任务",48,43,0,388,90,Color.white);
   Art(root,"daily_icon_activity_star_v01",64,130,150,150);
   Text(root,"今日活跃度",32,195,164,330,50,Ink).alignment=TextAnchor.MiddleLeft;
   Progress(root,199,216,526,40,combat.Meta.ActivityPoints/100f);Text(root,combat.Meta.ActivityPoints+"/100",22,199,216,526,40,Color.white);
   var chest=Art(root,"daily_icon_chest_v01",741,161,96,88);if(combat.Meta.State.ActivityClaimed)chest.color=new Color(.62f,.68f,.76f,.88f);
   Text(root,"100",20,733,238,112,34,Color.white);
   Hit(root,720,142,145,132,()=>{if(combat.Meta.ClaimActivity()){Save();Show();}},combat.Meta.ActivityPoints>=100&&!combat.Meta.State.ActivityClaimed);
   for(int i=0;i<4;i++)Task(i);
   Signin();
   var close=Art(root,"daily_return_button_v03",796,-4,97,92);close.raycastTarget=true;var button=close.gameObject.EnsureComponent<Button>();button.targetGraphic=close;button.onClick.AddListener(Hide);
   ui.Shade.gameObject.EnsureComponent<Button>().onClick.AddListener(Hide);ui.Complete();
  }
  Image Art(Transform parent,string key,float x,float y,float w,float h)=>ui.Art(parent,key,x,y,w,h);
  Text Text(Transform parent,string copy,int font,float x,float y,float w,float h,Color color){
   var text=ui.Label(parent,copy,font,color,x,y,w,h);if(color==Color.white){var outline=text.gameObject.EnsureComponent<Outline>();outline.effectColor=Ink;outline.effectDistance=Vector2.one*2;}return text;
  }
  void Task(int index){
   string[] titles={"完成 1 次挑战","合成 20 次","击败 30 个怪物","今日登录"},icons={"challenge","merge","monster","login"};
   int[] targets={1,20,30,1},rewards={10,30,50,20};float[] ys={288,473,658,843},shells={284,469,654,839},px={172,171,170,170};
   bool ready=combat.Meta.CanClaimTask(index),claimed=combat.Meta.State.TaskClaimed[index];
   Art(root,ready?"daily_task_row_claimable_v02":"daily_task_row_default_v02",ready?38:36,shells[index]+(ready?1:0),ready?839:843,ready?176:178);
   var row=GameUiSurface.Rect(root,"Task_"+index,33,ys[index],856,207);
   Art(row,ready?"daily_icon_slot_selected_v01":"daily_icon_slot_v01",28,index==3?22:25,128,132);
   var rects=new[]{new Rect(4,3,180,180),new Rect(-1,-2,185,185),new Rect(0,3,184,184),new Rect(3,-4,175,175)};var r=rects[index];
   Art(row,"daily_icon_"+icons[index]+"_v01",r.x,r.y,r.width,r.height);
   Text(row,titles[index],30,180,34,340,52,Ink).alignment=TextAnchor.MiddleLeft;
   float py=index==3?99:104;Progress(row,px[index]+3,py,255,38,combat.Meta.State.TaskProgress[index]/(float)targets[index]);
   Text(row,combat.Meta.State.TaskProgress[index]+"/"+targets[index],22,px[index]+3,py,255,38,Color.white);
   bool crystal=index==0||index==3;Art(row,crystal?"currency_diamond":"currency_coin",crystal?506:511,crystal?42:48,crystal?80:74,crystal?84:74);
   Text(row,"×"+rewards[index],24,496,123,100,37,Ink);
   Button(row,claimed?"已领取":ready?"领取":"未完成",ready?"claim":claimed?"claimed":"disabled",ready?640:638,ready?37:50,ready?190:189,ready?108:88,ready?36:31,()=>ClaimTask(index),ready);
  }
  public bool ClaimTask(int index){if(!combat.Meta.ClaimTask(index))return false;Save();Show();return true;}
  public bool ClaimSignin(){if(!combat.Meta.ClaimSign())return false;Save();Show();return true;}
  void Signin(){
   var parent=GameUiSurface.Rect(root,"Signin",0,1060,915,453);Art(parent,"daily_signin_panel_shell_complete_v03",-6,0,928,434);Text(parent,"签到",41,31,0,292,78,Color.white);
   bool available=combat.Meta.SignAvailable;int claimed=combat.Meta.State.SignDay==combat.Meta.State.Day?combat.Meta.State.SignStreak:Mathf.Max(0,combat.Meta.SignPreview-1);
   int current=(available?combat.Meta.SignPreview:combat.Meta.SignPreview%7+1)-1;
   int[] rewards={20,30,20,50,20,30,100};float total=0;for(int i=0;i<7;i++)total+=i==current||i==6?138:107;
   float x=36,gap=(854-total)/6;
   for(int i=0;i<7;i++){
    bool active=i==current,premium=i==6,done=i<claimed&&!( !available&&active);float width=active||premium?138:107;
    Art(parent,active||premium?"daily_signin_card_selected_v02":done?"daily_signin_card_claimed_v02":"daily_signin_card_default_v02",x,148,width,239);
    Text(parent,"第"+(i+1)+"天",26,x,168,width,39,Color.white);
    bool coin=i==1||i==3||i==5;float w=premium?116:coin?(active?86:80):(active?84:80),h=premium?104:coin?w:active?94:90;
    float offset=premium?53:coin?(active?66:67):(active?58:61);
    var reward=Art(parent,premium?"daily_icon_chest_v01":coin?"currency_coin":"currency_diamond",x+(width-w)/2,148+offset,w,h);if(done)reward.color=Color.gray;
    Text(parent,"×"+rewards[i],27,x,148+(premium?158:146),width,38,Color.white);
    if(done){Art(parent,"daily_icon_claimed_check_v01",x+(width-44)/2,322,44,36);Text(parent,"已领取",20,x,352,width,31,Color.white);}
    if(active)Button(parent,available?"今日签到":"明日领取","claim",x+12,338,width-24,39,19,()=>ClaimSignin(),available);
    x+=width+gap;
   }
  }
  void Progress(Transform parent,float x,float y,float w,float h,float ratio){Capsule(parent,"daily_progress_track_v01",x,y,w,h);if(ratio>0)Capsule(parent,"daily_progress_fill_v01",x,y,Mathf.Round(w*Mathf.Clamp01(ratio)),h);}
  void Capsule(Transform parent,string key,float x,float y,float w,float h){
   var texture=Resources.Load<Texture2D>("Campaign/"+key);float source=Mathf.Ceil(texture.height*.5f),cap=Mathf.Min(h*.5f,w*.5f);
   ui.Region(parent,key,new Rect(0,0,source,texture.height),new Rect(x,y,cap,h));
   if(w>cap*2)ui.Region(parent,key,new Rect(source,0,texture.width-source*2,texture.height),new Rect(x+cap,y,w-cap*2,h));
   ui.Region(parent,key,new Rect(texture.width-source,0,source,texture.height),new Rect(x+w-cap,y,cap,h));
  }
  void Button(Transform parent,string copy,string state,float x,float y,float w,float h,int font,UnityEngine.Events.UnityAction action,bool enabled){
   var image=Art(parent,"daily_button_"+state+"_v01",x,y,w,h);image.raycastTarget=true;var button=image.gameObject.EnsureComponent<Button>();button.targetGraphic=image;button.interactable=enabled;button.onClick.AddListener(action);
   Text(image.transform,copy,font,0,0,w,h,state=="claim"?Color.white:new Color(.72f,.8f,.89f));
  }
  static void Hit(Transform parent,float x,float y,float w,float h,UnityEngine.Events.UnityAction action,bool enabled){
   var image=GameUiSurface.Rect(parent,"Hit",x,y,w,h).gameObject.EnsureComponent<Image>();image.color=Color.clear;var button=image.gameObject.EnsureComponent<Button>();button.targetGraphic=image;button.interactable=enabled;button.onClick.AddListener(action);
  }
  void Save(){GetComponent<CampaignPersistence>()?.SaveStable();}
  public void Hide(){ui?.Dispose();ui=null;}
  void OnDisable(){Hide();}
  void OnDestroy(){Hide();}
 }
}
