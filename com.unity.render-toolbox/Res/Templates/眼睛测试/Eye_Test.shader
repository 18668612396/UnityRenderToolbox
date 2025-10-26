Shader "Custom/Eye_Test"
{
    Properties
    {
        _MidPlaneDisplacement("_MidPlaneDisplacement", 2D) = "white"{}
        
        _IrisUVRadius("Iris UV Radius", Range(0,0.5)) = 0.5
        _ScaleByCenter("Scale By Center", Float) = 1.0
        _DepthScale("Depth Scale", Float) = 1.2
        
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_MidPlaneDisplacement);
            SAMPLER(sampler_MidPlaneDisplacement);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _ScaleByCenter;
                float _IrisUVRadius;
                float _DepthScale;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 midPlaneDisplacement = SAMPLE_TEXTURE2D(_MidPlaneDisplacement, sampler_MidPlaneDisplacement, IN.uv);

                float2 DepthPlaneOffsetUV = float2(_IrisUVRadius * _ScaleByCenter + 0.5,0.5);
                half DepthPlaneOffset = SAMPLE_TEXTURE2D(_MidPlaneDisplacement, sampler_MidPlaneDisplacement,DepthPlaneOffsetUV);
                half ss = max(0.0,midPlaneDisplacement.rgb - DepthPlaneOffset) * _DepthScale;
                
                return ss;
            }
            ENDHLSL
        }
    }
}