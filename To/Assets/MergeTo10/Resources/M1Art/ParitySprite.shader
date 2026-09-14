Shader "MergeTo10/ParitySprite"
{
 Properties { [PerRendererData] _MainTex("Sprite",2D)="white"{} _UvCrop("UV crop",Vector)=(0,0,1,1) }
 SubShader
 {
  Tags {"Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"}
  Cull Off ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
  Pass
  {
   Tags {"LightMode"="SRPDefaultUnlit"}
   HLSLPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/Core2D.hlsl"
   TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
   float4 _UvCrop;
   struct Attributes {float4 positionOS:POSITION; float2 uv:TEXCOORD0; half4 color:COLOR;};
   struct Varyings {float4 positionCS:SV_POSITION; float2 uv:TEXCOORD0; half4 color:COLOR;};
   Varyings vert(Attributes v) {Varyings o;o.positionCS=TransformObjectToHClip(v.positionOS.xyz);o.uv=v.uv;o.color=v.color*unity_SpriteColor;return o;}
   half4 frag(Varyings i):SV_Target {return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,_UvCrop.xy+i.uv*_UvCrop.zw)*i.color;}
   ENDHLSL
  }
 }
}
