#ifndef NEMO_CHARACTER_CLOTH_INPUT_INCLUDED
#define NEMO_CHARACTER_CLOTH_INPUT_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
CBUFFER_START(UnityPerMaterial)
    half _Cutoff;
    half4 _Color;
    half _ColorIntensity;
    half _Smoothness;
    half _Metallic;
    half _NormalIntensity;

    half _EnableSecond;
    half4 _SecondColor;
    half _SecondColorIntensity;

    half _EnableDetailArray;
    int _DetailArea0_DetailIndex;
    int _DetailArea1_DetailIndex;
    int _DetailArea2_DetailIndex;
    int _DetailArea3_DetailIndex;

    half4 _DetailArea0_DetailColor;
    half4 _DetailArea1_DetailColor;
    half4 _DetailArea2_DetailColor;
    half4 _DetailArea3_DetailColor;

    half4 _DetailArea0_BaseColor;
    half4 _DetailArea1_BaseColor;
    half4 _DetailArea2_BaseColor;
    half4 _DetailArea3_BaseColor;

    float4 _DetailArea0_BaseMapMatrix;
    float4 _DetailArea1_BaseMapMatrix;
    float4 _DetailArea2_BaseMapMatrix;
    float4 _DetailArea3_BaseMapMatrix;

    float4 _DetailArea0_NormalMapMatrix;
    float4 _DetailArea1_NormalMapMatrix;
    float4 _DetailArea2_NormalMapMatrix;
    float4 _DetailArea3_NormalMapMatrix;

    half _DetailArea0_BaseSmoothness;
    half _DetailArea1_BaseSmoothness;
    half _DetailArea2_BaseSmoothness;
    half _DetailArea3_BaseSmoothness;

    half _DetailArea0_DetailSmoothness;
    half _DetailArea1_DetailSmoothness;
    half _DetailArea2_DetailSmoothness;
    half _DetailArea3_DetailSmoothness;

    half _DetailArea0_CustomFactor;
    half _DetailArea1_CustomFactor;
    half _DetailArea2_CustomFactor;
    half _DetailArea3_CustomFactor;

    int _DetailArea0_NormalIndex;
    int _DetailArea1_NormalIndex;
    int _DetailArea2_NormalIndex;
    int _DetailArea3_NormalIndex;

    half _DetailArea0_NormalIntensity;
    half _DetailArea1_NormalIntensity;
    half _DetailArea2_NormalIntensity;
    half _DetailArea3_NormalIntensity;
    half _DetailArea0_Enable;
    half _DetailArea1_Enable;
    half _DetailArea2_Enable;
    half _DetailArea3_Enable;

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
