

Shader "Unlit/OutLineShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AtmoColor("Atmosphere Color", Color) = (1,1,0,0)
        _Size("Size", Range(0,1)) = 0.5		//光晕范围
        _OutLightPow("Falloff", Range(1,10)) = 5		//光晕系数
		_OutLightStrength("Transparency", Range(5,20)) = 15	//光晕强度
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
                float4 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
        
        Pass {
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
            uniform float4 _AtmoColor;
            uniform float _Size;
            uniform float _OutLightPow;
            uniform float _OutLightStrength;
            
            v2f vert (appdata v)
            {
                v2f o;
                v.vertex = v.vertex + float4(v.normal, 0) * _Size;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = normalize(o.worldPos.xyz - _WorldSpaceCameraPos.xyz);
                o.normal = mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = _AtmoColor;
                //col.a = dot(i.viewDir, i.normal);
                float3 viewDir = normalize(i.worldPos.xyz - _WorldSpaceCameraPos.xyz);
                col.a = pow(saturate(dot(viewDir, i.normal.xyz)), _OutLightPow) * _OutLightStrength;
                return col;
            }
            ENDCG
        }
    }
}
