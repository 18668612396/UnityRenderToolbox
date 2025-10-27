Shader "Custom/Eye_Test"
{
    Properties
    {
        _NormalMap("Normal Map", 2D) = "bump"{}
        _MidPlaneDisplacement("_MidPlaneDisplacement", 2D) = "white"{}

        _IrisUVRadius("Iris UV Radius", Range(0,0.5)) = 0.5
        _ScaleByCenter("Scale By Center", Float) = 1.0
        _DepthScale("Depth Scale", Float) = 1.2
        _IoR("Ior", Float) = 1.6

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
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 tangentWS : TEXCOORD1;
                float4 bitangentWS : TEXCOORD2;
                float4 normalWS : TEXCOORD3;
                float3 viewDirWS : TEXCOORD4;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_MidPlaneDisplacement);
            SAMPLER(sampler_MidPlaneDisplacement);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _ScaleByCenter;
                float _IrisUVRadius;
                float _DepthScale;
                float _IoR;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInputs = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.tangentWS.xyz = normalInputs.tangentWS;
                output.bitangentWS.xyz = normalInputs.bitangentWS;
                output.normalWS.xyz = normalInputs.normalWS;
                output.tangentWS.w = vertexInputs.positionWS.x; // Store sign in w component
                output.bitangentWS.w = vertexInputs.positionWS.y; // Store sign in w component
                output.normalWS.w = vertexInputs.positionWS.z; // Store sign in w component
                output.positionCS = vertexInputs.positionCS;
                output.viewDirWS = normalize(_WorldSpaceCameraPos - vertexInputs.positionWS);
                output.uv = input.uv;
                return output;
            }

            float3 ComputeRefract(float3 cameraW, float3 normalW, float internalIoR)
            {
                float airIoR = 1.00029;

                float n = airIoR / internalIoR;

                float facing = dot(normalW, cameraW);

                float w = n * facing;

                float k = sqrt(1 + (w - n) * (w + n));

                float3 t;
                t = (w - k) * normalW - n * cameraW;
                t = normalize(t);
                return -t;
            }

            float2 ScaleUVsByCenter(float2 inUV, float scaleByCenter)
            {
                float2 centeredUV = inUV - float2(0.5, 0.5);
                centeredUV *= scaleByCenter;
                return centeredUV + float2(0.5, 0.5);
            }

            float IrisDepth(float2 inUV)
            {
                half4 midPlaneDisplacement = SAMPLE_TEXTURE2D(_MidPlaneDisplacement, sampler_MidPlaneDisplacement, inUV);
                float2 DepthPlaneOffsetUV = float2(_IrisUVRadius * _ScaleByCenter + 0.5, 0.5);
                half DepthPlaneOffset = SAMPLE_TEXTURE2D(_MidPlaneDisplacement, sampler_LinearClamp, DepthPlaneOffsetUV);
                return max(0.0, midPlaneDisplacement.rgb - DepthPlaneOffset) * _DepthScale;
            }

            float3 RefractionDirection(float3 normalWS, float3 viewDirWS, float ior, float irisDepth)
            {
                float3 refraction = refract(viewDirWS, normalWS, 1 / ior);
                float rdotn = dot(refraction, normalWS);
                float rdotn2 = rdotn * rdotn;
                float rdotnLerp = lerp(0.325, 1, rdotn2);
                return irisDepth / rdotnLerp * refraction;
            }

            float2 DeriveTangents(float3 normalWS, float3 refractionDir)
            {
                float3 direction = float3(0, 0, 1);
                float p1 = dot(direction, normalWS);
                float3 p2 = normalize(direction - p1 * normalWS);
                float p3 = dot(p2, refractionDir);
                float3 p4 = cross(p2, normalWS);
                float p5 = dot(p4, refractionDir);
                return float2(p3, p5);
            }

            float2 scalePupils(float2 UV, float PupilScale)
            {
                // Scale UVs from from unit circle in or out from center
                // float2 UV, float PupilScale

                float2 UVcentered = UV - float2(0.5f, 0.5f);
                float UVlength = length(UVcentered);
                // UV on circle at distance 0.5 from the center, in direction of original UV
                float2 UVmax = normalize(UVcentered) * 0.5f;

                float2 UVscaled = lerp(UVmax, float2(0.f, 0.f), saturate((1.f - UVlength * 2.f) * PupilScale));
                return UVscaled + float2(0.5f, 0.5f);
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 normalWS = normalize(input.normalWS);
                float3 tangentWS = normalize(input.tangentWS.xyz);
                float3 bitangentWS = normalize(input.bitangentWS.xyz);
                half3 normalMapSample = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv).xyz * 2 - 1;
                normalMapSample.z = sqrt(1 - saturate(dot(normalMapSample.xy, normalMapSample.xy)));
                float3x3 tbn = float3x3(tangentWS, bitangentWS, normalWS);
                normalWS = normalize(mul(normalMapSample, tbn));
                float irisDepth = IrisDepth(input.uv);
                float3 refractionDir = RefractionDirection(normalWS, normalize(input.viewDirWS), _IoR, irisDepth);
                float2 derivedTangents = DeriveTangents(normalWS, refractionDir);

                float2 t1 = _IrisUVRadius * float2(-1, 1);
                t1 = t1 * derivedTangents + ScaleUVsByCenter(input.uv, _ScaleByCenter) - 0.5;

                float2 t2 = 1 / (_IrisUVRadius * 2) * t1;
                t2 += 0.5;
                float2 finalUV = scalePupils(t2, 1);
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, finalUV);
                return half4(baseColor.rgb, 1);
            }
            ENDHLSL
        }
    }
}