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

        _Scale("Scale", Range(0,1)) = 1.0

        _LimbusUVWidth("Limbus UV Width", Vector) = (0.035,0.045,0,0)

        _EyeDepth ("Eye Depth", Float) = 0.5

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
                float3 tangentWS : TEXCOORD1;
                float3 bitangentWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float3 viewDirWS : TEXCOORD4;
                float3 positionWS : TEXCOORD5;
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
                float _Scale;

                float _EyeDepth;
                float4 _LimbusUVWidth;
            CBUFFER_END

            float3 EyeReflection(
                float2 coord,
                float ScaleByCenter,
                float IrisUVRadius,
                float2 LimbusUVWidth,
                float internalIoR,
                float3 normalW,
                float3 cameraW,
                float3 EyeDepth,
                float DepthScale,
                float3 EyeNormal,
                float3 Tangent,
                float PupilScale
            )
            {
                float3 Ret = 0;
                //Center the uv
                float2 CenterUV = (coord / ScaleByCenter + 0.5) - (0.5 / ScaleByCenter);

                // Iris Mask with Limbus Ring falloff mask
                float2 UV = CenterUV - float2(0.5f, 0.5f);
                float2 m, r;
                r = (length(UV) - (IrisUVRadius - LimbusUVWidth)) / LimbusUVWidth;
                m = saturate(1 - r);
                m = smoothstep(0, 1, m);

                //Reflection direction
                float airIoR = 1.00029;
                float n = airIoR / internalIoR;
                float facing = dot(normalW, cameraW);
                float w = n * facing;
                float k = sqrt(1 + (w - n) * (w + n));
                float3 t;
                t = (w - k) * normalW - n * cameraW;
                t = -normalize(t);

                //Scale the reflection direction
                float3 IrisDepth = max(EyeDepth - 1.518, 0) * DepthScale;
                float CosAlpha = dot(cameraW, EyeNormal);
                float HeightW = IrisDepth / lerp(0.325, 1, CosAlpha * CosAlpha);
                float3 ScaleDir = HeightW * t;


                //Find tangent space coordinate
                float3 EyeTangent = normalize(Tangent - (dot(Tangent, EyeNormal) * EyeNormal));
                float TangentOffset = dot(EyeTangent, ScaleDir);
                float3 Binorm = cross(EyeTangent, EyeNormal);
                float BinomOffset = dot(Binorm, ScaleDir);
                float2 RefractedUVOffset = float2(TangentOffset, BinomOffset);

                //Combine the offset with coord
                float2 ScaleOffset = float2(-1, 1) * IrisUVRadius * RefractedUVOffset;
                float2 RefractedUV = CenterUV + ScaleOffset;
                RefractedUV = lerp(CenterUV, RefractedUV, m.r);

                //Scale Iris texture coordinates up by this amount before sampling iris
                float2 AjuastUV = (RefractedUV - 0.5) * (1 / (2 * IrisUVRadius)) + 0.5;


                //Scale the Pupil
                // Scale UVs from from unit circle in or out from center
                // float2 UV, float PupilScale
                float2 UVcentered = AjuastUV - float2(0.5f, 0.5f);
                float UVlength = length(UVcentered);
                // UV on circle at distance 0.5 from the center, in direction of original UV
                float2 UVmax = normalize(UVcentered) * 0.5f;

                float2 UVscaled = lerp(UVmax, float2(0.f, 0.f), saturate((1.f - UVlength * 2.f) * PupilScale));

                Ret.rg = UVscaled + float2(0.5f, 0.5f);
                Ret.b = m.r;

                return Ret;
            }

            float IrisDepth(float2 inUV)
            {
                half4 midPlaneDisplacement = SAMPLE_TEXTURE2D(_MidPlaneDisplacement, sampler_MidPlaneDisplacement, inUV);
                float2 DepthPlaneOffsetUV = float2(_IrisUVRadius * _ScaleByCenter + 0.5, 0.5);
                half DepthPlaneOffset = SAMPLE_TEXTURE2D(_MidPlaneDisplacement, sampler_MidPlaneDisplacement, DepthPlaneOffsetUV).r;
                return max(0.0, midPlaneDisplacement.r - DepthPlaneOffset) * _DepthScale;
            }

            //normalWS : 常规的法线朝向
            //EyeNormal : 经过法线贴图修改后的法线朝向
            float3 Test(float2 coord, float3 normalWS, float3 eyeNormalWS, float3 viewDirWS)
            {
                float3 Ret = 0;
                //Center the uv
                float2 CenterUV = (coord / _ScaleByCenter + 0.5) - (0.5 / _ScaleByCenter);

                // Iris Mask with Limbus Ring falloff mask
                float2 UV = CenterUV - float2(0.5f, 0.5f);
                float2 m, r;
                r = (length(UV) - (_IrisUVRadius - _LimbusUVWidth)) / _LimbusUVWidth;
                m = saturate(1 - r);
                m = smoothstep(0, 1, m);

                //Reflection direction
                float airIoR = 1.00029;
                float n = airIoR / _IoR;
                float facing = dot(normalWS, viewDirWS);
                float w = n * facing;
                float k = sqrt(1 + (w - n) * (w + n));
                float3 t;
                t = (w - k) * normalWS - n * viewDirWS;
                t = -normalize(t);

                //Scale the reflection direction
                float3 irisDepth = IrisDepth(coord);
                float CosAlpha = dot(viewDirWS, eyeNormalWS);
                float HeightW = irisDepth / lerp(0.325, 1, CosAlpha * CosAlpha);
                float3 ScaleDir = HeightW * t;
                return ScaleDir;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS.xyz, input.tangentOS);
                output.tangentWS = normalInputs.tangentWS;
                output.bitangentWS = normalInputs.bitangentWS;
                output.normalWS = normalInputs.normalWS;
                output.positionCS = vertexInputs.positionCS;
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInputs.positionWS);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.positionWS = vertexInputs.positionWS;
                return output;
            }

            float3 ComputeRefract(float3 cameraW, float3 normalW, float internalIoR)
            {
                float airIoR = 1.00029; // 保持一致，或简化为 1.0 测试差异

                cameraW = normalize(cameraW); // 确保归一化
                normalW = normalize(normalW);

                float n = airIoR / internalIoR;
                float facing = dot(normalW, cameraW);

                // 处理背面（如果从介质内部查看）
                if (facing < 0)
                {
                    normalW = -normalW; // 翻转法线
                    facing = -facing;
                    n = 1.0 / n; // 反转 IOR（从介质到空气）
                }

                float w = n * facing;
                float discriminant = 1 + (w - n) * (w + n);

                // TIR 检查：如果判别式 < 0，返回反射向量作为 fallback
                if (discriminant < 0)
                {
                    return reflect(cameraW, normalW); // 使用内置 reflect 函数
                }

                float k = sqrt(discriminant);

                float3 t = (w - k) * normalW - n * cameraW;
                t = normalize(t);
                return -t; // 保持原返回负值
            }

            float2 ScaleUVsByCenter(float2 inUV, float scaleByCenter)
            {
                float2 centeredUV = inUV - float2(0.5, 0.5);
                centeredUV *= scaleByCenter;
                return centeredUV + float2(0.5, 0.5);
            }


            float3 RefractionDirection(float3 normalWS, float3 viewDirWS, float ior, float irisDepth)
            {
                float3 incident = viewDirWS; // Correct incident direction (from camera to surface)
                float3 refraction = refract(incident, normalWS, 1.00029 / ior);
                float rdotn = dot(refraction, normalWS);
                float rdotn2 = rdotn * rdotn;
                float rdotnLerp = lerp(0.325, 1, rdotn2);
                return (irisDepth / rdotnLerp) * refraction;
            }

            float2 DeriveTangents(float3 normalWS, float3 refractionDir, float3 tangentWS)
            {
                float3 direction = normalize(tangentWS); // Use tangent as basis instead of fixed (0,0,1)
                float p1 = dot(direction, normalWS);
                float3 p2 = normalize(direction - p1 * normalWS);
                float p3 = dot(p2, refractionDir);
                float3 p4 = cross(p2, normalWS);
                float p5 = dot(p4, refractionDir);
                return float2(p3, p5);
            }

            float2 scalePupils(float2 UV, float PupilScale)
            {
                float2 UVcentered = UV - float2(0.5f, 0.5f);
                float UVlength = length(UVcentered);
                float2 UVmax = normalize(UVcentered) * 0.5f;

                float2 UVscaled = lerp(UVmax, float2(0.f, 0.f), saturate((1.f - UVlength * 2.f) * PupilScale));
                return UVscaled + float2(0.5f, 0.5f);
            }

            half3 frag(Varyings input) : SV_Target
            {
                float2 inUV = input.uv;
                float3 normalWS = normalize(input.normalWS);
                float3 tangentWS = normalize(input.tangentWS);
                float3 bitangentWS = normalize(input.bitangentWS);
                half3 normalMapSample = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, inUV));
                float3x3 tbn = float3x3(tangentWS, bitangentWS, normalWS);
                normalWS = normalize(mul(normalMapSample, tbn));
                half4 midPlaneDisplacement = SAMPLE_TEXTURE2D(_MidPlaneDisplacement, sampler_MidPlaneDisplacement, inUV);
                float3 uv = EyeReflection(inUV,
                    _ScaleByCenter,
                    _IrisUVRadius,
                    float2(_LimbusUVWidth.x, _LimbusUVWidth.y),
                    _IoR,
                    input.normalWS,
                    normalize(input.viewDirWS),
                    float3(midPlaneDisplacement.rgb),
                    _DepthScale,
                    normalWS,
                    tangentWS,
                    _Scale
                );
                
                float irisDepth = IrisDepth(inUV);
                float3 refractionDir = RefractionDirection(normalWS, normalize(input.viewDirWS), _IoR, irisDepth);
                refractionDir = Test(inUV, input.normalWS, normalWS, input.viewDirWS);
                float2 derivedTangents = DeriveTangents(normalWS, refractionDir, input.tangentWS);

                float2 t1 = _IrisUVRadius * float2(-1, 1);
                t1 = t1 * derivedTangents + ScaleUVsByCenter(inUV, _ScaleByCenter) - 0.5;

                float2 t2 = 1 / (_IrisUVRadius * 2) * t1;
                t2 += 0.5;
                float2 finalUV = scalePupils(t2, _Scale);
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv.xy);
                return half4(baseColor.rgb * _BaseColor.rgb, 1);
            }
            ENDHLSL
        }
    }
}