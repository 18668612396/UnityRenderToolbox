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
};

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
half GetPupilCoords(float2 uv)
{
    return uv / _PupilSize + float2(0.5, 0.5) - float2(0.5, 0.5) / _PupilSize;
}
half2 GetPupilMask(float2 uv)
{
    float2 uvFormCenter = uv - float2(0.5, 0.5);
    float dist = length(uvFormCenter);
    return smoothstep(_PupilSize / 2, _PupilSize / 2 - _PupilFeather, dist);
}
half4 LisPassFragment(Varyings input, half facing : VFACE) : SV_TARGET
{
    float2 pupilUV = input.uv.xy / _PupilSize + float2(0.5, 0.5) - float2(0.5, 0.5) / _PupilSize;
    float pupilMask = GetPupilMask(input.uv);
    half4 sample_pupil_base = SAMPLE_TEXTURE2D(_PupilBaseMap, sampler_PupilBaseMap, pupilUV);
    half4 sample_pupil_normal = SAMPLE_TEXTURE2D(_PupilNormalMap, sampler_PupilNormalMap, pupilUV);
    //采样基础贴图
    half4 sample_base = SAMPLE_TEXTURE2D(_ScleraBaseMap, sampler_ScleraBaseMap, input.uv.xy);

    //计算各自的法线
    float2 baseNormalTS = sample_pupil_normal.xy * 2.0 - 1.0;
    //计算切线空间法线
    float3 normalTS = float3(baseNormalTS, 1.0);
    normalTS.z = sqrt(saturate(1.0 - dot(normalTS.xy, normalTS.xy)));
    float3 inNormalWS = facing > 0 ? normalize(input.normalWS.xyz) : -normalize(input.normalWS.xyz);
    float3x3 tbn = float3x3(normalize(input.tangentWS.xyz), normalize(input.bitangentWS.xyz), inNormalWS);
    //准备向量
    float3 positionWS = float3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
    float3 normalWS = normalize(mul(normalTS, tbn));
    float3 viewDirWS = normalize(input.viewDirWS);
    //初始化SurfaceData
    float3 baseColor = lerp(sample_base,sample_pupil_base * _PupilColor, pupilMask);
    float smoothness = 0.5;
    float metallic = 0;
    float occlusion = 1;
    float roughness = 1.0 - smoothness;
    //PBR
    Light mainLight = GetMainLight();
    mainLight.distanceAttenuation = 1;
    RenderToolboxInputData inputData = GetRenderToolboxInputData(input.positionCS, positionWS, normalWS, viewDirWS, input.screenPos, input.shadowCoords);
    RenderToolboxSurfaceData surfaceData = GetRenderToolboxSurfaceData(baseColor.rgb, metallic, roughness, occlusion);
    half4 finalColor = 0;
    //先计算眼角膜相关的
    float3 reflectDirWS = normalize(reflect(-inputData.viewDirWS.xyz, normalize(input.normalWS.xyz)));
    finalColor.rgb += IrradianceSpecular(_CorneaCubemap, sampler_CorneaCubemap,reflectDirWS,inputData.ndotv,1.0 - _CorneaSmoothness,surfaceData.specColor);
    finalColor.rgb += IrradianceDiffuse(inputData,surfaceData);
    //虹膜+巩膜
    //本shader使用基于物理的折射算法来实现眼球的折射效果
    float3 refractedW = refract(-viewDirWS, input.normalWS, _RefractStrength);
    float cosAlpha = dot(input.normalWS, -refractedW);
    float dist = _PupilHeight / cosAlpha;
    float3 offsetW = dist * refractedW;
    float2 offsetL = mul(offsetW, (float3x2) UNITY_MATRIX_I_M);
    pupilUV += offsetL;
    
    return  SAMPLE_TEXTURE2D(_PupilBaseMap, sampler_PupilBaseMap, pupilUV);
    
    return finalColor;
    
}
#endif
