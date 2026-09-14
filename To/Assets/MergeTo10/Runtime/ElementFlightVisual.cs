using System;
using System.Collections.Generic;
using UnityEngine;
namespace MergeTo10.Runtime
{
 // Presentation uses frame time, independently of the combat wall-clock hit boundary.
 public sealed class ElementFlightVisual:MonoBehaviour
 {
  SpriteRenderer core,ribbon;Material trailMaterial;Sprite trailSprite;
  Sprite[] beams;Func<Vector3?> target,source;Vector3 origin,lastEnd;float age,lostAge;string key;
  public float PresentationAge=>age;
  sealed class Particle {public SpriteRenderer View;public Vector3 Start,End;public Color Tint;public float Age,Life,Scale,EndScale,Rotation,Spin,FadeDelay;}
  readonly List<Particle> particles=new List<Particle>();
  readonly System.Random random=new System.Random();
  Sprite particleSprite;Material additive;Vector3 previousHead;float nextDistance;int side=-1;bool addNext;
  float Roll(float min,float max)=>Mathf.Lerp(min,max,(float)random.NextDouble());
  float NextDistance(){float distance=Roll(9,27);if(Roll(0,1)<.20f)distance+=Roll(18,36);return distance*(key=="fire"?.90f:1)/100;}
  public static float HistoryLength(float distance,float progress,float width)=>Mathf.Max(width*.70f,distance*Mathf.Min(Mathf.Clamp01(progress),.10f/.14f)+9.5f);
  public static int LightningFrame(float elapsed)=>Mathf.Min(5,(int)(elapsed/(.4f/6)))%3;
  public void Setup(string element,Vector3 start,Func<Vector3?> provider,Func<Vector3?> sourceProvider=null)
  {
   key=element;origin=start;target=provider;source=sourceProvider;lastEnd=provider()??start;core=GetComponent<SpriteRenderer>();
   if(key=="lightning"){
    var tex=Resources.Load<Texture2D>("M2Art/lightning_beam");beams=new Sprite[3];
    for(int i=0;i<3;i++)beams[i]=Sprite.Create(tex,new Rect(i*266+4,tex.height-520,258,516),Vector2.one*.5f,100,0,SpriteMeshType.FullRect);
   }else{
    var tex=Resources.Load<Texture2D>("M2Art/trail_"+key);
    trailSprite=Sprite.Create(tex,new Rect(0,0,tex.width,tex.height),Vector2.one*.5f,100,0,SpriteMeshType.FullRect);
    var go=new GameObject("Ribbon_"+key);go.transform.SetParent(transform.parent,false);
    ribbon=go.AddComponent<SpriteRenderer>();ribbon.sprite=trailSprite;ribbon.sortingOrder=209;
    trailMaterial=new Material(Resources.Load<Shader>("M1Art/ElementRibbon"));ribbon.sharedMaterial=trailMaterial;
    Configure();
    var particleTex=Resources.Load<Texture2D>("M2Art/particle_"+key);
    particleSprite=Sprite.Create(particleTex,new Rect(0,0,particleTex.width,particleTex.height),Vector2.one*.5f,100,0,SpriteMeshType.FullRect);
    additive=new Material(Resources.Load<Shader>("M1Art/ElementParticleAdd"));previousHead=origin;nextDistance=NextDistance();addNext=Roll(0,1)>=.5f;
   }
   Present(0);
  }
  void Configure()
  {
   Color tail,middle,head;float flow,distortion,opacity;
   switch(key){
    case "poison":tail=new Color(.05f,.34f,.04f);middle=new Color(.24f,.82f,.10f);head=new Color(.78f,1,.30f);flow=2.2f;distortion=.045f;opacity=.90f;break;
    case "critical":tail=new Color(.14f,.03f,.34f);middle=new Color(.56f,.16f,.90f);head=new Color(.96f,.74f,1);flow=2.5f;distortion=.038f;opacity=.92f;break;
    case "fire":tail=new Color(.48f,.035f,.01f);middle=new Color(1,.24f,.025f);head=new Color(1,.94f,.20f);flow=3;distortion=.048f;opacity=.94f;break;
    default:tail=new Color(.05f,.22f,.88f);middle=new Color(.05f,.78f,1);head=new Color(.82f,.97f,1);flow=2.8f;distortion=.038f;opacity=.92f;break;
   }
   trailMaterial.SetColor("_Tail",tail);trailMaterial.SetColor("_Middle",middle);trailMaterial.SetColor("_Head",head);
   trailMaterial.SetFloat("_Flow",flow);trailMaterial.SetFloat("_Distortion",distortion);trailMaterial.SetFloat("_Opacity",opacity);
   trailMaterial.SetFloat("_UseAlpha",key=="ice"?0:1);trailMaterial.SetFloat("_Thickness",key=="ice"?.014f:.008f);
   trailMaterial.SetFloat("_TailSoft",key=="ice"?.16f:key=="fire"?.20f:.18f);trailMaterial.SetFloat("_HeadSoft",key=="ice"?.10f:.12f);
  }
  void Update(){
   age+=Time.deltaTime;Present(age);TickParticles(Time.deltaTime);
   if(age>=(key=="lightning"?.4f:.19f)&&particles.Count==0)Destroy(gameObject);
  }
  void Emit(Vector3 head)
  {
   var segment=head-previousHead;float remaining=segment.magnitude;var direction=segment.normalized;float cursor=0;
   while(remaining>=nextDistance&&remaining>.00001f){
    cursor+=nextDistance;Spawn(previousHead+direction*cursor,direction);
    if(Roll(0,1)<.30f)Spawn(previousHead+direction*(cursor+Roll(-.04f,.04f)),direction);
    remaining-=nextDistance;nextDistance=NextDistance();
   }
   nextDistance-=remaining;previousHead=head;
  }
  void Spawn(Vector3 start,Vector3 direction)
  {
   var go=new GameObject("TrailParticle_"+key);go.transform.SetParent(transform.parent,false);
   var view=go.AddComponent<SpriteRenderer>();view.sprite=particleSprite;view.sharedMaterial=addNext?additive:core.sharedMaterial;view.sortingOrder=208;
   float roll=Roll(0,1),scale=roll<.45f?Roll(.040f,.075f):roll<.85f?Roll(.085f,.130f):Roll(.145f,.205f);
   if(key=="fire")scale*=.82f;
   Color min,max;
   switch(key){
    case "poison":min=new Color(.40f,.82f,.08f);max=new Color(.86f,1,.28f);break;
    case "critical":min=new Color(.52f,.22f,.92f);max=new Color(.98f,.70f,1);break;
    case "fire":min=new Color(1,.16f,.025f);max=new Color(1,.94f,.20f);break;
    default:min=new Color(.68f,.90f,1);max=new Color(.90f,1,1);break;
   }
   var tint=Color.Lerp(min,max,Roll(0,1));tint.a=addNext?Roll(.46f,.72f):Roll(.68f,.94f);addNext=!addNext;
   side*=-1;float life=Roll(.20f,.62f)*(key=="fire"?.88f:1);
   // Unity Y is inverted relative to the original design canvas.
   var normal=new Vector3(direction.y,-direction.x,0);
   var p=new Particle{View=view,Start=start,End=start+(normal*(Roll(.68f,1.25f)*side)+direction*Roll(-.18f,.14f))*life,
    Life=life,Scale=scale,EndScale=scale*Roll(.16f,.30f),Tint=tint,Rotation=Roll(-180,180),Spin=Roll(-1.8f,1.8f)*Mathf.Rad2Deg,FadeDelay=life*Roll(.12f,.62f)};
   particles.Add(p);view.transform.localPosition=start;view.transform.localScale=Vector3.one*scale;view.color=tint;
  }
  void TickParticles(float delta)
  {
   for(int i=particles.Count-1;i>=0;i--){
    var p=particles[i];p.Age+=delta;
    if(p.Age>=p.Life){Destroy(p.View.gameObject);particles.RemoveAt(i);continue;}
    float t=p.Age/p.Life;p.View.transform.localPosition=Vector3.Lerp(p.Start,p.End,1-(1-t)*(1-t));
    p.View.transform.localScale=Vector3.one*Mathf.Lerp(p.Scale,p.EndScale,t*t);
    p.View.transform.localRotation=Quaternion.Euler(0,0,p.Rotation+p.Spin*t);
    var color=p.Tint;float fade=Mathf.Clamp01((p.Age-p.FadeDelay)/Mathf.Max(.04f,p.Life-p.FadeDelay));color.a*=1-fade*fade;p.View.color=color;
   }
  }
  void Present(float elapsed)
  {
   if(source!=null)origin=source()??origin;
   var end=target();if(end.HasValue)lastEnd=end.Value;else lostAge+=Time.deltaTime;
   Vector3 delta=lastEnd-origin;float angle=Mathf.Atan2(delta.y,delta.x)*Mathf.Rad2Deg;
   if(key=="lightning"){
    core.sprite=beams[LightningFrame(elapsed)];core.transform.localPosition=(origin+lastEnd)*.5f;
    M1Art.SetSize(core,new Vector2(120,Mathf.Max(96,delta.magnitude*100+64)));
    core.transform.localRotation=Quaternion.Euler(0,0,angle+90);return;
   }
   float progress=Mathf.Clamp01(elapsed/.14f),collapse=1-Mathf.Pow(Mathf.Clamp01((elapsed-.14f)/.05f),2);
   var head=Vector3.Lerp(origin,lastEnd,progress);core.transform.localPosition=head;
   if(elapsed<=.19f&&end.HasValue)Emit(head);
   M1Art.SetSize(core,Vector2.one*(key=="ice"?70:key=="poison"?74:78));
   float aliveAlpha=1-Mathf.Clamp01(lostAge/.08f);
   core.color=new Color(1,1,1,aliveAlpha);
   core.transform.localRotation=Quaternion.Euler(0,0,angle-(key=="critical"?0:90));core.enabled=elapsed<.14f;
   float width=key=="ice"?64:68,length=Mathf.Max(1,HistoryLength(delta.magnitude*100,progress,width)*collapse);
   ribbon.transform.localPosition=head+delta.normalized*((9.5f*collapse-length*.5f)/100);
   ribbon.transform.localRotation=Quaternion.Euler(0,0,angle);M1Art.SetSize(ribbon,new Vector2(length,width));
   ribbon.color=new Color(1,1,1,collapse*aliveAlpha);trailMaterial.SetFloat("_Age",Time.time);
   ribbon.enabled=elapsed<.19f;
  }
  void OnDestroy(){
   foreach(var p in particles)if(p.View){p.View.gameObject.SetActive(false);Destroy(p.View.gameObject);}
   if(particleSprite)Destroy(particleSprite);if(additive)Destroy(additive);
   if(ribbon){ribbon.gameObject.SetActive(false);Destroy(ribbon.gameObject);}if(trailSprite)Destroy(trailSprite);if(trailMaterial)Destroy(trailMaterial);if(beams!=null)foreach(var s in beams)if(s)Destroy(s);
  }
 }
}
