using System.Collections;
using System.Collections.Generic;
using MergeTo10.Core;
using UnityEngine;
namespace MergeTo10.Runtime
{
 public sealed class M1MergeFeedback:MonoBehaviour
 {
  readonly List<GameObject> effects=new List<GameObject>();
  Transform stage;GameObject burstPrefab;Coroutine shake;
  public void Setup(Transform layer,M1Art assets)
  {
   stage=layer;
   var settings=Resources.Load<MergeEffectSettings>("merge_effect");
   burstPrefab=settings?settings.Prefab:null;
   if(!burstPrefab)Debug.LogError("Missing merge_effect prefab reference",this);
  }
  public void Play(Vector2 local,int count)
  {
   StartCoroutine(Burst(LayoutMapper.BoardToDesign(local+Vector2.one*58)));
   if(shake!=null)StopCoroutine(shake);shake=StartCoroutine(Shake(count));
  }
  IEnumerator Burst(Vector2 center)
  {
   if(!burstPrefab)yield break;
   var go=Instantiate(burstPrefab,stage,false);go.name="MergeBurst";effects.Add(go);
   go.transform.localPosition=LayoutMapper.World(center);
   // Preserve the authored rotation, scale, textures and child emitters.
   var systems=go.GetComponentsInChildren<ParticleSystem>(true);
   foreach(var particles in systems)
   {
    particles.Stop(false,ParticleSystemStopBehavior.StopEmittingAndClear);
    var main=particles.main;main.loop=false;main.stopAction=ParticleSystemStopAction.None;
   }
   foreach(var renderer in go.GetComponentsInChildren<ParticleSystemRenderer>(true))renderer.sortingOrder+=100;
   foreach(var particles in systems)if(particles.gameObject.activeInHierarchy)particles.Play(false);
   bool alive;
   do
   {
    yield return null;alive=false;
    foreach(var particles in systems)if(particles&&particles.IsAlive(false)){alive=true;break;}
   }while(alive);
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
  void OnDisable(){Clear();}
  void OnDestroy(){Clear();}
 }
}
