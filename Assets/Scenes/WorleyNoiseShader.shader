Shader "Custom/WorleyNoiseShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UVScale("UV Scale", Range(1, 100)) = 10
        _NormalIntensity("Normal Intensity", Range(0, 100)) = 10

        _DiffuseColor("Diffuse Color", Color) = (0.5,0.5,0.5,0.5)
        _SpecularColor("Specular Color", Color) = (0.5,0.5,0.5,0.5)
        _Roughness("Roughness", Range(0, 1)) = 0.5
        _LightDirection("Light Direction", Vector) = (1,0,0,0)
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
            #include "UnityStandardBRDF.cginc"

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
            float _NormalIntensity;

            float4 _DiffuseColor;
            float4 _SpecularColor;
            float _Roughness;
            float4 _LightDirection;

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
                float3 color = 0;

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
                // color = min_dist;

                //add shading
                min_dist = min_dist*min_dist;
                // min_dist = min_dist*min_dist;
                float _ddx = ddx(min_dist)*_NormalIntensity;
                float _ddy = ddy(min_dist)*_NormalIntensity;
                float3 dx = float3(1, 0, _ddx);
                float3 dy = float3(0, 1, _ddy);

                float3 normalDir = normalize(cross(dx, dy));
                float3 lightDir = normalize(_LightDirection.xyz);
                float3 viewDir = float3(0,0,1);
                float3 halfDir = normalize(viewDir+lightDir);

                float nl = saturate(dot(normalDir, lightDir));
                float nv = saturate(dot(normalDir, viewDir));
                float lh = saturate(dot(halfDir, lightDir));
                float nh = saturate(dot(normalDir, lightDir));

                float3 lightColor = 1;
                //diffuse
                color += lightColor * _DiffuseColor.rgb * nl;
                //specular  //直接粘Unity的了，自己写好麻烦==
                float roughness = PerceptualRoughnessToRoughness(_Roughness);
                roughness = max(roughness, 0.002);
                float V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
                float D = GGXTerm (nh, roughness);
                float3 F = FresnelTerm (_SpecularColor, lh);
                color += V * D * UNITY_PI * F * lightColor * nl;

                return float4(color, 1);
            }
            ENDCG
        }
    }
}
