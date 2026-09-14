using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 public sealed class EnergyMoteGraphic:MaskableGraphic {
  public System.Action<VertexHelper> DrawMesh;
  protected override void OnPopulateMesh(VertexHelper mesh){mesh.Clear();DrawMesh?.Invoke(mesh);}
  public static void Circle(VertexHelper mesh,Vector2 p,float radius,Color color){
   int start=mesh.currentVertCount;mesh.AddVert(new Vector3(p.x,-p.y),color,Vector2.zero);
   for(int i=0;i<=20;i++){float angle=i*Mathf.PI*.1f;mesh.AddVert(new Vector3(p.x+Mathf.Cos(angle)*radius,-p.y+Mathf.Sin(angle)*radius),color,Vector2.zero);if(i>0)mesh.AddTriangle(start,start+i,start+i+1);}
  }
 }
}
