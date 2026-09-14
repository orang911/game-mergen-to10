using System;
using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class BattleHudView:MonoBehaviour {
  M2BattleDemo combat;M1BoardDemo board;GameUiSurface ui;Text wave,count,timer,coins;Button pause;
  public event Action PauseRequested;
  public bool Ready=>ui!=null;
  public string WaveText=>wave?wave.text:"";
  public string CountText=>count?count.text:"";
  public string CoinText=>coins?coins.text:"";
  public string TimeText=>timer?timer.text:"";
  void Start(){
   combat=GetComponent<M2BattleDemo>();board=GetComponent<M1BoardDemo>();
   ui=new GameUiSurface("BattleHudCanvas",90,0);ui.Shade.gameObject.SetActive(false);
   ui.Art(ui.Root,"hud_wave",216,15,268,84);ui.Art(ui.Root,"hud_timer",506,15,178,84);
   ui.Art(ui.Root,"hud_currency",772,15,153,84);ui.Art(ui.Root,"hud_clock",519,39,37,37);ui.Art(ui.Root,"currency_coin",713,14,82,86);
   wave=Label("",32,231,20,143,74);count=Label("",32,374,20,104,74);
   timer=Label("00:00",32,553,20,123,74);coins=Label("0",30,795,19,127,75);
   var icon=ui.Art(ui.Root,"hud_pause",30,11,84,88);icon.raycastTarget=true;
   pause=icon.gameObject.EnsureComponent<Button>();pause.targetGraphic=icon;pause.onClick.AddListener(RequestPause);ui.Complete();
  }
  Text Label(string value,int size,float x,float y,float w,float h){
   var text=ui.Label(ui.Root,value,size,Color.white,x,y,w,h,900);text.horizontalOverflow=HorizontalWrapMode.Overflow;return text;
  }
  public void RequestPause(){
   if(!combat||!combat.Ready||!combat.CampaignMode||board.Busy||combat.Frozen||combat.Gate!=M2BattleDemo.ChapterGate.None)return;
   PauseRequested?.Invoke();
  }
  void Update(){
   if(ui==null)return;ui.CanvasObject.SetActive(combat.Ready&&combat.CampaignMode&&!combat.NavigationSuspended);
   if(combat.Campaign==null)return;
   var current=combat.Campaign.Current;var state=combat.Campaign.State;
   string display=!string.IsNullOrEmpty(current.display_label)?current.display_label:!string.IsNullOrEmpty(current.node_id)?current.node_id:(state.Index+1).ToString();
   wave.text=display.StartsWith("续战")?display.Replace("续战 ","续战"):"第"+display+"波";
   wave.fontSize=current.continuation?28:32;
   count.text=(combat.AliveCount+state.Queue.Count)+"/"+state.Total;
   int seconds=Mathf.Max(0,(int)combat.CombatSeconds);timer.text=(seconds/60).ToString("00")+":"+(seconds%60).ToString("00");
   coins.text=combat.Meta.State.Coins.ToString();
   pause.interactable=PauseRequested!=null&&!combat.Paused&&!board.Busy&&!combat.Frozen&&combat.Gate==M2BattleDemo.ChapterGate.None;
  }
  void OnDisable(){if(ui!=null&&ui.CanvasObject)ui.CanvasObject.SetActive(false);}
  void OnDestroy(){ui?.Dispose();}
 }
}
