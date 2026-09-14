using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
namespace MergeTo10.Runtime
{
 // Original chapter_node_complete_modal.gd geometry, artwork and intro timing.
 // This view handles node-complete only; the chapter-complete/home flow is separate.
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class ChapterNodeView:MonoBehaviour {
  M2BattleDemo combat;GameObject canvasObject;RectTransform content;CanvasGroup group;
  readonly List<Sprite> sprites=new List<Sprite>();Button continueButton;bool submitted;
  public bool Visible=>canvasObject&&canvasObject.activeSelf;
  void Awake(){combat=GetComponent<M2BattleDemo>();combat.GateChanged+=OnGate;}
  void OnGate(M2BattleDemo.ChapterGate gate){
   if(!isActiveAndEnabled)return;
   Hide();if(gate!=M2BattleDemo.ChapterGate.NodeComplete)return;
   Build(combat.Campaign.Current.node_id);StartCoroutine(Intro());
  }
  RectTransform Rect(Transform parent,string name,float x,float y,float width,float height){
   return GameUiSurface.Rect(parent,name,x,y,width,height);
  }
  Image Art(Transform parent,string name,string key,float x,float y,float width,float height,bool sliced=false){
   var texture=Resources.Load<Texture2D>("Campaign/"+key);if(!texture)throw new InvalidOperationException("Missing chapter UI: "+key);
   var sprite=Sprite.Create(texture,new UnityEngine.Rect(0,0,texture.width,texture.height),Vector2.one*.5f,100,0,SpriteMeshType.FullRect,sliced?Vector4.one*12:Vector4.zero);sprites.Add(sprite);
   var image=Rect(parent,name,x,y,width,height).gameObject.EnsureComponent<Image>();image.sprite=sprite;image.type=sliced?Image.Type.Sliced:Image.Type.Simple;image.raycastTarget=false;return image;
  }
  Text Label(Transform parent,string value,int size,int weight,Color color,float x,float y,float width,float height,bool outline){
   var label=Rect(parent,"Text",x,y,width,height).gameObject.EnsureComponent<Text>();label.font=Resources.Load<Font>("Campaign/chapter_"+weight);
   if(!label.font)throw new InvalidOperationException("Missing packaged chapter font");
   label.text=value;label.fontSize=size;label.color=color;label.alignment=TextAnchor.MiddleCenter;label.raycastTarget=false;
   label.horizontalOverflow=HorizontalWrapMode.Wrap;label.verticalOverflow=VerticalWrapMode.Overflow;
   if(outline){var edge=label.gameObject.EnsureComponent<Outline>();edge.effectColor=new Color(.04f,.10f,.24f);edge.effectDistance=Vector2.one;}
   return label;
  }
  void Build(string node){
   submitted=false;
   if(!EventSystem.current){var events=new GameObject("ChapterEventSystem",typeof(EventSystem),typeof(InputSystemUIInputModule));events.GetComponent<InputSystemUIInputModule>().AssignDefaultActions();}
   var template=PrefabSceneLibrary.Find("ChapterNodeCanvas");
   canvasObject=template?Instantiate(template):new GameObject("ChapterNodeCanvas",typeof(RectTransform),typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));
   canvasObject.name="ChapterNodeCanvas";if(template)canvasObject.EnsureComponent<UiPrefabInstance>().BeginBinding();canvasObject.SetActive(true);
   var canvas=canvasObject.GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceOverlay;canvas.sortingOrder=1000;
   var scaler=canvasObject.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(941,1672);scaler.screenMatchMode=CanvasScaler.ScreenMatchMode.Expand;
   var shade=Rect(canvasObject.transform,"FullScreenShade",0,0,0,0);shade.anchorMin=Vector2.zero;shade.anchorMax=Vector2.one;shade.offsetMin=shade.offsetMax=Vector2.zero;
   shade.gameObject.EnsureComponent<Image>().color=new Color(.01f,.035f,.025f,.70f);
   var design=Rect(canvasObject.transform,"DesignRoot",0,0,941,1672);design.anchorMin=design.anchorMax=design.pivot=Vector2.one*.5f;design.anchoredPosition=Vector2.zero;
   content=Rect(design,"Content",115.5f,480,710,610);content.pivot=Vector2.one*.5f;content.anchoredPosition=new Vector2(470.5f,-785);
   group=content.gameObject.EnsureComponent<CanvasGroup>();
   Art(content,"Panel","node_panel",0,70,710,514,true);
   var title=Art(content,"TitleBar","node_title",8,0,694,130);
   Label(title.transform,node+" 完成",52,900,Color.white,70,8,554,112,true);
   var divider=Art(content,"CrystalDivider","node_divider",13.5f,170,683,137);divider.preserveAspect=true;
   Label(content,"水晶、棋盘与能量状态将带入下一关。",30,700,new Color(.035f,.14f,.34f),50,315,610,82,false);
   var buttonArt=Art(content,"ContinueButton","node_button",100,410,510,140);buttonArt.raycastTarget=true;
   buttonArt.rectTransform.pivot=Vector2.one*.5f;buttonArt.rectTransform.anchoredPosition=new Vector2(355,-480);
   continueButton=buttonArt.gameObject.EnsureComponent<Button>();continueButton.targetGraphic=buttonArt;
   continueButton.transition=Selectable.Transition.None;
   var trigger=buttonArt.gameObject.EnsureComponent<EventTrigger>();
   var down=new EventTrigger.Entry{eventID=EventTriggerType.PointerDown};down.callback.AddListener(_=>{if(!submitted){buttonArt.color=new Color(.92f,.82f,.66f);buttonArt.rectTransform.localScale=Vector3.one*.96f;}});trigger.triggers.Add(down);
   var up=new EventTrigger.Entry{eventID=EventTriggerType.PointerUp};up.callback.AddListener(_=>{buttonArt.color=Color.white;buttonArt.rectTransform.localScale=Vector3.one;});trigger.triggers.Add(up);
   Label(buttonArt.transform,"继续前进",44,900,new Color(1,.97f,.86f),0,0,510,140,true).GetComponent<Outline>().effectColor=new Color(.24f,.10f,.025f);
   continueButton.onClick.AddListener(Submit);canvasObject.GetComponent<UiPrefabInstance>()?.CompleteBinding();
  }
  public void Submit(){if(submitted||!Visible)return;submitted=true;continueButton.interactable=false;if(!combat.ContinueCampaign()&&continueButton){submitted=false;continueButton.interactable=true;}}
  IEnumerator Intro(){float elapsed=0;while(elapsed<.22f&&Visible){
   float t=Mathf.Clamp01(elapsed/.22f),u=t-1;float back=1+2.70158f*u*u*u+1.70158f*u*u;
   content.localScale=Vector3.one*Mathf.LerpUnclamped(.9f,1,back);group.alpha=Mathf.Clamp01(elapsed/.16f);elapsed+=Time.unscaledDeltaTime;yield return null;
  }if(Visible){content.localScale=Vector3.one;group.alpha=1;}}
  void Hide(){StopAllCoroutines();if(canvasObject){canvasObject.SetActive(false);Destroy(canvasObject);}foreach(var sprite in sprites)if(sprite)Destroy(sprite);sprites.Clear();canvasObject=null;}
  void OnDisable(){Hide();}
  void OnDestroy(){if(combat)combat.GateChanged-=OnGate;Hide();}
 }
}
