using System;
using System.Linq;
using System.Collections;
using MergeTo10.Core;
using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class ImprintChoiceView:MonoBehaviour {
  sealed class Card {public RectTransform Root;public Image Icon;public Outline Outline;public CanvasGroup Group;public Vector2 Position;}
  M2BattleDemo combat;M1BoardDemo board;GameUiSurface ui;Card[] cards;string[] ids;int[] levels;int selected=-1;bool locked,wasPaused;
  Button confirm;CanvasGroup content;Material cleanup;
  SkillEnergyState openedState;
  public bool Visible=>ui!=null;public bool Interactable=>Visible&&!locked;
  public string[] Choices=>ids==null?Array.Empty<string>():(string[])ids.Clone();
  void Awake(){combat=GetComponent<M2BattleDemo>();board=GetComponent<M1BoardDemo>();combat.GateChanged+=OnGate;combat.EnergyChoicesEnabled=true;}
  void Update(){
   if(Visible&&openedState!=combat.Energy.State){Hide();return;}
   if(!Visible&&combat.Ready&&combat.CampaignMode&&!combat.NavigationSuspended&&!combat.Paused&&!board.Busy&&!combat.Frozen&&combat.Durability>0&&
    combat.Gate==M2BattleDemo.ChapterGate.None&&combat.AllowsEnergyChoice&&combat.Energy.ChoiceReady)Show();
  }
  void OnGate(M2BattleDemo.ChapterGate gate){if(gate!=M2BattleDemo.ChapterGate.None)Hide();}
  void Show(){
   openedState=combat.Energy.State;wasPaused=combat.Paused;combat.SetPaused(true);locked=true;selected=-1;
   var pool=SkillEnergy.Ids.ToList();ids=new string[3];for(int i=0;i<3;i++){int n=UnityEngine.Random.Range(0,pool.Count);ids[i]=pool[n];pool.RemoveAt(n);}
   levels=ids.Select(id=>Mathf.Clamp(combat.Meta.State.Levels[Array.IndexOf(MetaProgress.Cards,id)]+1,1,5)).ToArray();
   ui=new GameUiSurface("ImprintChoiceCanvas",1100,0);cleanup=new Material(Resources.Load<Shader>("Campaign/UIImprintCleanup"));
   var contentRoot=GameUiSurface.Rect(ui.Root,"Content",0,0,941,1672);content=contentRoot.gameObject.EnsureComponent<CanvasGroup>();
   var left=ui.Art(contentRoot,"imprint_title",236,380,108,45);left.preserveAspect=true;GameUiSurface.CenterPivot(left.rectTransform);left.rectTransform.localScale=new Vector3(-1,1,1);
   ui.Art(contentRoot,"imprint_title",604,380,108,45).preserveAspect=true;
   Label(contentRoot,"道具选择",54,344,350,250,104,7);
   cards=new Card[3];var rules=CardRules.Load();
   for(int i=0;i<3;i++){
    int index=i;var root=GameUiSurface.Rect(contentRoot,"Imprint_"+i,34.5f+295*i,527,282,598);GameUiSurface.CenterPivot(root);
    var face=ui.Art(root,"imprint_card",0,0,282,598,36);face.material=cleanup;
    var outline=face.gameObject.EnsureComponent<Outline>();outline.effectDistance=Vector2.one*6;outline.effectColor=new Color(.28f,.9f,1);outline.enabled=false;
    Label(root,rules.cards.First(c=>c.id==ids[i]).item_name,30,20,14,242,76,5);
    var icon=ui.Art(root,ids[i],44,128,194,202);icon.preserveAspect=true;
    string copy=Description(ids[i],levels[i]);int longest=copy.Split('\n').Max(line=>line.Length),compact=copy.Replace("\n","").Length;
    int font=copy.Count(c=>c=='\n')>=2||compact>=25||longest>=12?18:compact>=18||longest>=10?19:21;
    var description=ui.Label(root,copy,font,new Color(.035f,.045f,.065f),34,378,214,140);description.verticalOverflow=VerticalWrapMode.Truncate;
    if(!combat.Meta.State.SeenCards[Array.IndexOf(MetaProgress.Cards,ids[i])]){var badge=ui.Art(root,"imprint_new",216,-18,76,72);badge.preserveAspect=true;Label(badge.transform,"新",34,0,0,76,72,5);}
    var hit=root.gameObject.EnsureComponent<Image>();hit.color=Color.clear;var button=root.gameObject.EnsureComponent<Button>();button.targetGraphic=hit;button.transition=Selectable.Transition.None;button.onClick.AddListener(()=>Select(index));
    if(i>=1){var ad=ui.Art(root,"imprint_ad",20,614,220,64);Label(ad.transform,"▶  看广告解锁",22,0,0,220,64,4);}
    cards[i]=new Card{Root=root,Icon=icon,Outline=outline,Group=root.gameObject.EnsureComponent<CanvasGroup>(),Position=root.anchoredPosition};
   }
   var confirmArt=ui.Art(contentRoot,"imprint_confirm",319,1205,303,110);confirmArt.raycastTarget=true;
   confirm=confirmArt.gameObject.EnsureComponent<Button>();confirm.targetGraphic=confirmArt;confirm.onClick.AddListener(Confirm);confirm.interactable=false;
   Label(confirmArt.transform,"确定",52,0,0,303,110,7);ui.Complete();StartCoroutine(Intro());
  }
  void Label(Transform parent,string value,int font,float x,float y,float w,float h,int border){
   var text=ui.Label(parent,value,font,Color.white,x,y,w,h,900);var outline=text.gameObject.EnsureComponent<Outline>();outline.effectColor=new Color(.02f,.04f,.09f);outline.effectDistance=Vector2.one*border;
  }
  static string Description(string id,int q){
   switch(id){
    case "ascension_hammer":return "下一次合成结果\n提升"+(q>=4?2:1)+"级";
    case "unity_dial":return "将其余非最高级方块\n统一为本次合成前数字";
    case "fate_shuffler":return "重新排列棋盘，并保证\n至少一组可合成方块";
    case "twin_mold":return "使"+(q>=4?2:1)+"个相邻方块变为\n本次合成结果数字";
    case "castle_cannon":return "对最前方怪物造成\n"+(130+q*30)+"%基础攻击伤害";
    default:return "攻击前方"+new[]{2,2,3,3,4}[q-1]+"只怪物\n造成"+(60+q*10)+"%伤害\n并附加燃烧";
   }
  }
  static float Back(float t){float u=t-1;return 1+2.70158f*u*u*u+1.70158f*u*u;}
  IEnumerator Intro(){
   for(float age=0;Visible&&age<.48f;age+=Time.unscaledDeltaTime){
    ui.Shade.color=new Color(0,0,0,180f/255*Mathf.Clamp01(age/.18f));content.alpha=Mathf.Clamp01(age/.22f);
    for(int i=0;i<3;i++){float t=Mathf.Clamp01((age-.05f-i*.065f)/.25f);cards[i].Group.alpha=Mathf.Clamp01((age-.05f-i*.065f)/.2f);cards[i].Root.anchoredPosition=cards[i].Position+new Vector2(0,-38*(1-Back(t)));cards[i].Root.localScale=Vector3.one*Mathf.LerpUnclamped(.88f,1,Back(t));}yield return null;
   }
   if(!Visible)yield break;foreach(var card in cards){card.Root.anchoredPosition=card.Position;card.Root.localScale=Vector3.one;card.Group.alpha=1;}content.alpha=1;locked=false;
  }
  public void Select(int index){
   if(!Interactable||index<0||index>=3)return;selected=index;confirm.interactable=true;
   for(int i=0;i<3;i++)cards[i].Outline.enabled=i==selected;
   cards[index].Root.SetAsLastSibling();StartCoroutine(Selection(index));
  }
  IEnumerator Selection(int index){
   var starts=cards.Select(c=>c.Root.localScale.x).ToArray();
   for(float age=0;Visible&&!locked&&selected==index&&age<.13f;age+=Time.unscaledDeltaTime){for(int i=0;i<3;i++)cards[i].Root.localScale=Vector3.one*Mathf.LerpUnclamped(starts[i],i==index?1.025f:1,Back(age/.13f));yield return null;}
   if(Visible&&!locked&&selected==index)for(int i=0;i<3;i++)cards[i].Root.localScale=Vector3.one*(i==index?1.025f:1);
  }
  public void Confirm(){if(!Interactable||selected<0)return;locked=true;confirm.interactable=false;StartCoroutine(Commit());}
  IEnumerator Commit(){
   var chosen=cards[selected];var start=ui.Root.InverseTransformPoint(chosen.Icon.transform.TransformPoint(chosen.Icon.rectTransform.rect.center));
   // Root pivot is centered, while child placement is top-left.
   Vector2 from=new Vector2(start.x+470.5f,836-start.y),target=new Vector2(101.5f,1529);
   var delta=target-from;var control=Vector2.Lerp(from,target,.46f);control.x=Mathf.Clamp(control.x+Mathf.Clamp(Mathf.Abs(delta.y)*.14f,85,175),70,871);control.y=from.y+delta.y*.38f;
   var fly=ui.Art(ui.Root,ids[selected],from.x-97,from.y-101,194,202);fly.preserveAspect=true;GameUiSurface.CenterPivot(fly.rectTransform);chosen.Icon.enabled=false;
   for(float age=0;Visible&&age<.46f;age+=Time.unscaledDeltaTime){
    float t=Mathf.Clamp01(age/.46f),e=t<.5f?2*t*t:1-Mathf.Pow(-2*t+2,2)/2;
    var p=(1-e)*(1-e)*from+2*(1-e)*e*control+e*e*target;fly.rectTransform.anchoredPosition=new Vector2(p.x,-p.y);fly.rectTransform.localScale=Vector3.one*Mathf.Lerp(1,.45f,Mathf.SmoothStep(0,1,e));
    content.alpha=Mathf.Lerp(1,.1f,Mathf.Clamp01(age/.18f));yield return null;
   }
   if(!Visible)yield break;if(openedState!=combat.Energy.State){Hide();yield break;}fly.gameObject.SetActive(false);
   if(!combat.CommitImprintChoice(ids[selected],levels[selected])){Hide();yield break;}
   for(float age=0;Visible&&age<.18f;age+=Time.unscaledDeltaTime){ui.Shade.color=new Color(0,0,0,180f/255*(1-age/.18f));yield return null;}
   Hide();if(combat.Campaign.State.AwaitingReward)combat.ContinueCampaign();
  }
  void Hide(){StopAllCoroutines();if(ui!=null){ui.Dispose();ui=null;combat.SetPaused(wasPaused);}if(cleanup)Destroy(cleanup);cleanup=null;}
  void OnDisable(){Hide();}
  void OnDestroy(){if(combat){combat.GateChanged-=OnGate;combat.EnergyChoicesEnabled=false;}Hide();}
 }
}
