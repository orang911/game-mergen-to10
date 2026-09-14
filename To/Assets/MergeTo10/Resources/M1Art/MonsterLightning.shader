Shader "MergeTo10/MonsterLightning" {
 Properties { [PerRendererData] _MainTex("Sprite",2D)="white"{} _White("White phase",Float)=1 }
 SubShader {
  Tags {"Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"}
  Cull Off ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
  Pass {
   Tags {"LightMode"="SRPDefaultUnlit"}
   HLSLPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/Core2D.hlsl"
   #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
   TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);float _White;
   struct A {float3 p:POSITION;float2 uv:TEXCOORD0;float4 c:COLOR;};
   struct V {float4 p:SV_POSITION;float2 uv:TEXCOORD0;float4 c:COLOR;};
   V vert(A a){V v;v.p=TransformObjectToHClip(a.p);v.uv=a.uv;v.c=a.c*unity_SpriteColor;return v;}
   float4 frag(V v):SV_Target {
    float4 s=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,v.uv);
    #if !defined(UNITY_COLORSPACE_GAMMA)
    s.rgb=LinearToSRGB(s.rgb);
    #endif
    s*=v.c;float lum=dot(s.rgb,float3(.299,.587,.114));
    s.rgb=lerp(s.rgb,lerp(lum*.055,lerp(lum,1,.88),_White),.96);
    #if !defined(UNITY_COLORSPACE_GAMMA)
    s.rgb=SRGBToLinear(s.rgb);
    #endif
    return s;
   }
   ENDHLSL
  }
 }
}
