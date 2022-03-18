Shader "Unlit/OutLineV2Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
        
        
        Pass
        {
            Cull Front
            Blend SrcAlpha One
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 normal: TEXCOORD2;
                float3 viewDir: TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                
                // 这里默认物体中心为远点
                float4 cube_model_center = float4(0,0,0,0);
                // 用顶点坐标减去物体中心作为法线
                float3 strange_normal = normalize(v.vertex.xyz - cube_model_center.xyz);
                // 沿着法线方向扩展
                v.vertex = v.vertex + float4(strange_normal, 0) * 0.1;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.viewDir = normalize(o.worldPos.xyz - _WorldSpaceCameraPos.xyz);
                o.normal = mul(unity_ObjectToWorld, float4(strange_normal, 0)).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 col = float4(1,0,0,1);
                //col.a = pow(saturate(dot(i.viewDir, i.normal.xyz)), 20) * 20;
                return col;
            }
            ENDCG
        }
    }
}
