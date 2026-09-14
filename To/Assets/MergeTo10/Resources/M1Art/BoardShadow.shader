Shader "MergeTo10/BoardShadow"
{
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }
        Cull Off ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            Tags { "LightMode"="SRPDefaultUnlit" }
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            int _BlockCount;
            float4 _Blocks[25];
            float4 _Opacities[25];
            struct Attributes { float3 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionCS:SV_POSITION; float2 uv:TEXCOORD0; };
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS=TransformObjectToHClip(input.positionOS);
                output.uv=input.uv;
                return output;
            }
            float4 frag(Varyings input):SV_Target
            {
                float2 pixel=input.uv*633.0;
                float coverage=0;
                for(int index=0;index<25;index++)
                {
                    if(index>=_BlockCount)break;
                    float2 halfSize=_Blocks[index].zw;
                    float radius=min(18.0,min(halfSize.x,halfSize.y)-0.5);
                    float2 q=abs(pixel-_Blocks[index].xy-float2(3,6))-halfSize+radius;
                    float distanceToShadow=min(max(q.x,q.y),0.0)+length(max(q,0.0))-radius;
                    coverage=max(coverage,(1-smoothstep(-3.5,3.5,distanceToShadow))*_Opacities[index].x);
                }
                float3 color=float3(0.025,0.045,0.09);
                #if !defined(UNITY_COLORSPACE_GAMMA)
                color=SRGBToLinear(color);
                #endif
                return float4(color,0.28*coverage);
            }
            ENDHLSL
        }
    }
}
