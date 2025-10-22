#ifndef NEMO_COMMON_COMMON_SCENE_INCLUDED
#define NEMO_COMMON_COMMON_SCENE_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
TEXTURECUBE(_ReflectionCube);
SAMPLER(sampler_ReflectionCube);

struct CharacterInputData
{
    float3 positionWS;
    float3 normalWS;
    float3 viewDirWS;
    float3 reflectDirWS;
    float4 shadowCoords;
    //记录点乘
    float ndotv; // dot(normalWS, viewDirWS)
};

CharacterInputData GetNemoInputData(float3 positionWS, float3 normalWS, float3 viewDirWS, float4 shadowCoords)
{
    CharacterInputData inputData = (CharacterInputData)0;
    inputData.positionWS = positionWS;
    inputData.normalWS = normalize(normalWS);
    inputData.viewDirWS = normalize(viewDirWS);
    inputData.shadowCoords = shadowCoords;
    inputData.reflectDirWS = normalize(reflect(-inputData.viewDirWS, inputData.normalWS));
    inputData.ndotv = max(0.00001, dot(inputData.normalWS, inputData.viewDirWS));
    return inputData;
}

struct CharacterSurfaceData
{
    bool isUI;// 是否是UI,如果在UI中，則光照始終跟随相机
    half3 baseColor;
    half metallic;
    half roughness;
    half occlusion; // Ambient Occlusion
    half3 diffColor; //baseColor * (1.0 - metallic);
    half3 specColor; //lerp(0.04, baseColor, metallic);
};

CharacterSurfaceData GetNemoSurfaceData(half3 baseCoor, half metallic, half roughness, half occlusion,bool isUI)
{
    CharacterSurfaceData surfaceData = (CharacterSurfaceData)0;
    surfaceData.baseColor = baseCoor;
    surfaceData.metallic = metallic;
    surfaceData.roughness = roughness;
    surfaceData.occlusion = occlusion;
    surfaceData.diffColor = baseCoor * (1.0 - metallic);
    surfaceData.specColor = lerp(half3(0.04, 0.04, 0.04), baseCoor, metallic);
    surfaceData.isUI = isUI;
    return surfaceData;
}


float normal_distrib(float ndh, float Roughness)
{
    // use GGX / Trowbridge-Reitz, same as Disney and Unreal 4
    // cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
    float alpha = Roughness * Roughness;
    float tmp = alpha / max(1e-8, (ndh * ndh * (alpha * alpha - 1.0) + 1.0));
    return tmp * tmp * INV_PI;
}

//G
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

half4 fresnel(float vdh, half4 F0)
{
    // Schlick with Spherical Gaussian approximation
    // cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
    float sphg = pow(2.0, (-5.55473 * vdh - 6.98316) * vdh);
    return F0 + ((half4)1.0 - F0) * sphg;
}


//直接光漫反射？？？
half4 microfacets_contrib(float vdh, float ndh, float ndl, float ndv, half4 Ks, float Roughness)
{
    // This is the contribution when using importance sampling with the GGX based
    // sample distribution. This means ct_contrib = ct_brdf / ggx_probability
    return fresnel(vdh, Ks) * (visibility(ndl, ndv, Roughness) * vdh * ndl / ndh);
}

half3 LightDiffuse(CharacterInputData inputData, CharacterSurfaceData surfaceData, Light light)
{
    half NdotL = max(dot(inputData.normalWS, light.direction), 0.0);
    half3 kd = surfaceData.diffColor * (half3(1.0, 1.0, 1.0) - surfaceData.specColor);
    return kd * INV_PI * NdotL * light.color * light.shadowAttenuation * light.distanceAttenuation;
}
half3 LightSpecular(CharacterInputData inputData, CharacterSurfaceData surfaceData, Light light)
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

half3 LightContribution(CharacterInputData inputData, CharacterSurfaceData surfaceData, Light light)
{
    // Note that the lamp intensity is using ˝computer games units" i.e. it needs
    // to be multiplied by M_PI.
    // Cf https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
    half3 diffuse_brdf = LightDiffuse(inputData, surfaceData, light);
    half3 spec_brdf = LightSpecular(inputData,surfaceData,light);
    spec_brdf = min(spec_brdf, 1); // todo : 模型会大于1，所以要钳制一下
    return max(dot(inputData.normalWS, light.direction), 0.0) * ((diffuse_brdf + spec_brdf) * light.color * light.shadowAttenuation * light.distanceAttenuation);
}

//上述是灯光的贡献，下面是环境光的贡献
//LUT拟合曲线
float2 envBRDFApprox(const in float _NoV, in float _roughness)
{
    const float4 c0 = float4(-1.0, -0.0275, -0.572, 0.022);
    const float4 c1 = float4(1.0, 0.0425, 1.04, -0.04);
    float4 r = _roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * _NoV)) * r.x + r.y;
    float2 AB = float2(-1.04, 1.04) * a004 + r.zw;
    return float2(AB.x, AB.y);
}

half ComputeCubemapMipFromRoughness(half Roughness, half MipCount)
{
    // Level starting from 1x1 mip
    half Level = 3 - 1.15 * log2(Roughness);
    return MipCount - 1 - Level;
}

// [Karis 2013, "Real Shading in Unreal Engine 4" slide 11]
half3 EnvBRDF(TEXTURE2D_PARAM(_Texture, sampler_Texture), half3 SpecularColor, half Roughness, half NoV)
{
    // Importance sampled preintegrated G * F
    float2 AB = SAMPLE_TEXTURE2D_LOD(_Texture, sampler_Texture, float2( NoV, Roughness ), 0).rg;

    // Anything less than 2% is physically impossible and is instead considered to be shadowing 
    float3 GF = SpecularColor * AB.x + saturate(50.0 * SpecularColor.g) * AB.y;
    return GF;
}

// Computes the specular term for EnvironmentBRDF
half3 EnvironmentBRDFSpecular(float roughness2, half3 specular, half3 grazingTerm, half fresnelTerm)
{
    float surfaceReduction = 1.0 / (roughness2 + 1.0);
    return surfaceReduction * lerp(specular, grazingTerm, fresnelTerm);
}

float3 fresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

//间接光漫反射
float3 IrradianceDiffuse(CharacterInputData inputData, CharacterSurfaceData surfaceData)
{
    half3 GI = SampleSH(inputData.normalWS);
    return surfaceData.diffColor * (1 - surfaceData.specColor) * GI;
}
float3 lut_function(float roughness, float ndotv, float3 f0)
{
    float4 t = roughness * float4(-1.0, -0.0275, -0.572, 0.022) + float4(1.0, 0.0425, 1.04, -0.04);
    float s = min(t.x * t.x, exp2(ndotv * -9.28)) * t.x + t.y;
    float2 scale = s * float2(-1.04, 1.04) + t.zw;
    float3 bias = saturate(50.0 * f0.y) * scale.yyy;
    float3 lut = f0.xyz * scale.xxx + bias;
    return lut;
}
//此算法来自战双帕弥什
half3 IrradianceSpecularNew(CharacterInputData inputData, CharacterSurfaceData surfaceData)
{
    half3 lut = lut_function(surfaceData.roughness, inputData.ndotv, surfaceData.specColor);
    float mip = surfaceData.roughness * (1.7 - 0.7 * surfaceData.roughness) * UNITY_SPECCUBE_LOD_STEPS;
    float4 indirectionCube = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, inputData.reflectDirWS, mip);
    half3 reflectCube = indirectionCube.xyz * indirectionCube.w  * lut ;
    return reflectCube;
}
//此算法来自Unreal Engine 4
// https://www.unrealengine.com/zh-CN/blog/physically-based-shading-on-mobile
half3 IrradianceSpecular(CharacterInputData inputData, CharacterSurfaceData surfaceData)
{
    // float UNITY_SPECCUBE_LOD_STEPS = 6.0;
    float mip = surfaceData.roughness * (1.7 - 0.7 * surfaceData.roughness) * UNITY_SPECCUBE_LOD_STEPS;
    float4 indirectionCube = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, inputData.reflectDirWS, mip) ;
    // indirectionCube.rgb = DecodeHDREnvironment(indirectionCube,unity_SpecCube0_HDR);
    float2 envBRDF = envBRDF = envBRDFApprox(inputData.ndotv, surfaceData.roughness);
    float3 F_IndirectionLight = fresnel(inputData.ndotv, surfaceData.specColor);
    float3 indirectionSpecFactor = indirectionCube.rgb * (F_IndirectionLight * envBRDF.r + envBRDF.g);
    return indirectionSpecFactor;
}

//间接光照
half3 IrradianceLighting(CharacterInputData inputData, CharacterSurfaceData surfaceData)
{
    return (IrradianceDiffuse(inputData, surfaceData) + IrradianceSpecularNew(inputData, surfaceData)) * surfaceData.occlusion;
}

//总光照
half3 Lighting(CharacterInputData inputData, CharacterSurfaceData surfaceData)
{
    half3 totalLight = half3(0.0, 0.0, 0.0);
    //遍历所有光源
    /*
    for (int i = 0; i < unity_LightCount; ++i)
    {
        Light light = unity_Lights[i];
        if (light.type == LightType.Directional)
        {
            totalLight += LightContribution(inputData, surfaceData, light);
        }
    }
    */
    // totalLight += LightContribution(inputData, surfaceData, GetMainLight(inputData.shadowCoords));
    Light mainLight = GetMainLight();
    // mainLight.shadowAttenuation = saturate(GetObjectRealtimeShadow(inputData.positionWS) + 0.2);
    // mainLight.direction = surfaceData.isUI ? float3(inputData.viewDirWS.x,0.5,inputData.viewDirWS.z) : mainLight.direction;
    totalLight += LightContribution(inputData, surfaceData, mainLight);
    totalLight += max(0, IrradianceLighting(inputData, surfaceData));
    return totalLight;
}
#endif
