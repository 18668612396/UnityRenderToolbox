#ifndef NEMO_CHARACTER_CLOTH_PASSES_INCLUDED
#define NEMO_CHARACTER_CLOTH_PASSES_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-toolbox/Res/Shaders/Lighting.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 uv : TEXCOORD0;
    float4 tangentWS : TEXCOORD1;
    float4 bitangentWS : TEXCOORD2;
    float4 normalWS : TEXCOORD3;
    float4 viewDirWS : TEXCOORD4;
    float4 shadowCoords : TEXCOORD5;
    float4 screenPos : TEXCOORD6;
    // float4 tangentWS : TEXCOORD2;
    // float4 bitangentWS : TEXCOORD3;
    // float4 normalWS : TEXCOORD4;
    // float4 sh : TEXCOORD5;
    // float4 positionShadowSpace : TEXCOORD6;
    // float3 positionWS : TEXCOORD7;
    // float4 rimParams : TEXCOORD8;
};

// 确定细节层（使用NormalAO的W通道，完全按照原shader逻辑）
int GetDetailLayerFromNormalAlpha(float layerMask)
{
    // 原shader的精确逻辑
    bool4 greaterThanThresholds = layerMask >= float4(0.05, 0.25, 0.5, 0.75);
    bool4 lessThanUpperBounds = layerMask < float4(0.249, 0.499, 0.749, 1.0);
    bool4 inRange = greaterThanThresholds && lessThanUpperBounds;

    // 原shader的选择逻辑：从高优先级到低优先级
    int result = -1;
    // result = inRange.w ? 3 : int(0);
    // result = inRange.z ? 2 : result;
    // result = inRange.y ? 1 : result;
    // result = inRange.x ? 0 : result;

    result = layerMask >= 0.05 && layerMask < 0.25 ? 0 : result;
    result = layerMask >= 0.249 && layerMask < 0.499 ? 1 : result;
    result = layerMask >= 0.5 && layerMask < 0.749 ? 2 : result;
    result = layerMask >= 0.75 && layerMask <= 1.0 ? 3 : result;


    return result; // 默认层
}

half4 GetDetailColors(float index)
{
    half4 detailColor = half4x4(_DetailArea0_DiffuseColor, _DetailArea1_DiffuseColor, _DetailArea2_DiffuseColor, _DetailArea3_DiffuseColor)[index].rgba;
    half detailIntensity = half4(_DetailArea0_DiffuseIntensity, _DetailArea1_DiffuseIntensity, _DetailArea2_DiffuseIntensity, _DetailArea3_DiffuseIntensity)[index];
    if (index == -1)
    {
        return half4(1, 1, 1, 0);
    }
    return detailColor * detailIntensity;
}

float2 TransformDetailFormMatrix(float2 uv, float2x2 mat)
{
    float2 pivot = float2(0.5, 0.5);
    return mul(mat, uv - pivot) + pivot;
}

half GetDetailMask(float2 uv, float index)
{
    //采样细节贴图，这里是从数组采样出来的，他将会用于颜色混合以及光滑度混合，不会影响法线
    int detailMask_Index = int4(_DetailArea0_DetailIndex, _DetailArea1_DetailIndex, _DetailArea2_DetailIndex, _DetailArea3_DetailIndex)[index];
    float detailMaskEnable = float4(_DetailArea0_Enable, _DetailArea1_Enable, _DetailArea2_Enable, _DetailArea3_Enable)[index];
    float4 baseMapMatrix = float4x4(_DetailArea0_BaseMapMatrix, _DetailArea1_BaseMapMatrix, _DetailArea2_BaseMapMatrix, _DetailArea3_BaseMapMatrix)[index];
    if (index == -1)
    {
        return 0;
    }
    return SAMPLE_TEXTURE2D_ARRAY(_DetailTextureArray, sampler_DetailTextureArray, TransformDetailFormMatrix(uv,baseMapMatrix), detailMask_Index).x * detailMaskEnable;
}

half3 GetDetailNormal(float2 uv, float index)
{
    //采样细节贴图，这里是从数组采样出来的，他将会用于颜色混合以及光滑度混合，不会影响法线
    int detailNormal_Index = int4(_DetailArea0_NormalIndex, _DetailArea1_NormalIndex, _DetailArea2_NormalIndex, _DetailArea3_NormalIndex)[index];
    float detailMaskEnable = float4(_DetailArea0_Enable, _DetailArea1_Enable, _DetailArea2_Enable, _DetailArea3_Enable)[index];
    float4 normalMapMatrix = float4x4(_DetailArea0_NormalMapMatrix, _DetailArea1_NormalMapMatrix, _DetailArea2_NormalMapMatrix, _DetailArea3_NormalMapMatrix)[index];
    half3 detailNormal = SAMPLE_TEXTURE2D_ARRAY(_DetailTextureArray, sampler_DetailTextureArray, TransformDetailFormMatrix(uv,normalMapMatrix), detailNormal_Index).xyz;
    float detailNormalIntensity = float4(_DetailArea0_NormalIntensity, _DetailArea1_NormalIntensity, _DetailArea2_NormalIntensity, _DetailArea3_NormalIntensity)[index];
    if (index == -1)
    {
        return 0;
    }
    return (detailNormal * 2 - 1) * detailNormalIntensity * detailMaskEnable;
}

half GetDetailSmoothness(float index)
{
    float detailSmoothness = float4(_DetailArea0_Smoothness, _DetailArea1_Smoothness, _DetailArea2_Smoothness, _DetailArea3_Smoothness)[index];
    if (index == -1)
    {
        return 0;
    }
    return detailSmoothness;
}

Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.positionCS = vertexInput.positionCS;
    output.uv = float4(input.uv0, input.uv1);
    //TBNW
    output.tangentWS = float4(normalInput.tangentWS.xyz, vertexInput.positionWS.x);
    output.bitangentWS = float4(normalInput.bitangentWS.xyz, vertexInput.positionWS.y);
    output.normalWS = float4(normalInput.normalWS.xyz, vertexInput.positionWS.z);
    output.viewDirWS.xyz = normalize(_WorldSpaceCameraPos.xyz - vertexInput.positionWS);
    output.shadowCoords = GetShadowCoord(vertexInput);
    output.screenPos = ComputeScreenPos(output.positionCS);
    return output;
}

half4 LisPassFragment(Varyings input, half facing : VFACE) : SV_TARGET
{
    //获取屏幕空间uv
    float2 screenUV = input.screenPos.xy / input.screenPos.w;
    //采样基础贴图
    half4 sample_base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
    half alpha = sample_base.a * _Color.a;
    if (_UseAlphaTest > 0.5)
    {
        clip(sample_base.w - _Cutoff);
    }
    half4 sample_normal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv.xy);
    half4 sample_mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, input.uv.xy);
    //采样第二层纹理
    half4 sample_secondBase = SAMPLE_TEXTURE2D(_SecondBaseMap, sampler_SecondBaseMap, input.uv.zw);
    half4 sample_secondNormal = SAMPLE_TEXTURE2D(_SecondNormalMap, sampler_SecondNormalMap, input.uv.zw);
    half4 sample_secondMask = SAMPLE_TEXTURE2D(_SecondMaskMap, sampler_SecondMaskMap, input.uv.zw);
    //计算各自的法线
    float2 baseNormalTS = sample_normal.xy * 2.0 - 1.0;
    float2 secondNormalTS = (sample_secondNormal.xy * 2.0 - 1.0) * _EnableSecond * sample_secondBase.a;
    //计算细节
    int detailIndex = GetDetailLayerFromNormalAlpha(sample_normal.w);
    half detailMask = GetDetailMask(input.uv.xy, detailIndex);
    half4 detailColor = GetDetailColors(detailIndex);
    half detailSmoothness = GetDetailSmoothness(detailIndex);
    half3 detailNormal = GetDetailNormal(input.uv.xy, detailIndex);
    float2 detailNormalTS = detailNormal.xy;
    //计算切线空间法线
    float3 normalTS = float3(baseNormalTS, 1.0);
    normalTS.xy += lerp(detailNormalTS.xy, secondNormalTS.xy, sample_secondBase.a * _EnableSecond);
    normalTS.z = sqrt(saturate(1.0 - dot(normalTS.xy, normalTS.xy)));
    float3 inNormalWS = facing > 0 ? normalize(input.normalWS.xyz) : -normalize(input.normalWS.xyz);
    float3x3 tbn = float3x3(normalize(input.tangentWS.xyz), normalize(input.bitangentWS.xyz), inNormalWS);
    //准备向量
    float3 positionWS = float3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
    float3 normalWS = normalize(mul(normalTS, tbn));
    float3 viewDirWS = normalize(input.viewDirWS.xyz);
    //初始化SurfaceData
    float3 baseColor = sample_base.rgb * _Color.rgb * _ColorIntensity;
    baseColor = lerp(baseColor, detailColor.rgb * baseColor, detailMask); //混合细节贴图
    baseColor = lerp(baseColor, sample_secondBase.rgb, sample_secondBase.a * _EnableSecond); //混合第二层贴图
    float smoothness = sample_mask.r;
    smoothness = lerp(smoothness, detailSmoothness, detailMask); //混合细节贴图
    smoothness = lerp(smoothness, sample_secondMask.r, sample_secondBase.a * _EnableSecond); //混合第二层贴图
    float metallic = sample_mask.g;
    metallic = lerp(metallic, sample_secondMask.g, sample_secondBase.a * _EnableSecond); //混合第二层贴图
    float occlusion = sample_normal.b;
    occlusion = lerp(occlusion, sample_secondMask.b, sample_secondBase.a * _EnableSecond); //混合第二层贴图
    float roughness = 1.0 - smoothness;
    //PBR
    Light mainLight = GetMainLight();
    mainLight.distanceAttenuation = 1;
    RenderToolboxInputData inputData = GetRenderToolboxInputData(input.positionCS,positionWS,normalWS,viewDirWS,input.screenPos,input.shadowCoords);
    RenderToolboxSurfaceData surfaceData = GetRenderToolboxSurfaceData(baseColor.rgb, metallic, roughness, occlusion);

    half4 finalColor;
    //再计算漫反射部分
    half3 diffuseLighting = half3(0.0, 0.0, 0.0);
    #if _ENABLE_SSS
    {
        half4 scattering = GetScatteringCoeffs(input.uv.xy);
        diffuseLighting = GetDiffuseLighting(inputData, surfaceData, scattering);
    }
    #else
    {
        diffuseLighting = GetDiffuseLighting(inputData, surfaceData);
    }
    #endif
    //先计算镜面反射部分
    half3 specularLighting = half3(0.0, 0.0, 0.0);
    specularLighting += LightSpecular(inputData, surfaceData, mainLight);
    specularLighting += IrradianceSpecular(inputData, surfaceData);
    specularLighting *= surfaceData.occlusion;
    
    finalColor.rgb = diffuseLighting + specularLighting;
    return half4(finalColor.rgb, alpha);
}

half4 SubSurfaceScatteringPassFragment(Varyings input, half facing : VFACE) : SV_TARGET
{
    //采样基础贴图
    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy).a * _Color.a;
    if (_UseAlphaTest > 0.5)
    {
        clip(alpha - _Cutoff);
    }
    half4 sample_normal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv.xy);
    half4 sample_mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, input.uv.xy);
    //计算切线空间法线
    float3 normalTS = float3(sample_normal.xy * 2.0 - 1.0, 1.0);
    normalTS.z = sqrt(saturate(1.0 - dot(normalTS.xy, normalTS.xy)));
    float3 inNormalWS = facing > 0 ? normalize(input.normalWS.xyz) : -normalize(input.normalWS.xyz);
    float3x3 tbn = float3x3(normalize(input.tangentWS.xyz), normalize(input.bitangentWS.xyz), inNormalWS);
    //准备向量
    float3 positionWS = float3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
    float3 normalWS = normalize(mul(normalTS, tbn));
    float3 viewDirWS = normalize(input.viewDirWS.xyz);
    //初始化SurfaceData
    float smoothness = sample_mask.r;
    float metallic = sample_mask.g;
    float occlusion = sample_normal.b;
    float roughness = 1.0 - smoothness;
    //PBR
    RenderToolboxInputData inputData = GetRenderToolboxInputData(input.positionCS,positionWS,normalWS,viewDirWS,input.screenPos,input.shadowCoords);
    RenderToolboxSurfaceData surfaceData = GetRenderToolboxSurfaceData(1.0, metallic, roughness, occlusion);
    surfaceData.diffColor = 1;//只计算漫反射光源，不牵扯到漫反射贴图，这样才能保证仅对光照进行卷积计算
    surfaceData.specColor = 0;//不计算镜面反射部分
    return half4(GetDiffuseLighting(inputData, surfaceData), alpha);
}
#endif
