#ifndef NEMO_CHARACTER_CLOTH_INPUT_INCLUDED
#define NEMO_CHARACTER_CLOTH_INPUT_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
CBUFFER_START(UnityPerMaterial)
    half _IsUI;
    half _UseAlphaTest;
    half _Cutoff;
    half4 _Color;
    float _ColorIntensity;
    half _EnableSecond;

    half _DetailGroup;
    int _DetailArea0_DetailIndex;
    int _DetailArea1_DetailIndex;
    int _DetailArea2_DetailIndex;
    int _DetailArea3_DetailIndex;

    half4 _DetailArea0_DiffuseColor;
    half4 _DetailArea1_DiffuseColor;
    half4 _DetailArea2_DiffuseColor;
    half4 _DetailArea3_DiffuseColor;

    half _DetailArea0_DiffuseIntensity;
    half _DetailArea1_DiffuseIntensity;
    half _DetailArea2_DiffuseIntensity;
    half _DetailArea3_DiffuseIntensity;

    float4 _DetailArea0_BaseMapMatrix;
    float4 _DetailArea1_BaseMapMatrix;
    float4 _DetailArea2_BaseMapMatrix;
    float4 _DetailArea3_BaseMapMatrix;

    float4 _DetailArea0_NormalMapMatrix;
    float4 _DetailArea1_NormalMapMatrix;
    float4 _DetailArea2_NormalMapMatrix;
    float4 _DetailArea3_NormalMapMatrix;

    float _DetailArea0_Smoothness;
    float _DetailArea1_Smoothness;
    float _DetailArea2_Smoothness;
    float _DetailArea3_Smoothness;

    float _DetailArea0_CustomFactor;
    float _DetailArea1_CustomFactor;
    float _DetailArea2_CustomFactor;
    float _DetailArea3_CustomFactor;

    int _DetailArea0_NormalIndex;
    int _DetailArea1_NormalIndex;
    int _DetailArea2_NormalIndex;
    int _DetailArea3_NormalIndex;

    float _DetailArea0_NormalIntensity;
    float _DetailArea1_NormalIntensity;
    float _DetailArea2_NormalIntensity;
    float _DetailArea3_NormalIntensity;
    float _DetailArea0_Enable;
    float _DetailArea1_Enable;
    float _DetailArea2_Enable;
    float _DetailArea3_Enable;

    half4 _RimLightColor;
    half _RimLightPower;
    half _RimLightIntensity;

    half4 _ScatteringColor;
    half _ScatteringIntensity;
CBUFFER_END
    half4 _SubSurfaceScatteringDiffuse_TexelSize;

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);
TEXTURE2D(_MaskMap);
SAMPLER(sampler_MaskMap);
TEXTURE2D(_SecondBaseMap);
SAMPLER(sampler_SecondBaseMap);
TEXTURE2D(_SecondNormalMap);
SAMPLER(sampler_SecondNormalMap);
TEXTURE2D(_SecondMaskMap);
SAMPLER(sampler_SecondMaskMap);
TEXTURE2D(_SubSurfaceScatteringDiffuse);
SAMPLER(sampler_SubSurfaceScatteringDiffuse);
TEXTURE2D(_ScatteringMap);
SAMPLER(sampler_ScatteringMap);



TEXTURE2D_ARRAY(_DetailTextureArray);
SAMPLER(sampler_DetailTextureArray);
#endif
