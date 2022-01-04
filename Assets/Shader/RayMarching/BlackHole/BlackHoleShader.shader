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
            
            float torus_sdfR(float3 p, float r1, float r2){
                float2 q = float2(length(p.xz) - r1, p.y);
                return length(q) - r2;
            }
            
            float sphere_sdf(float3 p, float r){
                return length(p) - r;
            }
            
            float yuanzhu_sdf(float3 p, float height, float r){
                if (p.y <= height && p.y >= -height){
                    return length(p.xz) - r;
                } else {
                    if (length(p.xz) < r){
                        return abs(p.y) - abs(height);
                    } else {
                        return 1;
                    }
                }
            }
            
            float plane_sdf(float3 p, float3 dir){
                float len = length((abs(p.y/dir.y))*dir);
                if (length(len*dir+p)<6)
                    return len;
                return 1;
            }
            
            float plane_vertical_sdf(float3 p, float3 dir) {
                if (length(p.xz)<5)
                    return abs(p.y);
                float len = length((abs(p.y/dir.y))*dir);
                //if (length(len*dir+p)<5)
                    //return len;
                if (len < 0.02 && length(len*dir+p)<5){
                    return len;
                }
                return 0.02;
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
                float camDistance1 = length(i.origin.xyz - _WorldSpaceCameraPos);
                float3 dir = normalize(i.worldPos.xyz - _WorldSpaceCameraPos);
                
                float3 origin = i.origin;
                float3 p = start-origin;
                //float dt = (pow(1.05,cameraDis*4-2))/2000;
                float dt = 0.01;
                //dt = Random2DTo1D(p.xz*100, 0.005, 0.3);
                float hitPan = 0;
                float hitHole = 0;
                int hitPanFlag = 0;
                float3 hitToruP;
                float3 hitHoleP;
                float GM = 0.8;

                float hit = sphere_sdf(p*float3(1,33,1), 4);
                float rayL = length(normalize(p*float3(1,33,1))*hit*float3(1,1/33,1));
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
                    if (hit < 0.01 && hitPanFlag==0){
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
                    float curDt = dt;
                    if (hit>0.1 && hitR>dt){
                        
                        curDt = hitR;
                    }
                    if (hitSphere > 0 && hitSphere < curDt){
                        curDt = hitSphere;
                    }
                    
                    start += dir * curDt;
                    dir += a*curDt;
                    
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
                    float r2 = dot(hitToruP, hitToruP);
                    float glow = 1.5/r2;
                    torCol += glow;
                }
                
                return torCol;
            }
            ENDCG
        }
    }
}
