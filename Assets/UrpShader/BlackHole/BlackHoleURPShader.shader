Shader "Unlit/BlackHoleURPShader"
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

            float sphere_sdf(float3 p, float r){
                return length(p) - r;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float4 torCol = 0;
                float3 start = _WorldSpaceCameraPos;
                float cameraDis = length(i.worldPos.xyz - _WorldSpaceCameraPos);
                float3 dir = normalize(i.worldPos.xyz - _WorldSpaceCameraPos);
                
                float3 origin = i.origin;
                float3 p = start-origin;
                float dt = 0.001;
                float hitPan = 0;
                float hitHole = 0;
                int hitPanFlag = 0;
                float3 hitToruP;
                float3 hitHoleP;
                float GM = 0.8;

                float hit = sphere_sdf(p*float3(1,33,1), 4);
                //float rayL = length(normalize(p*float3(1,33,1))*hit*float3(1,1/33,1));
                //dir = normalize(i.worldPos.xyz - _WorldSpaceCameraPos*float3(1, 13, 1));
                for (int i = 0; i < 800; i++){
                    p = (start-origin);
                    hit = sphere_sdf(p*float3(1,33,1), 4);
                    
                    float hitR = sphere_sdf(p, 4);
                    //float hit = plane_vertical_sdf(p*float3(1, 13, 1), 4, 3);
                    //float hitR = torus_sdf(p*float3(1, 1, 1), 4, 3);
                    //float hit = yuanzhu_sdf(p, 0.1, 4);
                    float hitToru = smoothstep(0, -0.01, hit);
                    float hitSphere = sphere_sdf((start-origin), 0.7);
                    if (hit < 0.001 && hitPanFlag==0){
                        // 碰到了吸积盘，记录
                        hitPan = hitToru;
                        hitPanFlag = 1;
                        hitToruP = p;
                        break;
                    }
                    
                    if (hitSphere < 0.01) {
                        // 碰到了黑洞，记录并跳出
                        hitHoleP = p;
                        hitHole = 1;
                        break;
                    }
                    
                    // 计算光线弯曲
                    float r2 = dot(p, p);
                    float3 a = GM/r2*normalize(-p);
                    float curDt = 0.001;
                    if (hit>0 && hitR>curDt){
                        
                        curDt = hitR;
                    }
                    if (hitSphere > 0.01 && hitSphere < curDt){
                        curDt = hitSphere;
                    }
                    
                    start += dir * hitR;
                    dir += a*hitR;
                    
                }
                if (hitHole > 0 && hitPan < 0.1) {
                    //float hits = 1- smoothstep(0, -0.01, sphere_sdf(hitHoleP, 1));
                    float dot1 = 1-dot(normalize(hitHoleP), normalize(-hitHoleP+_WorldSpaceCameraPos))*2;
                    torCol.rgb = dot1;
                    // 碰到了黑洞，没有碰到吸积盘，返回黑色
                    torCol.a = 1;
                    return torCol;
                }
                if (hitPanFlag == 1) {
                    // 碰到了吸积盘
                    float v = smoothstep(0, 1, length(hitToruP.xz)/8);
                    float u = (atan2(hitToruP.z, hitToruP.x)/3.1415 * v) - _Time.y;
                    float tx = tex2D(_Noise, float2(u,v)).r;
                    torCol = fixed4(1,1,0,tx*8 * length(hitToruP.xz)/15);
                    if (hitHole > 0) {
                        torCol = fixed4(0,0,0,1) * (1 - tx) + fixed4(1, 1, 1, 1) * tx;
                    }
                    torCol.xyz = (torCol.xyz-0.3)*4;
                    float r2 = dot(hitToruP, hitToruP);
                    // if (length(hitToruP.xz) < 0.8) {
                    //     torCol = 1;
                    // }
                    //float glow = 0.5/r2;
                    //torCol += glow;
                }

                return torCol;
            }
            ENDCG
        }
    }
}
