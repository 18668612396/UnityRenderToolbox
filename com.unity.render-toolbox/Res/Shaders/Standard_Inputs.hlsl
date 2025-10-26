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

    float _DetailArea0_BaseSmoothness;
    float _DetailArea1_BaseSmoothness;
    float _DetailArea2_BaseSmoothness;
    float _DetailArea3_BaseSmoothness;

    float _DetailArea0_DetailSmoothness;
    float _DetailArea1_DetailSmoothness;
    float _DetailArea2_DetailSmoothness;
    float _DetailArea3_DetailSmoothness;

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
