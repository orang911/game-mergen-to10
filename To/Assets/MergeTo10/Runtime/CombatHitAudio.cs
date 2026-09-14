using UnityEngine;
namespace MergeTo10.Runtime
{
 public sealed class CombatHitAudio:MonoBehaviour
 {
  readonly AudioSource[] voices=new AudioSource[4];int cursor;
  public bool Muted;
  public int PlayedCount{get;private set;}
  public static float Pitch(int index)=>1+Mathf.Min(.12f,index*.025f);
  public static float VolumeDb(int index,int total,bool killed)=>killed||index>=total-1?-13:index==0?-16:-23;
  public void Setup(){
   var clip=Resources.Load<AudioClip>("M1Art/merge");
   for(int i=0;i<4;i++){voices[i]=gameObject.AddComponent<AudioSource>();voices[i].playOnAwake=false;voices[i].spatialBlend=0;voices[i].clip=clip;}
  }
  public void Play(int index,int total,bool killed){
   if(Muted)return;var voice=voices[cursor++%4];voice.Stop();
   voice.pitch=Pitch(index);voice.volume=Mathf.Pow(10,VolumeDb(index,total,killed)/20);voice.Play();PlayedCount++;
  }
  public void Pause(bool paused){foreach(var voice in voices)if(voice){if(paused)voice.Pause();else voice.UnPause();}}
  public void Clear(){foreach(var voice in voices)if(voice)voice.Stop();cursor=0;}
 }
}
