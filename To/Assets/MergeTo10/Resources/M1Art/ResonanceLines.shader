Shader "MergeTo10/ResonanceLines"
{
 Properties { _Fade("Fade",Float)=1 }
 SubShader
 {
  Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }
  Cull Off ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
  Pass
  {
   Tags { "LightMode"="SRPDefaultUnlit" }
   HLSLPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
   #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
   struct Attributes { float3 positionOS:POSITION; float4 color:COLOR; };
   struct Varyings { float4 positionCS:SV_POSITION; float4 color:COLOR; };
   Varyings vert(Attributes input)
   {
    Varyings output;
    output.positionCS=TransformObjectToHClip(input.positionOS);
    output.color=input.color;
    #if !defined(UNITY_COLORSPACE_GAMMA)
    output.color.rgb=SRGBToLinear(output.color.rgb);
    #endif
    return output;
   }
   float _Fade;
   float4 frag(Varyings input):SV_Target { return float4(input.color.rgb,input.color.a*_Fade); }
   ENDHLSL
  }
 }
}
