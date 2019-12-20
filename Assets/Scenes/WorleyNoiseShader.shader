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

        _VolumeColor("Volume Color", Color) = (0.5,0.5,0.5,0.5)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM

            #pragma shader_feature DISPLAY_DISTANCE DISPLAY_LIGHT DISPLAY_VOLUME

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

            float4 _VolumeColor;

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
            float3 random3( float3 p ) {
                return frac(sin(float3(dot(p,float3(127.1,311.7,269.5)), dot(p,float3(269.5,183.3,127.1)), dot(p,float3(311.7,269.5,183.3)) ))*43758.5453);
            }

            float4 frag (v2f i) : SV_Target
            {
                float min_dist = 10;
                float3 color = 0;

                //对屏幕进行缩放及拉伸处理
                float2 uv = i.uv * _UVScale;
                uv.x *= _ScreenParams.x/_ScreenParams.y;

#if defined(DISPLAY_VOLUME)
                //在体内进行步进
                float3 pos = float3(uv, _Time.x*5);
                float alpha = 0;
                float3 sumCol = 0;
                for (int i = 0; i < 20; i++)
                {
                    if ( alpha >= 1)	//累积足够
                    {
                        break;
                    }
                    else		//步进累计颜色
                    {
                        float3 id3 = floor(pos);
                        float3 offset3 = frac(pos);
                        min_dist = 10;
                        //循环相邻27个控制点，获取当前像素距最近控制点的距离
                        for ( int l = -1; l <= 1; l++ )
                        {
                            for ( int m = -1; m <= 1; m++ )
                            {
                                for ( int n = -1; n <= 1; n++ )
                                {
                                    float3 searchPoint = id3 + float3( l, m, n );
                                    
                                    //对栅格点进行随机偏移
                                    searchPoint += sin(random3( searchPoint ) * UNITY_TWO_PI + _Time.x)*0.5+0.5;

                                    float dist = distance(pos, searchPoint);
                                    min_dist = min(min_dist, dist);
                                }
                            }       
                        }
                        float density = saturate(1 -  min_dist);
                        density = smoothstep(0.5, 2.0, density);


#ifdef UNITY_COLORSPACE_GAMMA
                        float3 localCol = GammaToLinearSpace(_VolumeColor.rgb) * density;
#else
                        float3 localCol = _VolumeColor.rgb * density;
#endif

                        sumCol += localCol * (1 - alpha);;
                        alpha += density * (1 - alpha);

                        pos += float3(0,0,0.1);
                    }
                }

                float3 bgColor = 0;
                alpha = clamp(0, 1, alpha);
                sumCol += bgColor*(1- alpha);

                return float4(sumCol, 1);

#endif


                //栅格化获取id，及offset
                float2 id = floor(uv);
                float2 offset = frac(uv);

                min_dist = 10;
                //循环相邻9个控制点，获取当前像素距最近控制点的距离
                for ( int m = -1; m <= 1; m++ )
                {
                    for ( int n = -1; n <= 1; n++ )
                    {
                        float2 searchPoint = id + float2( m, n );
                        
                        //对栅格点进行随机偏移
                        searchPoint += sin(random2( searchPoint ) * UNITY_TWO_PI + _Time.y)*0.5+0.5;

                        float dist = distance(uv, searchPoint);
                        min_dist = min(min_dist, dist);
                    }
                }

#ifdef DISPLAY_DISTANCE
                color = min_dist;
                return float4(color, 1);

#elif defined(DISPLAY_LIGHT) 

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
#ifdef UNITY_COLORSPACE_GAMMA
                color += lightColor * GammaToLinearSpace(_DiffuseColor.rgb) * nl;
#else
                color += lightColor * _DiffuseColor.rgb * nl;
#endif

                //specular  //直接粘Unity的了，自己写好麻烦==
                float roughness = PerceptualRoughnessToRoughness(_Roughness);
                roughness = max(roughness, 0.002);
                float V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
                float D = GGXTerm (nh, roughness);
#ifdef UNITY_COLORSPACE_GAMMA
                float3 F = FresnelTerm (GammaToLinearSpace(_SpecularColor), lh);
#else
                float3 F = FresnelTerm (_SpecularColor, lh);
#endif
                color += V * D * UNITY_PI * F * lightColor * nl;

#ifdef UNITY_COLORSPACE_GAMMA
                return float4(LinearToGammaSpace(color), 1);
#else
                return float4(color, 1);
#endif

#endif

            }
            ENDCG
        }
    }
}
