Shader "Custom/WorleyNoiseShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UVScale("UV Scale", Range(1, 100)) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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
            };

            sampler2D _MainTex;
            float4 _MainTex_TextureSize;
            float _UVScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            //随机函数，根据id返回0-1范围的值
            float2 random2( float2 p ) {
                return frac(sin(float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))))*43758.5453);
            }

            float4 frag (v2f i) : SV_Target
            {
                float min_dist = 10;

                //对屏幕进行缩放及拉伸处理
                float2 uv = i.uv * _UVScale;
                uv.x *= _ScreenParams.x/_ScreenParams.y;

                //栅格化获取id，及offset
                float2 id = floor(uv);
                float2 offset = frac(uv);

                //循环相邻9个控制点，获取当前像素距最近控制点的距离
                for ( int m = -1; m <= 1; m++ )
                {
                    for ( int n = -1; n <= 1; n++ )
                    {
                        float2 searchPoint = id + float2( m, n );
                        
                        //对栅格点进行随机偏移
                        searchPoint += random2( searchPoint );

                        float dist = distance(uv, searchPoint);
                        min_dist = min(min_dist, dist);
                    }
                }

                return min_dist;
            }
            ENDCG
        }
    }
}
