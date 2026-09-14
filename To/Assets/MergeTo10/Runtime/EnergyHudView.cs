using System.Collections.Generic;
using System.Collections;
using MergeTo10.Core;
using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class EnergyHudView:MonoBehaviour {
  sealed class Mote {public Vector2 Start,Control,Target;public float Age,Delay,Duration;public int Step;public bool Bright;public readonly List<Vector2> Trail=new List<Vector2>();}
  static readonly string[] Names={"星阶铸锤","万象数盘","命运魔箱","双生晶模","王城魔炮","龙焰投石"};
  readonly List<Mote> motes=new List<Mote>();
  M2BattleDemo combat;GameUiSurface ui;RectTransform hud;Image fill,inactive,pending;Text meter,label;
  EnergyMoteGraphic graphic;SkillEnergyState state;string pendingId="";int visual;float finishDelay=-1;
  Image flying;bool triggering;readonly List<Vector2> imprintTrail=new List<Vector2>();float trailFade=1;
  public int VisualEnergy=>visual;public int ActiveMotes=>motes.Count;
  public bool Ready=>ui!=null;
  void Start(){
   combat=GetComponent<M2BattleDemo>();combat.EnergyFxRequested+=Gain;
   GetComponent<M1BoardDemo>().PlayPendingImprint=Trigger;
   ui=new GameUiSurface("EnergyHudCanvas",80,0);ui.Shade.gameObject.SetActive(false);
   hud=GameUiSurface.Rect(ui.Root,"EnergyHud",14,1420,913,210);
   ui.Art(hud,"energy_panel",22,31,400,147);
   ui.Art(hud,"energy_disabled",35,52,105,114);
   inactive=ui.Art(hud,"energy_slot",49,67,77,84);
   var frame=GameUiSurface.Rect(hud,"EnergyFrame",169,122,226,35).gameObject.EnsureComponent<Image>();
   frame.raycastTarget=false;frame.color=new Color(.72f,.86f,.96f,.95f);
   var inside=GameUiSurface.Rect(frame.transform,"Inside",3,3,220,29).gameObject.EnsureComponent<Image>();
   inside.raycastTarget=false;inside.color=new Color(.06f,.14f,.22f);
   fill=GameUiSurface.Rect(hud,"EnergyFill",176,129,0,21).gameObject.EnsureComponent<Image>();fill.raycastTarget=false;fill.color=new Color(.05f,.72f,.90f);
   meter=ui.Label(hud,"0/100",20,Color.white,169,122,226,35);
   label=ui.Label(hud,"技能未激活",27,Color.white,151,43,260,74);
   // Instant-item actions are not yet migrated: never present these as usable buttons.
   ui.Art(hud,"energy_swap",529,43,115,129).color=new Color(1,1,1,.45f);
   ui.Art(hud,"energy_rain",657,43,114,129).color=new Color(1,1,1,.45f);
   ui.Art(hud,"energy_locked",785,43,115,125);
   graphic=GameUiSurface.Rect(ui.Root,"EnergyMotes",0,0,941,1672).gameObject.EnsureComponent<EnergyMoteGraphic>();
   graphic.raycastTarget=false;graphic.DrawMesh=DrawMotes;
   ui.Complete();state=combat.Energy.State;visual=state.energy;Refresh();
  }
  void Gain(int amount,Vector2 source,int count,bool bright){
   if(state!=combat.Energy.State){state=combat.Energy.State;motes.Clear();visual=state.energy-amount;}
   finishDelay=-1;count=Mathf.Max(1,count);var target=new Vector2(253,1559.5f);
   for(int i=0;i<count;i++){
    var start=source+new Vector2(Random.Range(-18f,18f),Random.Range(-15f,15f));
    motes.Add(new Mote{Start=start,Target=target,Control=(start+target)*.5f+new Vector2(Random.Range(-75f,75f),Random.Range(-130f,-55f)),Duration=Random.Range(.35f,.55f),Delay=i*.04f,Step=amount/count+(i<amount%count?1:0),Bright=bright});
   }
  }
  void Update(){
   if(ui==null)return;ui.CanvasObject.SetActive(combat.CampaignMode&&!combat.NavigationSuspended);
   if(state!=combat.Energy.State){ClearTrigger();state=combat.Energy.State;motes.Clear();finishDelay=-1;visual=state.energy;}
   if(motes.Count>0){
    for(int i=motes.Count-1;i>=0;i--){var mote=motes[i];mote.Age+=Time.deltaTime;if(mote.Age<mote.Delay)continue;
     float t=Mathf.Clamp01((mote.Age-mote.Delay)/mote.Duration);
     float e=t<.5f?Mathf.Pow(t*2,1.7f)*.5f:(1-Mathf.Pow(1-(t-.5f)*2,1.7f))*.5f+.5f;
     var p=(1-e)*(1-e)*mote.Start+2*(1-e)*e*mote.Control+e*e*mote.Target;
     mote.Trail.Insert(0,p);if(mote.Trail.Count>7)mote.Trail.RemoveAt(7);
     if(t>=1){visual=Mathf.Min(state.energy,visual+mote.Step);motes.RemoveAt(i);}
    }
    if(motes.Count==0){visual=state.energy;finishDelay=visual>=100?.24f:0;}
   }else if(finishDelay<0)visual=state.energy;
   if(finishDelay>=0){finishDelay-=Time.deltaTime;if(finishDelay<=0){finishDelay=-1;combat.Energy.FinishFx();}}
   graphic.SetVerticesDirty();Refresh();
  }
  void Refresh(){
   fill.rectTransform.sizeDelta=new Vector2(212*Mathf.Clamp01(visual/100f),21);meter.text=visual+"/100";
   string id=state.pending??"";
   if(id!=pendingId){if(pending)Destroy(pending.gameObject);pending=null;pendingId=id;if(id.Length>0)pending=ui.Art(hud,id,49,67,77,84);}
   inactive.enabled=id.Length==0;
   if(pending)pending.enabled=!triggering;
   int index=System.Array.IndexOf(SkillEnergy.Ids,id);
   label.text=index>=0?"下一次合成：待触发\n"+Names[index]:visual>=100?"能量已满\n等待选择印记":"技能未激活";
   label.fontSize=index>=0||visual>=100?20:27;
  }
  void DrawMotes(VertexHelper mesh){
   for(int i=0;i<imprintTrail.Count;i++){float strength=(i+1f)/imprintTrail.Count;EnergyMoteGraphic.Circle(mesh,imprintTrail[i],15*strength,new Color(.22f,.78f,1,.18f*strength*trailFade));EnergyMoteGraphic.Circle(mesh,imprintTrail[i],6.5f*strength,new Color(.7f,.95f,1,.7f*strength*trailFade));}
   foreach(var mote in motes){if(mote.Trail.Count==0)continue;
    for(int i=0;i<mote.Trail.Count;i++)EnergyMoteGraphic.Circle(mesh,mote.Trail[i],Mathf.Max(2,7-i),new Color(.25f,.9f,1,(1-i/(float)mote.Trail.Count)*.24f));
    var p=mote.Trail[0];EnergyMoteGraphic.Circle(mesh,p,mote.Bright?13:10,new Color(.42f,.96f,1,mote.Bright?.62f:.4f));
    EnergyMoteGraphic.Circle(mesh,p,mote.Bright?6.5f:5,new Color(.82f,.98f,1,.96f));EnergyMoteGraphic.Circle(mesh,p-new Vector2(2,2),2,Color.white);
   }
  }
  IEnumerator Trigger(Vector2 target){
   if(ui==null||!combat.Energy.HasPending)yield break;
   var captured=combat.Energy.State;triggering=true;trailFade=1;imprintTrail.Clear();
   flying=ui.Art(ui.Root,captured.pending,63,1487,77,84);flying.preserveAspect=true;GameUiSurface.CenterPivot(flying.rectTransform);
   Vector2 start=new Vector2(101.5f,1529);float arc=Mathf.Clamp(Vector2.Distance(start,target)*.12f,60,130),trailTimer=0;
   for(float age=0;age<.32f&&captured==combat.Energy.State;age+=Time.deltaTime){
    float t=Mathf.Clamp01(age/.32f),e=t<.5f?2*t*t:1-Mathf.Pow(-2*t+2,2)/2;var p=Vector2.Lerp(start,target,e);p.y-=Mathf.Sin(e*Mathf.PI)*arc;
    flying.rectTransform.anchoredPosition=new Vector2(p.x,-p.y);flying.rectTransform.localScale=Vector3.one*Mathf.Lerp(1,.62f,e);
    trailTimer+=Time.deltaTime;if(trailTimer>=.014f){trailTimer=0;imprintTrail.Add(p);if(imprintTrail.Count>13)imprintTrail.RemoveAt(0);}yield return null;
   }
   if(captured!=combat.Energy.State){ClearTrigger();yield break;}
   flying.rectTransform.anchoredPosition=new Vector2(target.x,-target.y);
   for(float age=0;age<.18f&&captured==combat.Energy.State;age+=Time.deltaTime){
    float t=Mathf.Clamp01(age/.1f),u=t-1;flying.rectTransform.localScale=Vector3.one*Mathf.LerpUnclamped(.62f,1.3f,1+2.70158f*u*u*u+1.70158f*u*u);
    flying.color=new Color(1,1,1,1-Mathf.Pow(Mathf.Clamp01(age/.14f),2));trailFade=1-Mathf.Pow(age/.18f,2);yield return null;
   }
   ClearTrigger();
  }
  void ClearTrigger(){if(flying)Destroy(flying.gameObject);flying=null;triggering=false;imprintTrail.Clear();}
  void OnDisable(){if(ui!=null&&ui.CanvasObject)ui.CanvasObject.SetActive(false);}
  void OnDestroy(){if(combat)combat.EnergyFxRequested-=Gain;var board=GetComponent<M1BoardDemo>();if(board)board.PlayPendingImprint=null;ui?.Dispose();}
 }
}
