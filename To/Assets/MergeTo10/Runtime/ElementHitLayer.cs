using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace MergeTo10.Runtime
{
 public sealed class ElementHitLayer:MonoBehaviour
 {
  public static readonly string[] Keys={"poison","ice","lightning","critical","fire","crystal"};
  public static readonly int[] Counts={13,11,10,15,7,8};
  public static readonly float[] Sizes={165,160,170,170,170,155};
  readonly Dictionary<string,Sprite[]> frames=new Dictionary<string,Sprite[]>();
  readonly List<GameObject> active=new List<GameObject>();
  Material material;
  public int ActiveCount=>active.Count;
  public int TotalPlayed {get;private set;}
  public void Setup()
  {
   material=new Material(Resources.Load<Shader>("M1Art/ParitySprite"));
   for(int k=0;k<Keys.Length;k++)
   {
    var tex=Resources.Load<Texture2D>("M2Art/hit_"+Keys[k]);
    if(!tex)throw new System.InvalidOperationException("Missing hit atlas "+Keys[k]);
    var seq=new Sprite[Counts[k]];int w=tex.width/4,h=tex.height/4;
    for(int i=0;i<seq.Length;i++){int f=i+(k==4?1:0);seq[i]=Sprite.Create(tex,new Rect(f%4*w,tex.height-(f/4+1)*h,w,h),Vector2.one*.5f,100,0,SpriteMeshType.FullRect);}
    frames.Add(Keys[k],seq);
   }
  }
  public void Play(string key,Vector2 position,int tier)
  {
   int index=System.Array.IndexOf(Keys,key);if(index<0)return;
   var go=new GameObject("Impact_"+key);go.transform.SetParent(transform,false);
   go.transform.localPosition=MergeTo10.Core.LayoutMapper.World(position);
   var r=go.AddComponent<SpriteRenderer>();r.sharedMaterial=material;r.sortingOrder=220;r.sprite=frames[key][0];
   M1Art.SetSize(r,Vector2.one*Sizes[index]*(1+Mathf.Max(0,tier-1)*.04f));
   active.Add(go);TotalPlayed++;StartCoroutine(Animate(r,frames[key],index==0?27:18));
  }
  IEnumerator Animate(SpriteRenderer r,Sprite[] seq,float fps)
  {
   foreach(var frame in seq){if(!r)yield break;r.sprite=frame;yield return new WaitForSeconds(1/fps);}
   if(r){active.Remove(r.gameObject);Destroy(r.gameObject);}
  }
  public void Clear(){StopAllCoroutines();foreach(var go in active)if(go){go.SetActive(false);Destroy(go);}active.Clear();}
  void OnDestroy(){Clear();foreach(var seq in frames.Values)foreach(var frame in seq)Destroy(frame);if(material)Destroy(material);}
 }
}

