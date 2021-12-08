Shader "Unlit/NewUnlitShader"
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
                float3 dir = normalize(i.worldPos.xyz - _WorldSpaceCameraPos);
                
                float3 origin = i.origin;
                float3 p = start-origin;
                int hitToru = 0;
                for (int i = 0; i < 250; i++){
                    float3 p = start-origin;
                    float hit = torus_sdf((start-origin)*float3(1, 12, 1), 1, 0.5);
                    if (hit < 0.01){
                        hitToru = 1;
                    }
                    float hitHole = sphere_sdf((start-origin), 2.5);
                    if (hitHole < 0.01) {
                        if (hitToru > 0) {
                            // 被前面的吸积盘挡住了
                            return 1;
                        } else {
                            if (hitHole < -2) {
                                // 史瓦西半径
                                return fixed4(0,0,0,1);
                            }else {
                                // 引力透镜范围
                                float GM = 0.5;
                                float r2 = dot(p, p);
                                float3 a = GM/r2*normalize(-p);
                                dir += a*0.02;
                            }
                        }
                    }
                    if (hitToru > 0){
                        return 1;
                    }
                    start += dir * 0.03;
                }
                return torCol;
            }
            ENDCG
        }
    }
}
