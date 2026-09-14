using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
namespace MergeTo10.Runtime {
 public sealed class GameUiSurface:IDisposable {
  public readonly GameObject CanvasObject;public readonly RectTransform Root;public readonly Image Shade;
  readonly List<Sprite> sprites=new List<Sprite>();
  public GameUiSurface(string name,int order,float opacity,string prefabId=null){
   if(!EventSystem.current){var events=new GameObject("GameEventSystem",typeof(EventSystem),typeof(InputSystemUIInputModule));events.GetComponent<InputSystemUIInputModule>().AssignDefaultActions();}
   var template=PrefabSceneLibrary.Find(prefabId??name);
   if(template){
    CanvasObject=UnityEngine.Object.Instantiate(template);CanvasObject.name=name;
    CanvasObject.EnsureComponent<UiPrefabInstance>().BeginBinding();CanvasObject.SetActive(true);
    Shade=Rect(CanvasObject.transform,"Shade",0,0,0,0).GetComponent<Image>();
    Root=Rect(CanvasObject.transform,"DesignRoot",0,0,941,1672);
    Shade.color=new Color(0,0,0,opacity);return;
   }

   CanvasObject=new GameObject(name,typeof(RectTransform),typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));
   var canvas=CanvasObject.GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceOverlay;canvas.sortingOrder=order;
   var scaler=CanvasObject.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(941,1672);scaler.screenMatchMode=CanvasScaler.ScreenMatchMode.Expand;
   var shade=Rect(CanvasObject.transform,"Shade",0,0,0,0);shade.anchorMin=Vector2.zero;shade.anchorMax=Vector2.one;shade.offsetMin=shade.offsetMax=Vector2.zero;
   Shade=shade.gameObject.EnsureComponent<Image>();Shade.color=new Color(0,0,0,opacity);
   Root=Rect(CanvasObject.transform,"DesignRoot",0,0,941,1672);Root.anchorMin=Root.anchorMax=Root.pivot=Vector2.one*.5f;Root.anchoredPosition=Vector2.zero;
  }
  public void Complete(){CanvasObject.GetComponent<UiPrefabInstance>()?.CompleteBinding();}
  public static RectTransform Subtree(Transform parent,string id,string name,float x,float y,float width,float height){
   var prefab=PrefabSceneLibrary.Find(id);
   if(!prefab)return Rect(parent,name,x,y,width,height);
   var go=UnityEngine.Object.Instantiate(prefab,parent,false);go.name=name;
   go.EnsureComponent<UiPrefabInstance>().BeginBinding();
   var binding=go.GetComponent<PrefabUiNode>();if(binding)binding.Claimed=true;
   go.SetActive(true);return (RectTransform)go.transform;
  }
  public static RectTransform Rect(Transform parent,string name,float x,float y,float width,float height){
   string key=name+"@"+x.ToString("R",System.Globalization.CultureInfo.InvariantCulture)+","+y.ToString("R",System.Globalization.CultureInfo.InvariantCulture);
   foreach(var node in parent.GetComponentsInChildren<PrefabUiNode>(true)){
    if(node.transform==parent||node.Claimed||!node.Baked||node.BindingKey!=key)continue;
    var ancestor=node.transform.parent;bool belongs=true;
    while(ancestor&&ancestor!=parent){if(ancestor.GetComponent<PrefabUiNode>()){belongs=false;break;}ancestor=ancestor.parent;}
    if(!belongs||ancestor!=parent)continue;
    node.Claimed=true;node.gameObject.SetActive(true);var bound=(RectTransform)node.transform;if(bound.sizeDelta==node.BaseSize)bound.sizeDelta=new Vector2(width,height);return bound;
   }
   var rect=new GameObject(name,typeof(RectTransform)).GetComponent<RectTransform>();rect.SetParent(parent,false);rect.anchorMin=rect.anchorMax=rect.pivot=new Vector2(0,1);rect.anchoredPosition=new Vector2(x,-y);rect.sizeDelta=new Vector2(width,height);var binding=rect.gameObject.AddComponent<PrefabUiNode>();binding.BindingKey=key;binding.Claimed=true;return rect;
  }
  public Image Art(Transform parent,string key,float x,float y,float width,float height,float border=0){
   var texture=Resources.Load<Texture2D>("Campaign/"+key);if(!texture)throw new InvalidOperationException("Missing UI asset "+key);
   var sprite=Sprite.Create(texture,new UnityEngine.Rect(0,0,texture.width,texture.height),Vector2.one*.5f,100,0,SpriteMeshType.FullRect,Vector4.one*border);sprites.Add(sprite);
   var image=Rect(parent,"Art",x,y,width,height).gameObject.EnsureComponent<Image>();if(!image.GetComponent<PrefabUiNode>().Baked)image.name=key;image.sprite=sprite;image.raycastTarget=false;if(border>0)image.type=Image.Type.Sliced;return image;
  }
  public Text Label(Transform parent,string value,int size,Color color,float x,float y,float width,float height,int weight=700){
   var text=Rect(parent,"Label",x,y,width,height).gameObject.EnsureComponent<Text>();text.font=Resources.Load<Font>("Campaign/chapter_"+weight);text.text=value;text.fontSize=size;text.color=color;text.alignment=TextAnchor.MiddleCenter;text.raycastTarget=false;text.verticalOverflow=VerticalWrapMode.Overflow;return text;
  }
  public Image Region(Transform parent,string key,UnityEngine.Rect source,UnityEngine.Rect target){
   var texture=Resources.Load<Texture2D>("Campaign/"+key);if(!texture)throw new InvalidOperationException("Missing UI asset "+key);
   source.y=texture.height-source.y-source.height;var sprite=Sprite.Create(texture,source,Vector2.one*.5f,100);sprites.Add(sprite);
   var image=Rect(parent,"Region",target.x,target.y,target.width,target.height).gameObject.EnsureComponent<Image>();image.sprite=sprite;image.raycastTarget=false;return image;
  }
  public static void CenterPivot(RectTransform rect){if(rect.GetComponent<PrefabUiNode>()?.Baked==true)return;var size=rect.sizeDelta;rect.pivot=Vector2.one*.5f;rect.anchoredPosition+=new Vector2(size.x*.5f,-size.y*.5f);}
  public void Dispose(){if(CanvasObject){CanvasObject.SetActive(false);UnityEngine.Object.Destroy(CanvasObject);}foreach(var sprite in sprites)if(sprite)UnityEngine.Object.Destroy(sprite);sprites.Clear();}
 }
}
