using System;
using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 public sealed class ExitConfirmationView:MonoBehaviour {
  GameUiSurface ui;Action accepted,cancelled;
  public bool Visible=>ui!=null;
  public void Show(Action confirm,Action cancel){
   Hide();accepted=confirm;cancelled=cancel;ui=new GameUiSurface("ExitConfirmationCanvas",1300,.68f);
   var panel=ui.Art(ui.Root,"exit_shell",321,748,299,176);panel.raycastTarget=true;
   ui.Label(panel.transform,"退出后将结束本次挑战",20,Color.white,20,8,259,54);
   Button(panel.transform,"继续挑战",14,89,127,63,Cancel);Button(panel.transform,"确认退出",155,89,128,63,Confirm);
   ui.Shade.gameObject.EnsureComponent<Button>().onClick.AddListener(Cancel);ui.Complete();
  }
  void Button(Transform parent,string title,float x,float y,float w,float h,UnityEngine.Events.UnityAction action){
   var hit=GameUiSurface.Rect(parent,title,x,y,w,h).gameObject.EnsureComponent<Image>();hit.color=Color.clear;var button=hit.gameObject.EnsureComponent<Button>();button.targetGraphic=hit;button.onClick.AddListener(action);
   ui.Label(parent,title,23,Color.white,x,y-3,w,h,900);
  }
  public void Confirm(){if(!Visible)return;var call=accepted;Hide();call?.Invoke();}
  public void Cancel(){if(!Visible)return;var call=cancelled;Hide();call?.Invoke();}
  void Hide(){ui?.Dispose();ui=null;accepted=cancelled=null;}
  void OnDisable(){Hide();}
  void OnDestroy(){Hide();}
 }
}
