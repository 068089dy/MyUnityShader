Shader "Unlit/LensShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // 在所有不透明几何体之后绘制自己
        Tags { "Queue" = "Transparent" }
        LOD 100
        Cull Off
        // 将对象后面的屏幕抓取到 _BackgroundTexture 中
        GrabPass
        {
            "_BackgroundTexture"
        }
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
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD1;
                float4 objPos : TEXCOORD2;
                float4 centerClipPos : TEXCOORD3;
                float4 normal: NORMAL;  
                float4 worldPos: TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.objPos = v.vertex;
                o.normal = v.normal;
                o.centerClipPos = UnityObjectToClipPos(float4(0, 0, 0, 1));
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }
            
            sampler2D _BackgroundTexture;

            fixed4 frag (v2f i) : SV_Target
            {
                // 计算中心的裁剪空间位置
                // sample the texture
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                if (dot(i.normal, viewDir) > 0.8){
                    return fixed4(0, 0, 0, 1);
                } else {
                    float distance = i.centerClipPos.z;
                    half4 bgcolor = tex2Dproj(_BackgroundTexture, i.grabPos);
                    half2 uv = i.vertex.xy/_ScreenParams.xy;
                    half2 center = i.centerClipPos.xy;
                    float len = length(uv - center);
                    float rad = 0.5;
                    float dist = 0.5;
               
                    float2 offset = uv - center;
                    
                    float deformation = 1 / pow(len * pow(dist, 0.5), 2) * rad * 0.1;
 
                    offset = offset * (1 - deformation);
                    offset += center;
                    offset = offset * (1-(0.1*rad)/(pow(len, 2)*dist)) + center;
                    bgcolor = tex2D(_BackgroundTexture, offset);
                    if (len * dist < rad) {
                        return half4( 0, 0, 0, 1 );
                    }
                    return i.grabPos.y;
                }
                return 1;
            }
            ENDCG
        }
    }
}
