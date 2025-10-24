#ifndef NEMO_CHARACTER_CLOTH_PASSES_INCLUDED
#define NEMO_CHARACTER_CLOTH_PASSES_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-toolbox/Res/Shaders/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

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

half4 GetScatteringCoeffs(float2 uv)
{
    // half3 sss = get2DSample(_ScatteringMap, uv, disableFragment, cDefaultColor.mScattering).r * _ScatteringIntensity * _ScatteringColor;
    half3 sss = SAMPLE_TEXTURE2D(_ScatteringMap, sampler_ScatteringMap, uv).rgb * _ScatteringIntensity * _ScatteringColor.rgb * 0.01;
    half a = sss == 0.0 ? 0.0 : 1.0;
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

TEXTURE2D(_BlueNoiseTex);

// --- 所需的全局变量 (在 Pass 中声明) ---

// 您必须从 C# 脚本传入这个矩阵：
// shader.SetMatrix("projectionInverseMatrix", camera.projectionMatrix.inverse);
float4x4 projectionInverseMatrix; 
// --- 翻译后的函数 ---

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
    return TransformWorldToView(ReconstructPositionWS(tex_coord));
}
float3 sssGetPosition(float2 tex_coord)
{
    float depth = SampleSceneDepth(tex_coord); // 或使用 _DepthRT 如果自定义
    // 步骤 3: 计算 NDC 坐标（屏幕 UV 转换为 [-1, 1] 范围）
    float4 ndc = float4(tex_coord * 2.0 - 1.0, depth, 1.0);
    #if UNITY_UV_STARTS_AT_TOP  // 处理平台翻转（DirectX vs OpenGL）
    ndc.y *= -1.0;
    #endif

    // 步骤 4: 转换为 View Space 位置
    float4 viewPos = mul(UNITY_MATRIX_I_P, ndc); // UNITY_MATRIX_I_P 是逆投影矩阵
    viewPos /= viewPos.w; // 透视除法

    // 示例: 可视化 positionWS（转换为颜色以调试）
    return viewPos; // 偏移到 [0, 1] 范围显示
}
float3 sssConvolve(float2 screenUV,float4 d, float noise)
{
    float2 screenSize = _ScreenParams.xy;
    const float GOLD = 0.618034;
    float2 tex_coord = screenUV;
    float3 prevDiffuse = SAMPLE_TEXTURE2D(_SubSurfaceScatteringDiffuse, sampler_SubSurfaceScatteringDiffuse, tex_coord).rgb;
    // if (d.a <= 0.0)
    //     return prevDiffuse;

    // Importance sample along the largest RGB component
    float dmax = max(max(d.x, d.y), d.z);
    
    float dmin = min(min(d.x, d.y), d.z);
    float3 currPos = ReconstructPositionVS(tex_coord);
    // Scale sample distribution with z
    float dz = dmax / -currPos.z;
    float4x4 projectionMatrix = UNITY_MATRIX_P;
    // if (projectionMatrix[0][0] * projectionMatrix[1][1] * dz < 1e-4)
    //     return prevDiffuse;

    float3 X = 0.0, W = 0.0;
    int nbSamples = 16;
    
    for (float i = 0.0; i < nbSamples; i++)
    {
        // Fibonacci spiral
        float r = (i + 0.5) / nbSamples;
        float t = 2.0 * PI * (GOLD * i + noise);
        float icdf = samples_icdf(r, dz);
        float2 Coords = tex_coord + icdf * float2(projectionMatrix[0][0] * cos(t), projectionMatrix[1][1] * sin(t));
        float4 D = SAMPLE_TEXTURE2D(_SubSurfaceScatteringDiffuse, sampler_SubSurfaceScatteringDiffuse, Coords);
        // Re-weight samples with the scene 3D distance and SSS profile instead of 2D importance sampling weights
        // SSS mask in alpha
        float dist = distance(currPos, ReconstructPositionVS(Coords));
        if (dist > 0.0)
        {
            float3 Weights = D.a / samples_pdf(icdf, dz) * sss_pdf(dist, d.rgb);
            X += Weights * D.rgb;
            W += Weights;
        }
    }

    return float3(
        W.r < 1e-5 ? prevDiffuse.r : X.r / W.r,
        W.g < 1e-5 ? prevDiffuse.g : X.g / W.g,
        W.b < 1e-5 ? prevDiffuse.b : X.b / W.b);
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
    CharacterInputData inputData = GetNemoInputData(positionWS, normalWS, viewDirWS, input.shadowCoords);
    CharacterSurfaceData surfaceData = GetNemoSurfaceData(baseColor.rgb, metallic, roughness, occlusion, _IsUI);
    half3 lightDiffuseColor = LightDiffuse(inputData, surfaceData, mainLight);
    half3 lightSpecular = LightSpecular(inputData, surfaceData, mainLight);
    half3 irradianceDiffuse = IrradianceDiffuse(inputData, surfaceData);
    half3 irradianceSpecular = IrradianceSpecularNew(inputData, surfaceData);
    half4 finalColor;

    half3 sample_diffuse = SAMPLE_TEXTURE2D(_SubSurfaceScatteringDiffuse, sampler_SubSurfaceScatteringDiffuse, screenUV);
    half4 sssCoeffs = GetScatteringCoeffs(input.uv.xy);
    uint3 loadCoords = uint3(uint2(input.positionCS.xy) & 0xFF, 0);
    float noise = _BlueNoiseTex.Load(loadCoords).x * 2 - 1;
    half3 diffuseContrib = surfaceData.diffColor * sssConvolve(screenUV, sssCoeffs, noise);
    finalColor.rgb = diffuseContrib + lightSpecular + (irradianceSpecular) * surfaceData.occlusion;
    return half4(finalColor.rgb, alpha);
}

half4 SubSurfaceScatteringPassFragment(Varyings input, half facing : VFACE) : SV_TARGET
{
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
    CharacterInputData inputData = GetNemoInputData(positionWS, normalWS, viewDirWS, input.shadowCoords);
    CharacterSurfaceData surfaceData = GetNemoSurfaceData(baseColor.rgb, metallic, roughness, occlusion, _IsUI);
    surfaceData.diffColor = 1;
    surfaceData.specColor = 0;
    half3 lightDiffuseColor = LightDiffuse(inputData, surfaceData, mainLight);
    half3 lightSpecular = LightSpecular(inputData, surfaceData, mainLight);
    half3 irradianceDiffuse = IrradianceDiffuse(inputData, surfaceData);
    half3 irradianceSpecular = IrradianceSpecularNew(inputData, surfaceData);
    half4 finalColor;

    half3 totalLight = half3(0.0, 0.0, 0.0);
    for (int i = 0; i < GetAdditionalLightsCount(); ++i)
    {
        Light light = GetAdditionalLight(i,positionWS);
        totalLight += LightDiffuse(inputData, surfaceData, light);
    }
    totalLight += LightDiffuse(inputData, surfaceData, mainLight);
    totalLight +=  irradianceDiffuse * surfaceData.occlusion;
    return half4(totalLight.rgb, alpha);
}
#endif
