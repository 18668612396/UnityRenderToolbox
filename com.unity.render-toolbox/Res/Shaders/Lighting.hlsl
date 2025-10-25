#ifndef NEMO_COMMON_COMMON_SCENE_INCLUDED
#define NEMO_COMMON_COMMON_SCENE_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Inputs.hlsl"
TEXTURECUBE(_ReflectionCube);
SAMPLER(sampler_ReflectionCube);


//###############################################################################
//                      次表面散射算法合集      
//###############################################################################

half4 GetScatteringCoeffs(float2 uv)
{
    // half3 sss = get2DSample(_ScatteringMap, uv, disableFragment, cDefaultColor.mScattering).r * _ScatteringIntensity * _ScatteringColor;
    half3 sss = SAMPLE_TEXTURE2D(_ScatteringMap, sampler_ScatteringMap, uv).rgb * _ScatteringIntensity * _ScatteringColor.rgb * 0.01;
    half a = sss < 1e-4 ? 0.0 : 1.0;
    return half4(sss, a);
}

// Substance 的 sss_pdf
float3 sss_pdf(float r, float3 d)
{
    d = max(float3(1e-4, 1e-4, 1e-4), d);
    return (exp(-r / d) + exp(-r / (3.0 * d))) / max(float3(1e-5, 1e-5, 1e-5), 8.0 * PI * d * r);
}

// Substance 的 samples_pdf
float samples_pdf(float r, float d)
{
    return exp(-r / (3.0 * d)) / (6.0 * PI * d * r);
}

// Substance 的 samples_icdf
float samples_icdf(float x, float d)
{
    return -3.0 * log(x) * d;
}

// 快速哈希函数，用于生成伪随机值
float Hash(float2 p, float seed)
{
    return frac(sin(dot(p + seed, float2(127.1, 311.7))) * 43758.5453123);
}

// 屏幕空间蓝噪声函数（固定，不随时间变化）
float GetBlueNoise(float2 screenUV, float seed)
{
    // 屏幕空间 UV 缩放，控制噪声频率
    float2 scaledUV = screenUV; // 0.01 可调，控制噪声颗粒大小

    // 使用黄金分割比例扰动
    const float GOLD = 0.6180339887498949;
    float2 p = scaledUV + float2(seed, seed * GOLD);

    // 多层哈希叠加，模拟蓝噪声均匀性
    float n = Hash(p, seed);
    n = frac(n + Hash(p + float2(1.0, 0.0), seed * GOLD));
    n = frac(n + Hash(p + float2(0.0, 1.0), seed * GOLD * GOLD));

    return n; // 返回 [0,1] 范围的蓝噪声值
}

float3 ReconstructPositionWS(float2 tex_coord)
{
    // A. 采样深度 (使用此宏来保证跨平台兼容性)
    #if UNITY_REVERSED_Z
    real depth = SampleSceneDepth(tex_coord);
    #else
    // Adjust z to match NDC for OpenGL
    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
    #endif
    float3 worldPos = ComputeWorldSpacePosition(tex_coord, depth, UNITY_MATRIX_I_VP);
    return worldPos;
}

float3 ReconstructPositionVS(float2 tex_coord)
{
    float3 vs = TransformWorldToView(ReconstructPositionWS(tex_coord));
    return vs;
}

float3 sssConvolve(RenderToolboxInputData inputData, float4 scattering, float noise)
{
    const float GOLD = 0.618034;
    float2 tex_coord = inputData.screenUV;
    float3 prevDiffuse = SAMPLE_TEXTURE2D(_SubSurfaceScatteringDiffuse, sampler_SubSurfaceScatteringDiffuse, tex_coord).rgb;
    // if (d.a <= 0.0)
    //     return prevDiffuse;

    // Importance sample along the largest RGB component
    float dmax = max(max(scattering.x, scattering.y), scattering.z);
    float dmin = min(min(scattering.x, scattering.y), scattering.z);
    float3 currPos = ReconstructPositionVS(tex_coord);
    // Scale sample distribution with z
    float dz = dmax / -(currPos.z);

    float4x4 projectionMatrix = UNITY_MATRIX_P;

    #if UNITY_UV_STARTS_AT_TOP  // 定义在 DirectX-like 平台，表示 Y 翻转
    float scaleY = -1.0; // 补偿负 m11
    #else
    float scaleY = 1.0;
    #endif
    float projScale = projectionMatrix[0][0] * (projectionMatrix[1][1] * scaleY); // 使产品总是正
    // if (projScale * dz < 1e-4)
    //     return prevDiffuse;

    float3 X = 0.0, W = 0.0;
    int nbSamples = 64;
    for (float i = 0.0; i < nbSamples; i++)
    {
        // Fibonacci spiral
        float r = (i + 0.5) / nbSamples;
        float t = 2.0 * PI * (GOLD * i + noise);
        float icdf = samples_icdf(r, dz);
        float2 Coords = tex_coord + icdf * float2(projectionMatrix[0][0] * cos(t), projectionMatrix[1][1] * sin(t) * _ProjectionParams.x);
        float4 D = SAMPLE_TEXTURE2D(_SubSurfaceScatteringDiffuse, sampler_SubSurfaceScatteringDiffuse, Coords);
        // Re-weight samples with the scene 3D distance and SSS profile instead of 2D importance sampling weights
        // SSS mask in alpha
        float dist = distance(currPos, ReconstructPositionVS(Coords)) * 100; // 这里乘以100是因为Substance的单位是cm, 所以他的算法也是基于cm的
        if (dist > 0.0)
        {
            float3 Weights = D.a / samples_pdf(icdf, dz) * sss_pdf(dist, scattering.rgb * 100);
            X += Weights * D.rgb;
            W += Weights;
        }
    }
    return float3(
        W.r < 1e-5 ? prevDiffuse.r : X.r / W.r,
        W.g < 1e-5 ? prevDiffuse.g : X.g / W.g,
        W.b < 1e-5 ? prevDiffuse.b : X.b / W.b);
}



//###############################################################################
//                      灯光漫反射算法合集                                      
//###############################################################################
half3 LightDiffuse(RenderToolboxInputData inputData, RenderToolboxSurfaceData surfaceData, Light light)
{
    half NdotL = max(dot(inputData.normalWS, light.direction), 0.0);
    half3 kd = surfaceData.diffColor * (half3(1.0, 1.0, 1.0) - surfaceData.specColor);
    return kd * INV_PI * NdotL * light.color * light.shadowAttenuation * light.distanceAttenuation;
}

half3 LightDiffuse(RenderToolboxInputData inputData, RenderToolboxSurfaceData surfaceData)
{
    half3 totalLight = half3(0.0, 0.0, 0.0);
    //主光源漫反射部分
    Light mainLight = GetMainLight(inputData.shadowCoords);
    totalLight += LightDiffuse(inputData, surfaceData, mainLight);
    // //其他光源漫反射部分
    // for (int i = 0; i < GetAdditionalLightsCount(); i++)
    // {
    //     Light additionalLight = GetAdditionalLight(inputData.shadowCoords, i);
    //     if (additionalLight.color == half3(0.0, 0.0, 0.0))
    //         break;
    //     totalLight += LightDiffuse(inputData, surfaceData, additionalLight);
    // }
    return totalLight;
}

//###############################################################################
//                      灯光镜面反射算法合集                                      
//###############################################################################
float normal_distrib(float ndh, float Roughness)
{
    // use GGX / Trowbridge-Reitz, same as Disney and Unreal 4
    // cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
    float alpha = Roughness * Roughness;
    float tmp = alpha / max(1e-8, (ndh * ndh * (alpha * alpha - 1.0) + 1.0));
    return tmp * tmp * INV_PI;
}

float G1(float ndw, float k) // w is either Ln or Vn
{
    // One generic factor of the geometry function divided by ndw
    // NB : We should have k > 0
    return 1.0 / (ndw * (1.0 - k) + k);
}

float visibility(float ndl, float ndv, float Roughness)
{
    // Schlick with Smith-like choice of k
    // cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
    // visibility is a Cook-Torrance geometry function divided by (n.l)*(n.v)
    float k = Roughness * Roughness * 0.5;
    return G1(ndl, k) * G1(ndv, k);
}

//F
half3 fresnel(float vdh, half3 F0)
{
    // Schlick with Spherical Gaussian approximation
    // cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
    float sphg = pow(2.0, (-5.55473 * vdh - 6.98316) * vdh);
    return F0 + ((half3)1.0 - F0) * sphg;
}

half3 LightSpecular(RenderToolboxInputData inputData, RenderToolboxSurfaceData surfaceData, Light light)
{
    half3 Vn = inputData.viewDirWS;
    half3 Ln = light.direction;
    half3 Nn = inputData.normalWS;
    half3 Ks = surfaceData.specColor;
    float Roughness = surfaceData.roughness;
    half3 Hn = normalize(Vn + Ln);
    float vdh = max(0.00001, dot(Vn, Hn));
    float ndh = max(0.00001, dot(Nn, Hn));
    float ndl = max(0.00001, dot(Nn, Ln));
    float ndv = max(0.00001, dot(Nn, Vn));
    return fresnel(vdh, Ks) * (normal_distrib(ndh, Roughness) * visibility(ndl, ndv, Roughness) / 4.0) * ndl * light.color * light.shadowAttenuation * light.distanceAttenuation;
}

//###############################################################################
//                      环境光光漫反射算法合集                                      
//###############################################################################
float3 IrradianceDiffuse(RenderToolboxInputData inputData, RenderToolboxSurfaceData surfaceData)
{
    half3 GI = SampleSH(inputData.normalWS);
    return surfaceData.diffColor * (1 - surfaceData.specColor) * GI;
}

//###############################################################################
//                      环境光光镜面反射算法合集                                      
//###############################################################################
float3 lut_function(float roughness, float ndotv, float3 f0)
{
    float4 t = roughness * float4(-1.0, -0.0275, -0.572, 0.022) + float4(1.0, 0.0425, 1.04, -0.04);
    float s = min(t.x * t.x, exp2(ndotv * -9.28)) * t.x + t.y;
    float2 scale = s * float2(-1.04, 1.04) + t.zw;
    float3 bias = saturate(50.0 * f0.y) * scale.yyy;
    float3 lut = f0.xyz * scale.xxx + bias;
    return lut;
}

half3 IrradianceSpecular(RenderToolboxInputData inputData, RenderToolboxSurfaceData surfaceData)
{
    //此算法来自战双帕弥什
    half3 lut = lut_function(surfaceData.roughness, inputData.ndotv, surfaceData.specColor);
    float mip = surfaceData.roughness * (1.7 - 0.7 * surfaceData.roughness) * UNITY_SPECCUBE_LOD_STEPS;
    float4 indirectionCube = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, inputData.reflectDirWS, mip);
    half3 reflectCube = indirectionCube.xyz * indirectionCube.w * lut;
    return reflectCube;
}

//###############################################################################
//                      光照合成算法合集                                      
//###############################################################################
// 综合漫反射光照
half3 GetDiffuseLighting(RenderToolboxInputData inputData, RenderToolboxSurfaceData surfaceData)
{
    half3 totalLight = half3(0.0, 0.0, 0.0);
    //环境光漫反射部分
    half3 irradianceDiff = IrradianceDiffuse(inputData, surfaceData);
    totalLight += irradianceDiff;
    //主光源漫反射部分
    Light mainLight = GetMainLight(inputData.shadowCoords);
    totalLight += LightDiffuse(inputData, surfaceData, mainLight);
    //其他光源漫反射部分
    for (int i = 0; i < GetAdditionalLightsCount(); i++)
    {
        Light additionalLight = GetAdditionalLight(i,inputData.positionWS);
        totalLight += LightDiffuse(inputData, surfaceData, additionalLight);
    }
    return totalLight;
}
// 综合漫反射光照（带次表面散射）
half3 GetDiffuseLighting(RenderToolboxInputData inputData, RenderToolboxSurfaceData surfaceData, float4 scattering)
{
    float noise = GetBlueNoise(inputData.positionCS.xy * 0.01, 0.0);
    return surfaceData.diffColor * sssConvolve(inputData, scattering, noise);
}
// 综合镜面反射光照
half3 GetSpecularLighting(RenderToolboxInputData inputData, RenderToolboxSurfaceData surfaceData)
{
    half3 totalLight = half3(0.0, 0.0, 0.0);
    //环境光镜面反射部分
    half3 irradianceSpec = IrradianceSpecular(inputData, surfaceData);
    totalLight += irradianceSpec;
    //主光源镜面反射部分
    Light mainLight = GetMainLight(inputData.shadowCoords);
    totalLight += LightSpecular(inputData, surfaceData, mainLight);
    // //其他光源镜面反射部分
    // for (int i = 0; i < GetAdditionalLightsCount(); i++)
    // {
    //     Light additionalLight = GetAdditionalLight(inputData.shadowCoords, i);
    //     if (additionalLight.color == half3(0.0, 0.0, 0.0))
    //         break;
    //     totalLight += LightSpecular(inputData, surfaceData, additionalLight);
    // }
    return totalLight;
}
#endif
