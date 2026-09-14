using System.Collections.Generic;
using UnityEngine;
using MergeTo10.Core;
namespace MergeTo10.Runtime
{
 public sealed class ResonanceDiagram:MonoBehaviour
 {
  Mesh mesh;Material material;
  readonly Dictionary<string,TextMesh> labels=new Dictionary<string,TextMesh>();
  sealed class Motion { public SpriteRenderer Icon;public Vector3 BaseScale;public float Age,Delay,Pulse=1,Burst=1;public readonly List<TextMesh> Outline=new List<TextMesh>(); }
  readonly Dictionary<string,Motion> motions=new Dictionary<string,Motion>();
  Font font;float finishAge=-1;
  public void Finish(){finishAge=0;}
  public static float RevealAlpha(float age,int index)=>Mathf.Clamp01((age-index*.08f)/.14f);
  public static float PulseScale(float age)=>age<.06f?Mathf.Lerp(1,1.18f,age/.06f):Mathf.Lerp(1.18f,1,(age-.06f)/.10f);
  public float AlphaFor(string key)=>motions.TryGetValue(key,out var m)?m.Icon.color.a:0;
  public void Bind(string key,SpriteRenderer icon)
  {
   if(motions.ContainsKey(key))return;
   motions.Add(key,new Motion{Icon=icon,BaseScale=icon.transform.localScale,Delay=motions.Count*.08f});
   icon.color=new Color(1,1,1,0);
  }
  public void Pulse(string key){if(motions.TryGetValue(key,out var m)){m.Pulse=0;m.Burst=1;}}
  public void BeginBurst(){foreach(var m in motions.Values)m.Burst=0;}
  public static float BurstScale(float age){
   if(age<.08f){float t=Mathf.Clamp01(age/.08f);return Mathf.Lerp(1,1.13f,1-(1-t)*(1-t));}
   float x=Mathf.Clamp01((age-.08f)/.20f)-1;float back=1+2.70158f*x*x*x+1.70158f*x*x;
   return Mathf.LerpUnclamped(1.13f,1,back);
  }
  void Update(){
   if(finishAge>=0){finishAge+=Time.deltaTime;if(finishAge>=.16f){Destroy(gameObject);return;}}
   AdvancePresentation(Time.deltaTime);
  }
  public void AdvancePresentation(float delta)
  {
   foreach(var pair in motions)
   {
    var m=pair.Value;m.Age+=delta;m.Pulse+=delta;m.Burst+=delta;
    if(!m.Icon)continue;
    float fade=finishAge<0?1:1-Mathf.Pow(Mathf.Clamp01(finishAge/.16f),2);
    material.SetFloat("_Fade",fade);
    float alpha=Mathf.Clamp01((m.Age-m.Delay)/.14f)*fade,scale=m.Burst<.28f?BurstScale(m.Burst):PulseScale(m.Pulse);
    m.Icon.color=new Color(1,1,1,alpha);m.Icon.transform.localScale=m.BaseScale*scale;
    if(!labels.TryGetValue(pair.Key,out var label))continue;
    label.color=new Color(1,1,1,alpha);
    label.transform.localScale=Vector3.one*(.95f*scale);
    label.transform.localPosition=m.Icon.transform.localPosition+new Vector3((45-633*.14f*.5f)*.0095f,-(62-633*.14f*.5f)*.0095f,0)*scale;
    foreach(var outline in m.Outline){outline.text=label.text;outline.color=new Color(.05f,.08f,.15f,alpha);}
   }
  }
  static Color ElementColor(string key)
  {
   switch(key){case "poison":return new Color(.35f,.9f,.3f);case "ice":return new Color(.5f,.8f,1);case "lightning":return new Color(1,.95f,.25f);case "critical":return new Color(.75f,.4f,.95f);default:return new Color(1,.45f,.15f);}
  }
  public bool RingVisible {get;private set;}
  public int CountFor(string key)=>labels.TryGetValue(key,out var label)?int.Parse(label.text.Substring(1)):0;
  public void Setup()
  {
   mesh=new Mesh();material=new Material(Resources.Load<Shader>("M1Art/ResonanceLines"));
   font=Resources.Load<Font>("M2Art/resonance_default");
   gameObject.AddComponent<MeshFilter>().sharedMesh=mesh;
   var renderer=gameObject.AddComponent<MeshRenderer>();renderer.sharedMaterial=material;renderer.sortingOrder=190;
  }
  public void Refresh(Dictionary<string,int> counts,Dictionary<string,Vector2> slots)
  {
   foreach(var pair in counts)
   {
    if(!labels.TryGetValue(pair.Key,out var label))
    {
     var go=new GameObject("Count_"+pair.Key);go.transform.SetParent(transform,false);
     label=go.AddComponent<TextMesh>();label.fontSize=48;label.characterSize=.06f;label.anchor=TextAnchor.UpperLeft;
     label.font=font;label.GetComponent<MeshRenderer>().sharedMaterial=font.material;
     label.color=Color.white;label.GetComponent<MeshRenderer>().sortingOrder=205;labels.Add(pair.Key,label);
     // Text top-left mirrors Godot's icon-local Count (45,62).
     label.transform.localPosition=LayoutMapper.World(LayoutMapper.BoardToDesign(slots[pair.Key]*633-Vector2.one*(633*.14f*.5f)+new Vector2(45,62)));
     label.transform.localScale=Vector3.one*.95f;
     if(motions.TryGetValue(pair.Key,out var motion))
      for(int i=0;i<16;i++)
      {
       var shadow=new GameObject("Outline_"+i);shadow.transform.SetParent(go.transform,false);
       float angle=i*Mathf.PI*2/16;shadow.transform.localPosition=new Vector3(Mathf.Cos(angle),Mathf.Sin(angle),0)*.05f;
       var text=shadow.AddComponent<TextMesh>();text.font=font;text.fontSize=48;text.characterSize=.06f;text.anchor=TextAnchor.UpperLeft;
       var renderer=text.GetComponent<MeshRenderer>();renderer.sharedMaterial=font.material;renderer.sortingOrder=204;
       motion.Outline.Add(text);
      }
    }
    else if(label.text!="×"+pair.Value)Pulse(pair.Key);
    label.text="×"+pair.Value;
   }
   RingVisible=counts.Count>=3;
   var vertices=new List<Vector3>();var colors=new List<Color>();var triangles=new List<int>();
   void Segment(Vector2 a,Vector2 b,float width,Color color)
   {
    var normal=new Vector2(-(b-a).y,(b-a).x).normalized*width*.5f;int start=vertices.Count;
    foreach(var p in new[]{a+normal,a-normal,b+normal,b-normal}){vertices.Add(LayoutMapper.World(LayoutMapper.BoardToDesign(p)));colors.Add(color);}
    triangles.AddRange(new[]{start,start+2,start+1,start+1,start+2,start+3});
   }
   if(RingVisible)
   {
    var center=new Vector2(.5f,.24f)*633;float radius=633*.285f;
    for(int i=0;i<95;i++)
    {
     float a=i*Mathf.PI*2/95,b=(i+1)*Mathf.PI*2/95;
     Segment(center+new Vector2(Mathf.Cos(a),Mathf.Sin(a))*radius,center+new Vector2(Mathf.Cos(b),Mathf.Sin(b))*radius,3,new Color(.5f,.95f,1,.65f));
    }
    string[] order={"fire","critical","poison","lightning","ice","fire"};
    for(int i=0;i<5;i++)Segment(slots[order[i]]*633,slots[order[i+1]]*633,2,new Color(.5f,.95f,1,.4f));
   }
   foreach(var pair in counts)
   {
    var center=slots[pair.Key]*633;float radius=633*.072f;var color=ElementColor(pair.Key);
    var fill=new Color(color.r*.55f,color.g*.55f,color.b*.55f,1);
    var edge=Color.Lerp(color,Color.white,.4f);
    for(int i=0;i<47;i++)
    {
     float a=i*Mathf.PI*2/47,b=(i+1)*Mathf.PI*2/47;
     var p=center+new Vector2(Mathf.Cos(a),Mathf.Sin(a))*radius;
     var q=center+new Vector2(Mathf.Cos(b),Mathf.Sin(b))*radius;
     int start=vertices.Count;
     foreach(var v in new[]{center,p,q}){vertices.Add(LayoutMapper.World(LayoutMapper.BoardToDesign(v)));colors.Add(fill);}
     triangles.AddRange(new[]{start,start+1,start+2});Segment(p,q,3,edge);
    }
   }
   mesh.Clear();mesh.SetVertices(vertices);mesh.SetColors(colors);mesh.SetTriangles(triangles,0);mesh.RecalculateBounds();
   AdvancePresentation(0);
  }
  public void Clear()
  {
   foreach(var label in labels.Values)if(label){label.gameObject.SetActive(false);Destroy(label.gameObject);}
   labels.Clear();motions.Clear();RingVisible=false;if(mesh)mesh.Clear();
  }
  void OnDestroy(){Clear();if(mesh)Destroy(mesh);if(material)Destroy(material);}
 }
}
