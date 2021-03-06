Shader "Unlit/TorusSDF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Noise ("Noise Texture", 2D) = "white" {}
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 objPos : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float3 origin : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Noise;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.objPos = v.vertex;
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
                o.origin = mul(UNITY_MATRIX_M, float4(0,0,0,1));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            float torus_sdf(float3 p, float r1, float r2){
                float2 q = float2(length(p.xz) - r1, p.y);
                return length(q) - r2;
            }
            
            float sphere_sdf(float3 p, float r){
                return length(p) - r;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 torCol = 0;
                float3 start = _WorldSpaceCameraPos;
                float cameraDis = length(i.worldPos.xyz - _WorldSpaceCameraPos);
                float3 dir = normalize(i.worldPos.xyz - _WorldSpaceCameraPos);
                
                float3 origin = i.origin;
                float3 p = start-origin;
                int hitToru = 0;
                int isHit = 0;
                for (int i = 0; i < 800; i++){
                    p = start-origin;
                    float hit = torus_sdf(p*float3(1, 12, 1), 1.5, 0.5);
                    if (hit < 0.01){
                        isHit = 1;
                        break;
                    }
                    start += dir * cameraDis* 0.0025;
                }
                if (isHit == 1){
                    float v = smoothstep(0, 1, length(p.xz)/2);
                    float u = (atan2(p.z, p.x)/3.1415 * v) - _Time.y*0.1;
                    float tx = tex2D(_Noise, float2(u,v)*8).r;
                    return tx;
                }
                return torCol;
            }
            ENDCG
        }
    }
}
