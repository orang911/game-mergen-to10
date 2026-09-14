using System;
using System.Collections.Generic;
using UnityEngine;
using MergeTo10.Core;
namespace MergeTo10.Runtime
{
 public sealed class DamageFeedbackLayer:MonoBehaviour
 {
  sealed class Entry{public TextMesh Text,Shadow;public Vector3 Origin;public float Age;public Color Color;}
  sealed class Flash{public SpriteRenderer View;public float Age;}
  readonly List<Flash> flashes=new List<Flash>();Font annihilationFont;Sprite white;Texture2D whiteTexture;Material flashMaterial;
  public int ActiveFlashes=>flashes.Count;
  readonly List<Entry> entries=new List<Entry>();Font font;
  public int ActiveCount=>entries.Count;
  public int TotalPlayed{get;private set;}
  public static string FormatDamage(double damage)=>"-"+Math.Max(1,(long)Math.Floor(damage+.5));
  public static float Alpha(float age)=>1-Mathf.Clamp01((age-.12f)/.42f);
  public void Setup(){
   font=Resources.Load<Font>("M2Art/resonance_default");annihilationFont=Resources.Load<Font>("M2Art/annihilation_text");
   whiteTexture=new Texture2D(1,1);whiteTexture.SetPixel(0,0,Color.white);whiteTexture.Apply();
   white=Sprite.Create(whiteTexture,new Rect(0,0,1,1),Vector2.one*.5f,100);
   flashMaterial=new Material(Resources.Load<Shader>("M1Art/ParitySprite"));
  }
  public static float FlashScale(float age)=>Mathf.Lerp(.48f,1.5f,age/.16f);
  public void PlayAnnihilation(Vector2 monsterCenter){
   PlayText("湮灭！",monsterCenter+new Vector2(0,-54),new Color(.96f,.84f,1),28,annihilationFont);
   var go=new GameObject("AnnihilationFlash");go.transform.SetParent(transform,false);
   var view=go.AddComponent<SpriteRenderer>();view.sprite=white;view.sharedMaterial=flashMaterial;view.sortingOrder=235;
   view.transform.localPosition=LayoutMapper.World(monsterCenter);
   var flash=new Flash{View=view};flashes.Add(flash);PresentFlash(flash);
  }
  public void Play(double damage,Vector2 monsterCenter)
  {
   if(damage<=0)return;
   PlayText(FormatDamage(damage),monsterCenter+new Vector2(0,-48),new Color(1,.28f,.25f),22,font);
  }
  void PlayText(string content,Vector2 position,Color color,int size,Font textFont){
   var go=new GameObject("DamageNumber");go.transform.SetParent(transform,false);
   var text=go.AddComponent<TextMesh>();text.font=textFont;text.fontSize=size*2;text.characterSize=.05f;
   text.anchor=TextAnchor.MiddleCenter;text.text=content;text.color=color;
   var r=text.GetComponent<MeshRenderer>();r.sharedMaterial=textFont.material;r.sortingOrder=240;
   var shadowGo=new GameObject("Shadow");shadowGo.transform.SetParent(go.transform,false);
   shadowGo.transform.localPosition=new Vector3(.02f,-.02f,0);
   var shadow=shadowGo.AddComponent<TextMesh>();shadow.font=textFont;shadow.fontSize=size*2;shadow.characterSize=.05f;
   shadow.anchor=text.anchor;shadow.text=text.text;shadow.color=new Color(.08f,.04f,.12f,.95f);
   var sr=shadow.GetComponent<MeshRenderer>();sr.sharedMaterial=textFont.material;sr.sortingOrder=239;
   var e=new Entry{Text=text,Shadow=shadow,Origin=LayoutMapper.World(position),Color=color};
   entries.Add(e);TotalPlayed++;Present(e);
  }
  void Present(Entry e){
   float t=Mathf.Clamp01(e.Age/.42f);
   e.Text.transform.localPosition=e.Origin+Vector3.up*(.28f*(1-(1-t)*(1-t)));
   e.Text.transform.localScale=Vector3.one*Mathf.Lerp(.75f,1.06f,e.Age/.12f);
   var color=e.Color;color.a=Alpha(e.Age);e.Text.color=color;e.Shadow.color=new Color(.08f,.04f,.12f,.95f*Alpha(e.Age));
  }
  void PresentFlash(Flash f){M1Art.SetSize(f.View,Vector2.one*(128*FlashScale(f.Age)));f.View.color=new Color(.95f,.84f,1,.92f*(1-Mathf.Clamp01(f.Age/.16f)));}
  void Update(){
   for(int i=entries.Count-1;i>=0;i--){var e=entries[i];e.Age+=Time.deltaTime;if(e.Age>=.54f){Destroy(e.Text.gameObject);entries.RemoveAt(i);}else Present(e);}
   for(int i=flashes.Count-1;i>=0;i--){var f=flashes[i];f.Age+=Time.deltaTime;if(f.Age>=.16f){Destroy(f.View.gameObject);flashes.RemoveAt(i);}else PresentFlash(f);}
  }
  public void Clear(){foreach(var e in entries)if(e.Text){e.Text.gameObject.SetActive(false);Destroy(e.Text.gameObject);}entries.Clear();foreach(var f in flashes)if(f.View){f.View.gameObject.SetActive(false);Destroy(f.View.gameObject);}flashes.Clear();}
  void OnDestroy(){Clear();if(white)Destroy(white);if(whiteTexture)Destroy(whiteTexture);if(flashMaterial)Destroy(flashMaterial);}
 }
}
