Shader "Unlit/SphereRayMarchingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        Cull Front
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 world_pos : TEXCOORD1;
                float3 origin : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.world_pos = mul(UNITY_MATRIX_M, v.vertex);
                o.origin = mul(UNITY_MATRIX_M, float4(0,0,0,1));
                return o;
            }
            
            float3 center;
            float radius;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 start = _WorldSpaceCameraPos;
                float3 dir = normalize(i.world_pos - _WorldSpaceCameraPos);
                float3 origin = i.origin;
                for (int i = 0; i< 320; i++){
                    float distance = length(start - origin) - 1;
                    if (distance < 0.0)
                        return 1;
                    start += dir * 0.1;
                }
                //fixed4 col = tex2D(_MainTex, i.uv);
                return 0;
            }
            ENDCG
        }
    }
}
