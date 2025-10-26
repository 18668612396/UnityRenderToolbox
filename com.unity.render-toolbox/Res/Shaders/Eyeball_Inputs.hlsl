#ifndef NEMO_CHARACTER_CLOTH_INPUT_INCLUDED
#define NEMO_CHARACTER_CLOTH_INPUT_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
CBUFFER_START(UnityPerMaterial)
    half4 _Color;
    half _ColorIntensity;
    half _Smoothness;
    half _Metallic;
    half _NormalIntensity;

    half4 _PupilColor;
    half _PupilSize;
    half _PupilFeather;
    half _PupilInsideSmoothness;
    half _ScleraSmoothness;
    half _PupilHeight;
    half3 _OffsetW;
    half _RefractStrength;
    //眼角膜参数
    half _CorneaSmoothness;
CBUFFER_END

half4 _SubSurfaceScatteringDiffuse_TexelSize;

TEXTURE2D(_PupilBaseMap);
SAMPLER(sampler_PupilBaseMap);
TEXTURE2D(_PupilNormalMap);
SAMPLER(sampler_PupilNormalMap);
TEXTURE2D(_ScleraBaseMap);
SAMPLER(sampler_ScleraBaseMap);
TEXTURE2D(_SecondBaseMap);

TEXTURECUBE(_CorneaCubemap);
SAMPLER(sampler_CorneaCubemap);

TEXTURE2D_ARRAY(_DetailTextureArray);
SAMPLER(sampler_DetailTextureArray);
#endif
