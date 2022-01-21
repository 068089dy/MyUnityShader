Shader "Unlit/BlackHoleV2Shader"
{
    Properties
    {
        // 吸积盘纹理
        _MainTex ("Texture", 2D) = "white" {}
        // 吸积盘半径
        _AcDiskRadius ("_AcDiskRadius", Float) = 4 
        // 吸积盘的厚度，0.001效果较佳
        _AcThicknessHalf ("_AcThickness", Float) = 0.001
        // 黑洞半径
        _BHRadius ("_BHRadius", Float) = 0.5
        // 最大迭代次数
        _StepLimit ("_StepLimit", int) = 200
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
                fixed4 col = 0;
                float3 start = _WorldSpaceCameraPos;
                float3 ray = normalize(i.worldPos.xyz - _WorldSpaceCameraPos);
                float3 p = start-i.origin;

                int hitAcFlag = 0; // 是否碰到吸积盘，0表示没有碰到，1表示碰到了一次，2表示碰到后又穿过，3表示第二次碰到
                int hitBHFlag = 0;
                float3 hitBHP;
                float3 hitBHViewRay;
                float3 hitAcP;
                float3 hitAcP2 = float3(0,0,0);
                float GM = 0.3;
                for (int j = 0; j < _StepLimit; j++){
                    // 计算是否进入大球
                    float hitAcSphere = sphere_sdf(p, _AcDiskRadius);
                    if (hitAcSphere < 0.001){
                        float hitBH = sphere_sdf(p, _BHRadius);
                        float hitRay = abs((p.y)/ray.y);
                        if (hitBHFlag == 0 && hitBH < 0.001) {
                            // 碰到了黑洞
                            hitBHFlag = 1;
                            hitBHP = p;
                            hitBHViewRay = ray;
                            break;
                        }
                        if (hitAcFlag == 0 && abs(p.y) <= _AcThicknessHalf) {
                            // 第一次碰到吸积盘
                            hitAcFlag = 1;
                            hitAcP = p;
                        }
                        if (hitAcFlag == 1 && abs(p.y) > _AcThicknessHalf) {
                            // 从吸积盘出来了
                            hitAcFlag = 2;
                        }
                        if (hitAcFlag == 2 && abs(p.y) <= _AcThicknessHalf) {
                            // 第二次碰到吸积盘
                            hitAcFlag = 3;
                            hitAcP2 = p;
                            break;
                        }
                        // 取最小值步进
                        float curDt = min(hitBH, hitRay);
                        // 这里如果curDt过大时，会导致弯曲不够正确，所以最大值取到0.1
                        curDt = min(0.1, curDt);
                        if (hitAcFlag == 1){
                            // 第一次进入盘，要出来
                            curDt = max(0.001, curDt); 
                        }
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
                    // 碰到了黑洞
                    col = fixed4(0,0,0,1);
                    // 黑洞边缘发光
                    col.gb = pow(1-dot(normalize(hitBHP),-hitBHViewRay),3)*2;
                    // 靠近盘的地方发光
                    col.gb += pow(1-abs(hitBHP.y/_BHRadius),5);
                }
                if (hitAcFlag >= 1) {
                    // 碰到了吸积盘
                    float distH = length(hitAcP.xz);
                    // 纹理采样坐标
                    // v是距离中心距离，映射到0～1
                    // u是弧度值，映射到0～1
                    float v = smoothstep(0, 1, distH/_AcDiskRadius);
                    float u = (atan2(hitAcP.x, hitAcP.z)/UNITY_PI * v)/2 - _Time.y;
                    float tx = tex2D(_MainTex, float2(u,v)).r;
                    if (hitAcFlag == 3){
                        // 第二次碰到吸积盘
                        float distH2 = length(hitAcP2.xz);
                        float v2 = smoothstep(0, 1, distH2/_AcDiskRadius);
                        float u2 = (atan2(hitAcP.x, hitAcP.z)/UNITY_PI * v)/2 - _Time.y;
                        float tx2 = tex2D(_MainTex, float2(u2,v2)).r;
                        // 两次碰到吸积盘颜色混合
                        // 第一次碰到的颜色
                        col = col*(1-tx) + fixed4(0,1,1,1)*tx;
                        col.a *= abs(1-(distH-_BHRadius)/_AcDiskRadius)*5;
                        // 第二次碰到的颜色
                        fixed4 col1 = fixed4(0,1,1,1)*tx2;
                        col1.a *= abs(1-(distH2-_BHRadius)/_AcDiskRadius)*5;
                        // 混合
                        col = col1*(1-col.a) + col*col.a;
                    } else {
                        // 颜色混合
                        col = col*(1-tx) + fixed4(0,1,1,1)*tx;
                        if (hitBHFlag != 1) {
                            // 吸积盘越靠外透明度越低
                            col *= abs(1-(distH-_BHRadius)/_AcDiskRadius)*2;
                        }
                    }
                }
                return col;
            }
            ENDCG
        }
    }
}
