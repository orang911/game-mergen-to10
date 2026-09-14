using UnityEngine;
namespace MergeTo10.Runtime
{
 // Frame-time interpolation matches MonsterView._process, including pause at delta=0.
 public sealed class MonsterRecovery
 {
  public Vector2 Offset{get;private set;}
  public float Angle{get;private set;}
  public void Tick(float delta,bool alive,bool stunned,float stunAge,Vector2 activeOffset,bool recoiling){
   if(!alive){Offset=Vector2.zero;Angle=0;return;}
   Angle=stunned?Mathf.Sin(stunAge*103)*.035f:Mathf.Lerp(Angle,0,Mathf.Min(1,delta*22));
   Offset=stunned||recoiling?activeOffset:Vector2.Lerp(Offset,Vector2.zero,Mathf.Min(1,delta*18));
  }
 }
}
