Shader "Unlit/BlackHoleV2Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AcDiskRadius ("_AcDiskRadius", Float) = 4 
        _AcThicknessHalf ("_AcThickness", Float) = 0.001
        _BHRadius ("_BHRadius", Float) = 0.5
        _StepLimit ("_StepLimit", int) = 0
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 objPos : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float3 origin : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _AcDiskRadius;
            float _BHRadius;
            float _AcThicknessHalf;
            int _StepLimit;

            

            float sphere_sdf(float3 p, float r){
                return length(p) - r;
            }

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

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 col = 0;
                float3 start = _WorldSpaceCameraPos;
                float3 ray = normalize(i.worldPos.xyz - _WorldSpaceCameraPos);
                float3 p = start-i.origin;

                int hitAcFlag = 0; // 是否碰到吸积盘，0表示没有碰到，1表示碰到了一次，2表示碰到后又出来，3表示第二次碰到
                int hitBHFlag = 0;
                float3 hitBHP;
                float3 hitBHViewRay;
                float3 hitAcP;
                float3 hitAcP2 = float3(0,0,0);
                float GM = 0.8;
                for (int j = 0; j < _StepLimit; j++){
                    // 计算是否进入大球
                    float hitAcSphere = sphere_sdf(p, _AcDiskRadius);
                    if (hitAcSphere < 0.001){
                        float hitBH = sphere_sdf(p, _BHRadius);
                        float hitRay = abs((p.y)/ray.y);
                        if (hitBHFlag == 0 && hitBH < 0.001) {
                            //col += fixed4(0,0,0,1);
                            hitBHFlag = 1;
                            hitBHP = p;
                            hitBHViewRay = ray;
                            //return fixed4(0,0,0,1);
                            break;
                        }
                        if (hitAcFlag == 0 && abs(p.y) <= _AcThicknessHalf) {
                            hitAcFlag = 1;
                            hitAcP = p;
                            //return 1;
                        }
                        if (hitAcFlag == 1 && abs(p.y) > _AcThicknessHalf) {
                            // 从吸积盘出来了
                            hitAcFlag = 2;
                            //hitAcP2 = p;
                            //return 1;
                        }
                        if (hitAcFlag == 2 && abs(p.y) <= _AcThicknessHalf) {
                            hitAcFlag = 3;
                            hitAcP2 = p;
                            break;
                        }
                        // 取最小值步进
                        float curDt = min(hitBH, hitRay);
                        curDt = min(0.1, curDt);
                        if (hitAcFlag == 1){
                            // 第一次进入盘，要出来
                            curDt = max(0.001, curDt); 
                        }
                        //curDt = 0.01;
                        // 计算光线弯曲
                        
                        p += curDt * ray;
                        float r2 = dot(p, p);
                        float3 a = GM/r2*normalize(-p);
                        ray += a*curDt;
                        ray = normalize(ray);
                    } else {

                        p += hitAcSphere * ray;
                    }


                    
                    
                }
                if (hitBHFlag == 1) {
                    col = fixed4(0,0,0,1);
                    //col.rgb = 1-dot(normalize(hitBHP),-hitBHViewRay);
                    //col.gb = pow(1-abs(hitBHP.y)/_BHRadius, 9)*2;
                }
                if (hitAcFlag >= 1) {
                    float distH = length(hitAcP.xz);
                    float v = smoothstep(0, 1, distH/_AcDiskRadius);
                    float u = (atan2(hitAcP.z, hitAcP.x)/3.1415 * v) - _Time.y;
                    float tx = tex2D(_MainTex, float2(u,v)).r;
                    
                    if (hitAcFlag == 3){
                        float distH2 = length(hitAcP2.xz);
                        float v2 = smoothstep(0, 1, distH2/_AcDiskRadius);
                        float u2 = (atan2(hitAcP2.z, hitAcP2.x)/3.1415 * v) - _Time.y;
                        float tx2 = tex2D(_MainTex, float2(u2,v2)).r;
                        col = col*(1-tx) + fixed4(0,1,1,1)*tx;
                        col.a = abs(1-distH/_AcDiskRadius)*2;
                        col.a += tx2*abs(1-distH2/_AcDiskRadius)*2;
                        //col = fixed4(0,1,1,1)*(tx2+tx)*abs(1-distH2/_AcDiskRadius)*2;
                        //col.a = abs(1-distH2/_AcDiskRadius)*2;
                        
                    } else {
                        col = col*(1-tx) + fixed4(0,1,1,1)*tx;
                        col.a *= abs(1-distH/_AcDiskRadius)*2;
                    }
                }
                return col;
            }
            ENDCG
        }
    }
}
