Shader "MergeTo10/CommerceSolid" {
 Properties { _StencilComp("Stencil Comparison",Float)=8 _Stencil("Stencil ID",Float)=0 _StencilOp("Stencil Operation",Float)=0 _StencilWriteMask("Stencil Write Mask",Float)=255 _StencilReadMask("Stencil Read Mask",Float)=255 _ColorMask("Color Mask",Float)=15 }
 SubShader { Tags {"Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" "CanUseSpriteAtlas"="True"}
  Stencil {Ref [_Stencil] Comp [_StencilComp] Pass [_StencilOp] ReadMask [_StencilReadMask] WriteMask [_StencilWriteMask]}
  Cull Off Lighting Off ZWrite Off ZTest Always Blend SrcAlpha OneMinusSrcAlpha ColorMask [_ColorMask]
  Pass { CGPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "UnityCG.cginc"
   struct Input {float4 vertex:POSITION;float4 color:COLOR;};
   struct Output {float4 vertex:SV_POSITION;float4 color:COLOR;};
   Output vert(Input i){Output o;o.vertex=UnityObjectToClipPos(i.vertex);o.color=i.color;return o;}
   fixed4 frag(Output i):SV_Target{return i.color;}
   ENDCG
  }
 }
}