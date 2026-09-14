using System;
using System.Linq;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using MergeTo10.Core;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class CrystalChoiceView:MonoBehaviour {
  M2BattleDemo combat;GameUiSurface ui;Material keyMaterial;Button confirm;Card[] cards;
  int selected=-1;bool locked,wasPaused;string[] ids;int[] levels;
  sealed class Card {public RectTransform Root,Inner;public GameObject Front,Back;public CanvasGroup Group;public Outline Border;public Vector2 Position;}
  public bool Visible=>ui!=null;public bool Interactable=>Visible&&!locked;
  void Awake(){combat=GetComponent<M2BattleDemo>();combat.GateChanged+=OnGate;}
  void OnGate(M2BattleDemo.ChapterGate gate){
   if(!isActiveAndEnabled)return;
   Hide();if(gate==M2BattleDemo.ChapterGate.CrystalReward&&!combat.BossRewardCommitted)Show();
  }
  void Show(){
   wasPaused=combat.Paused;combat.SetPaused(true);selected=-1;locked=true;
   ids=combat.CrystalChoices.ToArray();levels=ids.Select(id=>Mathf.Clamp(combat.Meta.State.Levels[Array.IndexOf(MetaProgress.Cards,id)]+1,1,5)).ToArray();
   ui=new GameUiSurface("CrystalChoiceCanvas",1100,0);keyMaterial=new Material(Resources.Load<Shader>("Campaign/UIGreenKey"));
   var title=ui.Art(ui.Root,"choice_title",34,270,873,176);title.preserveAspect=true;
   OutlineText(ui.Label(title.transform,"选择合成印记",64,Color.white,190,4,493,145,900),10,new Color(.43f,.18f,.03f));
   ui.Label(title.transform,"◆",26,new Color(1,.98f,.78f),145,51,42,42,900);ui.Label(title.transform,"◆",26,new Color(1,.98f,.78f),686,51,42,42,900);
   var rules=CardRules.Load();cards=new Card[ids.Length];
   for(int i=0;i<ids.Length;i++){
    int index=i;float x=(941-(ids.Length*284+(ids.Length-1)*16))*.5f+i*300;
    var root=GameUiSurface.Rect(ui.Root,"Card_"+i,x,557,284,530);GameUiSurface.CenterPivot(root);
    var inner=GameUiSurface.Rect(root,"CardTransform",0,0,225,420);GameUiSurface.CenterPivot(inner);inner.anchoredPosition=new Vector2(142,-265);inner.localScale=Vector3.one*(530f/420);
    var front=GameUiSurface.Rect(inner,"Front",0,0,225,420);
    var face=ui.Art(front,"choice_front",0,0,225,420);var border=face.gameObject.EnsureComponent<Outline>();border.effectColor=new Color(1,.84f,.25f);border.effectDistance=Vector2.one*5;border.enabled=false;
    var icon=ui.Art(front,ids[i],54,7,117,110);icon.preserveAspect=true;
    var definition=rules.cards.First(c=>c.id==ids[i]);int nameSize=definition.item_name.Length<=4?32:definition.item_name.Length<=6?29:25;
    OutlineText(ui.Label(front,definition.item_name,nameSize,new Color(.23f,.075f,.018f),12,128,201,52,900),3,new Color(1,.96f,.84f));
    for(int s=0;s<5;s++)ui.Art(front,s<levels[i]?"choice_star":"choice_star_slot",16+s*41,222,29,29).preserveAspect=true;
    int longest=definition.description.Split('\n').Max(line=>line.Length);int font=longest<=9?18:longest<=11?17:15;
    var description=ui.Label(front,definition.description,font,new Color(.20f,.075f,.035f),16,266,193,125);description.alignment=TextAnchor.UpperCenter;description.verticalOverflow=VerticalWrapMode.Truncate;
    if(!combat.Meta.State.SeenCards[Array.IndexOf(MetaProgress.Cards,ids[i])]){var badge=ui.Art(front,"choice_new",174,-10,56,56);badge.preserveAspect=true;OutlineText(ui.Label(badge.transform,"新",24,Color.white,0,0,56,56,900),4,new Color(.14f,.055f,.02f));}
    var back=ui.Art(inner,"choice_back",0,0,225,420);back.material=keyMaterial;back.preserveAspect=true;
    var hit=root.gameObject.EnsureComponent<Image>();hit.color=Color.clear;hit.raycastTarget=true;var button=root.gameObject.EnsureComponent<Button>();button.targetGraphic=hit;button.transition=Selectable.Transition.None;button.onClick.AddListener(()=>Select(index));
    cards[i]=new Card{Root=root,Inner=inner,Front=front.gameObject,Back=back.gameObject,Group=root.gameObject.EnsureComponent<CanvasGroup>(),Border=border,Position=root.anchoredPosition};front.gameObject.SetActive(false);
   }
   var confirmArt=ui.Art(ui.Root,"choice_confirm",296.5f,1193,348,114);confirmArt.raycastTarget=true;GameUiSurface.CenterPivot(confirmArt.rectTransform);
   confirm=confirmArt.gameObject.EnsureComponent<Button>();confirm.targetGraphic=confirmArt;confirm.onClick.AddListener(Confirm);
   OutlineText(ui.Label(confirmArt.transform,"确定",52,Color.white,0,0,348,114,900),8,new Color(.48f,.18f,.02f));confirm.interactable=false;
   ui.Complete();combat.MarkCrystalOffersSeen();StartCoroutine(Intro());
  }
  static void OutlineText(Text text,int size,Color color){var outline=text.gameObject.EnsureComponent<Outline>();outline.effectDistance=new Vector2(2,2);outline.effectColor=color;}
  static float Back(float t){float u=t-1;return 1+2.70158f*u*u*u+1.70158f*u*u;}
  IEnumerator Intro(){
   float elapsed=0;float total=.03f+(cards.Length-1)*.06f+.36f+.06f;
   while(elapsed<total&&Visible){
    ui.Shade.color=new Color(0,0,0,180f/255*Mathf.Clamp01(elapsed/.16f));
    for(int i=0;i<cards.Length;i++){
     var card=cards[i];float age=elapsed-.03f-i*.06f,t=Mathf.Clamp01(age/.22f);card.Group.alpha=t;
     card.Root.anchoredPosition=card.Position+new Vector2(0,-38*(1-Back(t)));card.Root.localScale=Vector3.one*Mathf.LerpUnclamped(.88f,1,Back(t));
     bool front=age>=.18f;card.Front.SetActive(front);card.Back.SetActive(!front);
     float phase=Mathf.Clamp01((front?age-.18f:age)/.18f),ease=1-Mathf.Pow(1-phase,3),width=front?ease:1-ease;
     card.Inner.localScale=new Vector3(width,1,1)*(530f/420);
    }
    elapsed+=Time.unscaledDeltaTime;yield return null;
   }
   if(!Visible)yield break;foreach(var card in cards){card.Root.localScale=Vector3.one;card.Inner.localScale=Vector3.one*(530f/420);card.Root.anchoredPosition=card.Position;card.Group.alpha=1;card.Front.SetActive(true);card.Back.SetActive(false);}locked=false;
  }
  public void Select(int index){if(!Interactable||index<0||index>=cards.Length)return;selected=index;confirm.interactable=true;foreach(var card in cards)card.Border.enabled=card==cards[index];StartCoroutine(SelectMotion(index));}
  IEnumerator SelectMotion(int choice){float elapsed=0;var starts=cards.Select(c=>c.Root.localScale.x).ToArray();var positions=cards.Select(c=>c.Root.anchoredPosition).ToArray();
   while(Visible&&!locked&&selected==choice&&elapsed<.13f){float t=Mathf.Clamp01(elapsed/.13f);for(int i=0;i<cards.Length;i++){bool active=i==choice;cards[i].Root.localScale=Vector3.one*Mathf.LerpUnclamped(starts[i],active?1.045f:.96f,Back(t));cards[i].Root.anchoredPosition=Vector2.Lerp(positions[i],cards[i].Position+new Vector2(0,active?11:0),t);cards[i].Group.alpha=active?1:.82f;}elapsed+=Time.unscaledDeltaTime;yield return null;}
  }
  public void Confirm(){if(!Interactable||selected<0)return;locked=true;confirm.interactable=false;StartCoroutine(Finish());}
  IEnumerator Finish(){
   var chosen=cards[selected];var start=chosen.Root.anchoredPosition;float elapsed=0;
   while(Visible&&elapsed<.54f){float t=Mathf.Clamp01(elapsed/.42f);chosen.Root.anchoredPosition=Vector2.Lerp(start,new Vector2(337.2f,-565.3f),t*t);chosen.Root.localScale=Vector3.one*Mathf.Lerp(1.045f,.12f,t);chosen.Group.alpha=elapsed<=.42f?1:1-(elapsed-.42f)/.12f;
    foreach(var other in cards)if(other!=chosen)other.Group.alpha=Mathf.Max(0,1-elapsed/.12f);elapsed+=Time.unscaledDeltaTime;yield return null;}
   if(!Visible)yield break;
   if(!combat.ChooseCrystalReward(ids[selected],levels[selected])){Hide();yield break;}
   elapsed=0;while(Visible&&elapsed<.18f){ui.Shade.color=new Color(0,0,0,180f/255*(1-elapsed/.18f));elapsed+=Time.unscaledDeltaTime;yield return null;}
   Hide();combat.ContinueCampaign();
  }
  void Hide(){StopAllCoroutines();if(ui!=null){ui.Dispose();ui=null;combat.SetPaused(wasPaused);}if(keyMaterial)Destroy(keyMaterial);keyMaterial=null;}
  void OnDisable(){Hide();}
  void OnDestroy(){if(combat)combat.GateChanged-=OnGate;Hide();}
 }
}
