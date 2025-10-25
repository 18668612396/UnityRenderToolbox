#ifndef NEMO_COMMON_COMMON_INPUTS_INCLUDED
#define NEMO_COMMON_COMMON_INPUTS_INCLUDED

struct RenderToolboxInputData
{
    float3 positionWS;
    float3 normalWS;
    float3 viewDirWS;
    float3 reflectDirWS;
    float4 shadowCoords;
    float2 screenUV;
    float4 positionCS;
    //记录点乘
    float ndotv; // dot(normalWS, viewDirWS)
};

RenderToolboxInputData GetRenderToolboxInputData(float4 positionCS, float3 positionWS, float3 normalWS, float3 viewDirWS, float4 screenPos, float4 shadowCoords)
{
    RenderToolboxInputData inputData = (RenderToolboxInputData)0;
    inputData.screenUV = screenPos.xy / screenPos.w;
    inputData.positionCS = positionCS;
    inputData.positionWS = positionWS;
    inputData.normalWS = normalize(normalWS);
    inputData.viewDirWS = normalize(viewDirWS);
    inputData.shadowCoords = shadowCoords;
    inputData.reflectDirWS = normalize(reflect(-inputData.viewDirWS, inputData.normalWS));
    inputData.ndotv = max(0.00001, dot(inputData.normalWS, inputData.viewDirWS));
    return inputData;
}

struct RenderToolboxSurfaceData
{
    bool isUI; // 是否是UI,如果在UI中，則光照始終跟随相机
    half3 baseColor;
    half metallic;
    half roughness;
    half occlusion; // Ambient Occlusion
    half3 diffColor; //baseColor * (1.0 - metallic);
    half3 specColor; //lerp(0.04, baseColor, metallic);
};

RenderToolboxSurfaceData GetRenderToolboxSurfaceData(half3 baseCoor, half metallic, half roughness, half occlusion)
{
    RenderToolboxSurfaceData surfaceData = (RenderToolboxSurfaceData)0;
    surfaceData.baseColor = baseCoor;
    surfaceData.metallic = metallic;
    surfaceData.roughness = roughness;
    surfaceData.occlusion = occlusion;
    surfaceData.diffColor = baseCoor * (1.0 - metallic);
    surfaceData.specColor = lerp(half3(0.04, 0.04, 0.04), baseCoor, metallic);
    return surfaceData;
}
#endif
