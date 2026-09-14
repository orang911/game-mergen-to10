using System.Collections;
using System.Collections.Generic;
using MergeTo10.Core;
using UnityEngine;
namespace MergeTo10.Runtime
{
 public sealed class M1MergeFeedback:MonoBehaviour
 {
  readonly List<Sprite> frames=new List<Sprite>();readonly List<GameObject> effects=new List<GameObject>();
  Transform stage;M1Art art;Coroutine shake;
  public void Setup(Transform layer,M1Art assets)
  {
   stage=layer;art=assets;var texture=Resources.Load<Texture2D>("M1Art/merge_sheet");
   for(int i=0;i<13;i++)frames.Add(Sprite.Create(texture,new Rect((i%4)*200,texture.height-(i/4+1)*200,200,200),Vector2.one*.5f,100,0,SpriteMeshType.FullRect));
  }
  public void Play(Vector2 local,int count)
  {
   StartCoroutine(Burst(LayoutMapper.BoardToDesign(local+Vector2.one*58)));
   if(shake!=null)StopCoroutine(shake);shake=StartCoroutine(Shake(count));
  }
  IEnumerator Burst(Vector2 center)
  {
   var go=new GameObject("MergeBurst");effects.Add(go);go.transform.SetParent(stage,false);go.transform.localPosition=LayoutMapper.World(center);
   var r=go.AddComponent<SpriteRenderer>();r.sharedMaterial=art.Material;r.sortingOrder=100;r.sprite=frames[0];M1Art.SetSize(r,Vector2.one*209);
   for(int i=1;i<13;i++){yield return new WaitForSeconds(.02f);r.sprite=frames[i];}
   effects.Remove(go);Destroy(go);
  }
  IEnumerator Shake(int count)
  {
   float h=count>=6?12:count>=4?9:6,v=h*.34f,d=count>=6?.18f:count>=4?.15f:.12f;
   var offsets=new[]{new Vector2(h,-v),new Vector2(-h*.76f,v*.72f),new Vector2(h*.52f,-v*.5f),new Vector2(-h*.28f,v*.28f),Vector2.zero};
   float[] weights={.14f,.18f,.20f,.22f,.26f};stage.localPosition=Vector3.zero;
   for(int i=0;i<5;i++)
   {
    Vector3 from=stage.localPosition,to=new Vector3(offsets[i].x,-offsets[i].y,0)/(100*LayoutMapper.Scale(new Vector2(Screen.width,Screen.height)));
    float t=0,duration=d*weights[i];
    while(t<duration){yield return null;t+=Time.deltaTime;float p=Mathf.Clamp01(t/duration);stage.localPosition=Vector3.Lerp(from,to,1-(1-p)*(1-p));}
   }
   stage.localPosition=Vector3.zero;shake=null;
  }
  public void Clear(){StopAllCoroutines();shake=null;if(stage)stage.localPosition=Vector3.zero;foreach(var go in effects)if(go)Destroy(go);effects.Clear();}
  void OnDestroy(){Clear();foreach(var frame in frames)Destroy(frame);}
 }
}

