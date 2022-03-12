Shader "Unlit/BlackHoleShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent" }
        Cull Front
        Blend SrcAlpha OneMinusSrcAlpha
        
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
            };

            struct v2f
            {
                float4 grabPos : TEXCOORD4;
                float4 objectPos: TEXCOORD5;
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 world_pos : TEXCOORD1;
                float3 origin : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BackgroundTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.objectPos = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.world_pos = mul(UNITY_MATRIX_M, v.vertex);
                o.origin = mul(UNITY_MATRIX_M, float4(0,0,0,1));
                o.grabPos = ComputeGrabScreenPos(UnityObjectToClipPos(v.vertex));
                return o;
            }
            
            float HitTest(float3 p){
                return length(p)-0.01;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                float3 start = _WorldSpaceCameraPos;
                
                float3 origin = i.origin;
                    
                float3 p = start;
                float3 v = normalize(i.world_pos - _WorldSpaceCameraPos);
                float dt = 0.01;
                float GM = 0.8;
                for (int j = 0; j < 400; j++){
                    p += v*dt;
                    float3 relP = p - origin;
                    float r2 = dot(relP, relP);
                    float3 a = GM/r2*normalize(-relP);
                    v += a*dt;
                    float hit = HitTest(relP);
                    float hitbh = step(hit, 0);
                    if (hitbh > 0.5)
                        break;
                }
                //grabPos = ComputeGrabScreenPos(UnityObjectToClipPos(v.vertex));
                float4 grabPos = ComputeGrabScreenPos(mul(UNITY_MATRIX_VP, p));
                float4 bgcolor = tex2Dproj(_BackgroundTexture, grabPos);
                return bgcolor;
            }
            ENDCG
        }
    }
}
