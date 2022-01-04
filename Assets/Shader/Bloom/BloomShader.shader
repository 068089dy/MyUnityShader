Shader "Unlit/BloomShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Theshold ("_Theshold", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass//0 预处理
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            float _Theshold;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            half3 Sample(float2 uv)
            {
                  return tex2D(_MainTex,uv).rgb;
            }
            
            half3 BoxFilter(float2 uv)
            {
                  half2 upL,upR,downL,downR;
                            
                  upL =_MainTex_ST.xy*half2(-1,1);
                  upR =_MainTex_ST.xy*half2(1,1);
                  downL =_MainTex_ST.xy*half2(-1,-1);
                  downR =_MainTex_ST.xy*half2(1,-1);
            
                  half3 col =0;
            
                  col+=Sample(uv+upL)*0.25;
                  col+=Sample(uv+upR)*0.25;
                  col+=Sample(uv+downL)*0.25;
                  col+=Sample(uv+downR)*0.25;
            
                  return col;
            }
             //亮度分布
            half3 PreFilter(half3 c)
            {
                half brightness = max(c.r,max(c.g,c.b));
                half contribution = max(0,brightness-_Theshold);
                contribution/=max(brightness,0.00001);
                return c*contribution;
            }
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(PreFilter(BoxFilter(i.uv)),1);
            }
            ENDCG
        }
        
    }
}
