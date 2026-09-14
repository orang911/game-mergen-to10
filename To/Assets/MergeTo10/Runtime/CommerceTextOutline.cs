using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 public sealed class CommerceTextOutline:Shadow {
  public override void ModifyMesh(VertexHelper vh){
   if(!IsActive())return;var vertices=new List<UIVertex>();vh.GetUIVertexStream(vertices);
   int start=0,end=vertices.Count;float radius=Mathf.Max(.5f,Mathf.Abs(effectDistance.x)*.5f);
   for(int i=0;i<8;i++){float angle=i*Mathf.PI/4;ApplyShadowZeroAlloc(vertices,effectColor,start,end,Mathf.Cos(angle)*radius,Mathf.Sin(angle)*radius);start=end;end=vertices.Count;}
   vh.Clear();vh.AddUIVertexTriangleStream(vertices);
  }
 }
}