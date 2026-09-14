Shader "MergeTo10/ElementRibbon"
{
 Properties {
  [PerRendererData] _MainTex("Trail",2D)="white"{}
  _Tail("Tail",Color)=(.05,.22,.88,1) _Middle("Middle",Color)=(.05,.78,1,1) _Head("Head",Color)=(.82,.97,1,1)
  _Opacity("Opacity",Float)=.92 _Flow("Flow",Float)=2.8 _Distortion("Distortion",Float)=.038
  _UseAlpha("Use Alpha",Float)=0 _TailSoft("Tail soft",Float)=.16 _HeadSoft("Head soft",Float)=.10
  _Thickness("Thickness",Float)=.014 _Age("Frame time",Float)=0
 }
 SubShader {
  Tags {"Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"}
  Cull Off ZWrite Off Blend SrcAlpha One
  Pass {
   Tags {"LightMode"="SRPDefaultUnlit"}
   HLSLPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/Core2D.hlsl"
   #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
   TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
   float4 _Tail,_Middle,_Head;
   float _Opacity,_Flow,_Distortion,_UseAlpha,_TailSoft,_HeadSoft,_Thickness,_Age;
   struct A {float3 p:POSITION;float2 uv:TEXCOORD0;float4 c:COLOR;};
   struct V {float4 p:SV_POSITION;float2 uv:TEXCOORD0;float4 c:COLOR;};
   V vert(A a){V v;v.p=TransformObjectToHClip(a.p);v.uv=float2(a.uv.x,1-a.uv.y);v.c=a.c*unity_SpriteColor;return v;}
   float hash21(float2 p){p=frac(p*float2(123.34,456.21));p+=dot(p,p+45.32);return frac(p.x*p.y);}
   float noise(float2 p){float2 c=floor(p),l=frac(p);l=l*l*(3-2*l);return lerp(lerp(hash21(c),hash21(c+float2(1,0)),l.x),lerp(hash21(c+float2(0,1)),hash21(c+1),l.x),l.y);}
   float4 sampleTrail(float2 uv){
    float4 s=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,float2(uv.x,1-uv.y));
    #if !defined(UNITY_COLORSPACE_GAMMA)
    s.rgb=LinearToSRGB(s.rgb);
    #endif
    return s;
   }
   float4 frag(V i):SV_Target {
    float2 uv=i.uv;float t=_Age*_Flow;
    float na=noise(float2(uv.x*7-t,uv.y*3.5+t*.35)),nb=noise(float2(uv.x*12.6+t*.7,uv.y*6-t*.22));
    float wave=sin(uv.x*15-t*2.2+nb*4);
    uv.y+=((na-.5)*1.35+wave*.24)*_Distortion*lerp(1,.3,i.uv.x);
    uv.x+=(nb-.5)*_Distortion*.24;uv=clamp(uv,.001,.999);
    float4 s=sampleTrail(uv),u=sampleTrail(uv+float2(0,_Thickness)),d=sampleTrail(uv-float2(0,_Thickness));
    float3 weights=float3(.299,.587,.114);
    float lum=max(dot(s.rgb,weights),max(dot(u.rgb,weights),dot(d.rgb,weights))*.72);
    float alpha=_UseAlpha>.5?smoothstep(.02,.85,max(s.a,max(u.a,d.a)*.72)):smoothstep(.025,.68,lum);
    alpha*=smoothstep(0,_TailSoft,i.uv.x)*(1-smoothstep(1-_HeadSoft,1,i.uv.x));
    alpha*=smoothstep(0,.10,i.uv.y)*(1-smoothstep(.90,1,i.uv.y))*_Opacity*i.c.a;
    float3 rgb=lerp(_Tail.rgb,_Middle.rgb,smoothstep(.02,.58,i.uv.x));
    rgb=lerp(rgb,_Head.rgb,smoothstep(.58,1,i.uv.x))*lerp(.52,1.22,smoothstep(.02,.92,lum));
    return float4(rgb,alpha);
   }
   ENDHLSL
  }
 }
}
