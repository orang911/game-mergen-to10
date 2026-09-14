using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(BattleHudView))]
 public sealed class BattlePauseView:MonoBehaviour {
  M2BattleDemo combat;BattleHudView hud;GameUiSurface ui;bool wasPaused;
  public System.Action SettingsRequested,ExitRequested;
  public bool Visible=>ui!=null;
  void Awake(){combat=GetComponent<M2BattleDemo>();hud=GetComponent<BattleHudView>();hud.PauseRequested+=Show;}
  public void Show(){
   if(Visible||!combat.Ready||combat.Paused||combat.Gate!=M2BattleDemo.ChapterGate.None||GetComponent<M1BoardDemo>().Busy)return;
   wasPaused=combat.Paused;combat.SetPaused(true);ui=new GameUiSurface("BattlePauseCanvas",1200,.68f);
   var panel=ui.Art(ui.Root,"hud_pause_shell",278.5f,695,384,282);
   ui.Label(panel.transform,"暂停中",33,Color.white,96,24,192,55,900);
   Action(panel.transform,"设置",29,120,157,135,()=>SettingsRequested?.Invoke(),SettingsRequested!=null);
   Action(panel.transform,"退出",199,120,156,135,()=>ExitRequested?.Invoke(),ExitRequested!=null);
   ui.Shade.gameObject.EnsureComponent<Button>().onClick.AddListener(Resume);
   // Prevent clicking the panel itself from reaching the shade.
   panel.raycastTarget=true;ui.Complete();
  }
  void Action(Transform parent,string title,float x,float y,float w,float h,UnityEngine.Events.UnityAction action,bool enabled){
   var hit=GameUiSurface.Rect(parent,title,x,y,w,h).gameObject.EnsureComponent<Image>();hit.color=Color.clear;
   var button=hit.gameObject.EnsureComponent<Button>();button.targetGraphic=hit;button.interactable=enabled;button.onClick.AddListener(action);
   ui.Label(parent,title,26,enabled?Color.white:Color.gray,x,203,w,44);
  }
  public void Resume(){if(!Visible)return;ui.Dispose();ui=null;combat.SetPaused(wasPaused);}
  void OnDisable(){Resume();}
  void OnDestroy(){if(hud)hud.PauseRequested-=Show;Resume();}
 }
}
