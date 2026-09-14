using System;
using UnityEngine;
using UnityEngine.UI;

namespace MergeTo10.Runtime {
 // Stable binding identity is independent of the display name and editable transform.
 // Baselines distinguish designer changes from data-driven text, icons and states.
 [DisallowMultipleComponent]
 public sealed class PrefabUiNode : MonoBehaviour {
  [HideInInspector] public string BindingKey;
  [HideInInspector] public bool Baked;
  [HideInInspector] public Color BaseColor;
  [HideInInspector] public Vector2 BaseSize;
  [HideInInspector] public Sprite BaseSprite;
  [HideInInspector] public int BaseFontSize;
  [HideInInspector] public Font BaseFont;
  [NonSerialized] public bool Claimed;
  Action restore;
  public void RecordBaseline() {
   Baked=true;BaseSize=((RectTransform)transform).sizeDelta;
   var graphic=GetComponent<Graphic>();if(graphic)BaseColor=graphic.color;
   var image=GetComponent<Image>();if(image)BaseSprite=image.sprite;
   var text=GetComponent<Text>();if(text){BaseFontSize=text.fontSize;BaseFont=text.font;}
  }
  public void CaptureAuthoring() {
   if(!Baked)return;
   var r=(RectTransform)transform;
   var min=r.anchorMin;var max=r.anchorMax;var pivot=r.pivot;var position=r.anchoredPosition3D;var size=r.sizeDelta;var scale=r.localScale;var rotation=r.localRotation;
   restore=()=>{if(!r)return;r.anchorMin=min;r.anchorMax=max;r.pivot=pivot;r.anchoredPosition3D=position;if(size!=BaseSize)r.sizeDelta=size;r.localScale=scale;r.localRotation=rotation;};
   var g=GetComponent<Graphic>();if(g&&g.color!=BaseColor){var color=g.color;restore+=()=>g.color=color;}
   var image=GetComponent<Image>();if(image&&image.sprite!=BaseSprite){var sprite=image.sprite;restore+=()=>image.sprite=sprite;}
   var text=GetComponent<Text>();if(text){
    if(text.fontSize!=BaseFontSize){int fontSize=text.fontSize;restore+=()=>text.fontSize=fontSize;}
    if(text.font!=BaseFont){var font=text.font;restore+=()=>text.font=font;}
   }
  }
  public void RestoreAuthoring(){if(Claimed)restore?.Invoke();restore=null;}
 }
}
