Shader "MergeTo10/MergeGhost"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite",2D)="white"{}
        _Fade("Fade",Float)=0
    }
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
            #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/Core2D.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            float _Fade;
            struct Attributes { float3 positionOS:POSITION; float2 uv:TEXCOORD0; half4 color:COLOR; };
            struct Varyings { float4 positionCS:SV_POSITION; float2 uv:TEXCOORD0; half4 color:COLOR; };
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS=TransformObjectToHClip(input.positionOS);
                output.uv=input.uv;
                output.color=input.color*unity_SpriteColor;
                return output;
            }
            half4 frag(Varyings input):SV_Target
            {
                half4 source=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                // The frozen Godot material uses atlas UVs, not per-region normalized UVs.
                float edge=min(min(input.uv.x,1-input.uv.x),min(input.uv.y,1-input.uv.y));
                float radial=1-smoothstep(0.35,0.78,distance(input.uv,float2(0.5,0.5)));
                float alpha=source.a*input.color.a*_Fade*smoothstep(0,0.12,edge)*(0.72+radial*0.28);
                // Godot Compatibility evaluates this custom mix in display-color space.
                // Keep Unity's project linear; translate only this material's arithmetic.
                #if !defined(UNITY_COLORSPACE_GAMMA)
                source.rgb=LinearToSRGB(source.rgb);
                input.color.rgb=LinearToSRGB(input.color.rgb);
                #endif
                half3 color=lerp(source.rgb*input.color.rgb,half3(0.82,0.92,1),0.18);
                #if !defined(UNITY_COLORSPACE_GAMMA)
                color=SRGBToLinear(color);
                #endif
                return half4(color,alpha);
            }
            ENDHLSL
        }
    }
}
