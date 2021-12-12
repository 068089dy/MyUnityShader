Shader "Unlit/BlackHole"
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
            
            float Random2DTo1D(float2 value,float a ,float2 b)
            {			
                //avaoid artifacts
                float2 smallValue = sin(value);
                //get scalar value from 2d vector	
                float  random = dot(smallValue,b);
                random = frac(sin(random) * a);
                return random;
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
                float dt = cameraDis/500;
                //dt = Random2DTo1D(p.xz*100, 0.005, 0.3);
                float hitPan = 0;
                float hitHole = 0;
                float3 hitToruP;
                float3 hitHoleP;
                float GM = 0.8;
                for (int i = 0; i < 800; i++){
                    p = start-origin;
                    float hit = torus_sdf((start-origin)*float3(1, 13, 1), 2, 1);
                    float hitToru = smoothstep(0, -0.01, hit);
                    float hitSphere = sphere_sdf((start-origin), 1.1);
                    if (hitToru > 0 && hitPan < 0.1){
                        hitPan = 1;
                        hitToruP = p;
                    }
                    
                    if (hitSphere < 0.01) {
                        hitHoleP = p;
                        hitHole = 1;
                        break;
                    }
                    
                    
                    float r2 = dot(p, p);
                    float3 a = GM/r2*normalize(-p);
                    dir += a*dt;
                    
                    start += dir * dt;
                }
                if (hitHole > 0 && hitPan < 0.1) {
                    return fixed4(0,0,0,1);
                }
                if (hitPan > 0) {
                    float v = smoothstep(0, 1, length(hitToruP.xz)/4);
                    float u = (atan2(hitToruP.z, hitToruP.x)/3.1415 * v) - _Time.y;
                    float tx = tex2D(_Noise, float2(u,v)).r;
                    torCol = fixed4(1,1,1,tx);
                    if (hitHole > 0) {
                        torCol = fixed4(0,0,0,1) * (1 - tx) + fixed4(1, 1, 1, tx) * tx;
                    }
                }
                return torCol;
            }
            ENDCG
        }
    }
}
