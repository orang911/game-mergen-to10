Shader "MergeTo10/UIImprintCleanup" {
 Properties { [PerRendererData] _MainTex("Texture",2D)="white"{} }
 SubShader { Tags {"Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True"} Cull Off ZWrite Off ZTest [unity_GUIZTestMode] Blend SrcAlpha OneMinusSrcAlpha
 Pass { CGPROGRAM
 #pragma vertex vert
 #pragma fragment frag
 #include "UnityCG.cginc"
 struct Input {float4 vertex:POSITION;float2 uv:TEXCOORD0;fixed4 color:COLOR;};
 struct Output {float4 vertex:SV_POSITION;float2 uv:TEXCOORD0;fixed4 color:COLOR;};
 sampler2D _MainTex;
 Output vert(Input v){Output o;o.vertex=UnityObjectToClipPos(v.vertex);o.uv=v.uv;o.color=v.color;return o;}
 fixed4 frag(Output i):SV_Target {
  float2 uv=i.uv;float y=1-uv.y;
  if(uv.x>.095&&uv.x<.905&&y>.020&&y<.046)uv.y=1-.054;
  if(uv.x>.908&&uv.x<.940&&y>.195&&y<.905)uv.x=.895;
  return tex2D(_MainTex,uv)*i.color;
 }
 ENDCG }
 }
}
