Shader "MergeTo10/ElementParticleAdd" {
 Properties { [PerRendererData] _MainTex("Sprite",2D)="white"{} }
 SubShader {
  Tags {"Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"}
  Cull Off ZWrite Off Blend SrcAlpha One
  Pass {
   Tags {"LightMode"="SRPDefaultUnlit"}
   HLSLPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/Core2D.hlsl"
   TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
   struct A {float3 p:POSITION;float2 uv:TEXCOORD0;float4 c:COLOR;};
   struct V {float4 p:SV_POSITION;float2 uv:TEXCOORD0;float4 c:COLOR;};
   V vert(A a){V v;v.p=TransformObjectToHClip(a.p);v.uv=a.uv;v.c=a.c*unity_SpriteColor;return v;}
   float4 frag(V v):SV_Target{return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,v.uv)*v.c;}
   ENDHLSL
  }
 }
}
