using System.Collections.Generic;
using MergeTo10.Core;
using UnityEngine;
namespace MergeTo10.Runtime
{
 public sealed class MonsterStatusView:MonoBehaviour
 {
  Mesh mesh;Material material;readonly List<TextMesh> labels=new List<TextMesh>();
  public int VisibleIndicators{get;private set;}
  public void Setup(){
   mesh=new Mesh();material=new Material(Resources.Load<Shader>("M1Art/ResonanceLines"));
   gameObject.AddComponent<MeshFilter>().sharedMesh=mesh;
   var renderer=gameObject.AddComponent<MeshRenderer>();renderer.sharedMaterial=material;renderer.sortingOrder=-98;
   var font=Resources.Load<Font>("M2Art/resonance_default");
   for(int i=0;i<3;i++){
    var go=new GameObject("StatusCount");go.transform.SetParent(transform,false);
    var text=go.AddComponent<TextMesh>();text.font=font;text.fontSize=40;text.characterSize=.0275f;text.anchor=TextAnchor.MiddleCenter;
    var r=text.GetComponent<MeshRenderer>();r.sharedMaterial=font.material;r.sortingOrder=-97;labels.Add(text);
   }
  }
  public void Refresh(BattleMonster model,Vector2 position,float size){
   transform.localPosition=LayoutMapper.World(position+new Vector2(0,-size*.336f));
   var colors=new List<Color>();var stacks=new List<int>();
   if(model.Alive){
    if(model.Ice>0){colors.Add(new Color(.35f,.75f,1,.95f));stacks.Add(0);}
    if(model.Burn.Count>0){colors.Add(new Color(1,.42f,.10f,.98f));stacks.Add(model.Burn.Count);}
    if(model.Poison.Count>0){colors.Add(new Color(.32f,.84f,.22f,.98f));stacks.Add(model.Poison.Count);}
   }
   VisibleIndicators=colors.Count;
   var vertices=new List<Vector3>();var vertexColors=new List<Color>();var triangles=new List<int>();
   void Circle(Vector3 center,float radius,Color color){
    for(int j=0;j<32;j++){
     int start=vertices.Count;float a=j*Mathf.PI*2/32,b=(j+1)*Mathf.PI*2/32;
     vertices.Add(center);vertices.Add(center+new Vector3(Mathf.Cos(a),Mathf.Sin(a),0)*radius);vertices.Add(center+new Vector3(Mathf.Cos(b),Mathf.Sin(b),0)*radius);
     vertexColors.Add(color);vertexColors.Add(color);vertexColors.Add(color);triangles.AddRange(new[]{start,start+1,start+2});
    }
   }
   for(int i=0;i<3;i++){
    labels[i].gameObject.SetActive(i<colors.Count&&stacks[i]>0);
    if(i>=colors.Count)continue;
    var center=new Vector3((i-(colors.Count-1)*.5f)*.19f,0,0);
    Circle(center,.08f,new Color(.08f,.10f,.14f,.9f));Circle(center,.06f,colors[i]);
    labels[i].text=stacks[i].ToString();labels[i].transform.localPosition=center;
   }
   mesh.Clear();mesh.SetVertices(vertices);mesh.SetColors(vertexColors);mesh.SetTriangles(triangles,0);mesh.RecalculateBounds();
  }
  void OnDestroy(){if(mesh)Destroy(mesh);if(material)Destroy(material);}
 }
}
