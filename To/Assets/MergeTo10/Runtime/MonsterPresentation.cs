using UnityEngine;
namespace MergeTo10.Runtime
{
 public static class MonsterPresentation
 {
  public const float SpawnDuration=.22f;
  public static float SpawnScale(float age)
  {
   float t=Mathf.Clamp01(age/SpawnDuration),a=t-1;
   return Mathf.LerpUnclamped(.12f,1,1+2.70158f*a*a*a+1.70158f*a*a);
  }
  public static float DeathDuration(bool annihilated)=>19f/24/(annihilated?2.5f:1);
  public static int DeathFrame(float age,bool annihilated)=>Mathf.Clamp((int)(age*24*(annihilated?2.5f:1)),0,18);
 }
}

