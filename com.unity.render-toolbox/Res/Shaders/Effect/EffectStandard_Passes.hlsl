#ifndef EFFECT_STANDARD_PASSES_INCLUDED
#define EFFECT_STANDARD_PASSES_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// 顶点输入属性结构体
// 存储模型空间下的顶点数据，包括位置、颜色、法线等基础信息
struct Attributes
{
    float4 positionOS : POSITION; // 模型空间顶点位置
    float4 Color : COLOR; // 顶点颜色
    float4 normalOS : NORMAL; // 模型空间法线
    float4 tangentOS : TANGENT; // 模型空间切线
    float4 texcoord0 : TEXCOORD00; // 基础纹理坐标
    float4 custom01 : TEXCOORD01; // 自定义数据通道1
    float4 custom02 : TEXCOORD02; // 自定义数据通道2
};

// 顶点到片段的输出结构体
// 存储需要传递给片段着色器的插值数据
struct Varyings
{
    float4 positionCS : SV_POSITION; // 裁剪空间顶点位置
    float4 uv : TEXCOORD00; // 主纹理坐标
    float4 color : COLOR; // 顶点颜色（插值后）
    float2 mask_uv : MASK_UV; // 遮罩纹理坐标
    float2 dissolve_uv : DISSOLVE_UV; // 溶解纹理坐标
    float2 distortion_uv : DISTORTION_UV; // 流动纹理坐标
    float4 custom01 : TEXCOORD01; // 自定义数据1（插值后）
    float4 custom02 : TEXCOORD02; // 自定义数据2（插值后）
    float4 tangentWS : TEXCOORD03; // 世界空间切线（w分量存储世界位置x）
    float4 bitangentWS : TEXCOORD04; // 世界空间副切线（w分量存储世界位置y）
    float4 normalWS : TEXCOORD05; // 世界空间法线（w分量存储世界位置z）
    float4 screenPos : TEXCOORD06; // 屏幕空间位置
    float4 second_uv : TEXCOORD07; // 第二纹理坐标
    float2 base_uv : TEXCOORD08; // 基础纹理坐标（未经过动画处理）
    float2 ramp_uv : TEXCOORD09; // 渐变纹理坐标
};

// 顶点着色器
// 处理顶点变换、UV动画、顶点动画等，输出插值数据到片段着色器
Varyings Vertex(Attributes input)
{
    Varyings output = (Varyings)0;

    // 计算主纹理UV动画（包含旋转和位移）
    float2 mainAnimation = ApplyUVAnimation(
        _MainAnimationSource,
        input.custom01,
        _MainAnimationCustomDataChannel01,
        input.custom02,
        _MainAnimationCustomDataChannel02,
        _MainTex_ST
    );
    output.uv.xy = RotateTextureUV(TRANSFORM_TEX(input.texcoord0, _MainTex), _MainRotationParams) + mainAnimation;

    // 计算第二纹理UV动画
    float2 secondAnimation = ApplyUVAnimation(
        _SecondAnimationSource,
        input.custom01,
        _SecondAnimationCustomDataChannel01,
        input.custom02,
        _SecondAnimationCustomDataChannel02,
        _SecondTex_ST
    );
    output.second_uv.xy = RotateTextureUV(TRANSFORM_TEX(input.texcoord0, _SecondTex) + secondAnimation, _SecondRotationParams);
    output.second_uv.zw = TRANSFORM_TEX(input.texcoord0, _SecondDissolveTex);

    // 计算遮罩纹理UV动画
    float2 maskAnimation = ApplyUVAnimation(
        _MaskAnimationSource,
        input.custom01,
        _MaskAnimationCustomDataChannel01,
        input.custom02,
        _MaskAnimationCustomDataChannel02,
        _MaskTex_ST
    );
    output.mask_uv = RotateTextureUV(TRANSFORM_TEX(input.texcoord0, _MaskTex), _MaskRotationParams) + maskAnimation;

    // 溶解纹理UV（带旋转）
    output.dissolve_uv = RotateTextureUV(TRANSFORM_TEX(input.texcoord0, _DissolveTex), _DissolveRotationParams);

    // 流动纹理UV动画
    float2 distortionAnimation = ApplyUVAnimation(
        _DistortionAnimationSource,
        input.custom01,
        _DistortionAnimationCustomDataChannel01,
        input.custom02,
        _DistortionAnimationCustomDataChannel02,
        _DistortionTex_ST
    );
    output.distortion_uv = RotateTextureUV(TRANSFORM_TEX(input.texcoord0, _DistortionTex), _DistortionRotationParams) + distortionAnimation;

    // 计算流动向量（从流动纹理采样）
    float distortionVector = 0;
    if (_EnableDistortion)
    {
        half sample_distortion01 = SAMPLE_TEXTURE2D_LOD(_DistortionTex, sampler_DistortionTex, output.distortion_uv.xy, 0).x;
        distortionVector = sample_distortion01 * 2 - 1; // 转换为[-1,1]范围
    }

    // 顶点动画处理
    float3 positionOS = input.positionOS.xyz;
    float4 vertexAnimationStrength = _VertexAnimationStrength;

    // 根据动画强度来源，从自定义数据通道获取强度值
    if (_VertexAnimationStrengthSource > 0.5 && _VertexAnimationStrengthSource < 1.5)
    {
        vertexAnimationStrength.x = input.custom01[_VertexAnimationStrengthCustomDataChannel01 - 1];
        vertexAnimationStrength.y = input.custom01[_VertexAnimationStrengthCustomDataChannel02 - 1];
        vertexAnimationStrength.z = input.custom01[_VertexAnimationStrengthCustomDataChannel03 - 1];
    }
    else if (_VertexAnimationStrengthSource > 1.5)
    {
        vertexAnimationStrength.x = input.custom02[_VertexAnimationStrengthCustomDataChannel01 - 1];
        vertexAnimationStrength.y = input.custom02[_VertexAnimationStrengthCustomDataChannel02 - 1];
        vertexAnimationStrength.z = input.custom02[_VertexAnimationStrengthCustomDataChannel03 - 1];
    }

    // 根据动画类型应用顶点位移
    if (vertexAnimationStrength.w < 0.5) // 基于法线方向的顶点动画
    {
        positionOS += input.normalOS.xyz * vertexAnimationStrength * distortionVector;
    }
    else if (vertexAnimationStrength.w > 0.5 && vertexAnimationStrength.w < 1.5) // 基于模型空间的顶点动画
    {
        positionOS += vertexAnimationStrength * distortionVector;
    }

    // 计算世界空间位置和法线
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS);
    float3 positionWS = vertexInput.positionWS;

    // 世界空间下的顶点动画
    if (vertexAnimationStrength.w > 1.5 && vertexAnimationStrength.w < 2.5)
    {
        positionWS += vertexAnimationStrength * distortionVector;
    }

    // 传递世界空间切线、副切线、法线（w分量存储世界位置）
    output.tangentWS = float4(normalInput.tangentWS, positionWS.x);
    output.bitangentWS = float4(normalInput.bitangentWS, positionWS.y);
    output.normalWS = float4(normalInput.normalWS, positionWS.z);

    // 传递基础数据
    output.color = input.Color;
    output.custom01 = input.custom01;
    output.custom02 = input.custom02;
    if (_EnableScreenParticle > 0.5)
    {
        float2 ndc_xy = input.texcoord0.xy * 2.0 - 1.0;// 2. 构建最终的裁剪空间位置
        #if UNITY_UV_STARTS_AT_TOP
        // 如果平台是 D3D (或其他 y 轴在顶部的)
        // 就翻转传递给片元着色器的 Y 轴
        ndc_xy.y *= -1.0;
        #endif
        // xy = 我们刚算好的NDC坐标
        // z = 0.0  (放在近裁剪平面上。对于粒子特效无所谓，0.5 也可以)
        // w = 1.0  (必须为1，这样 xy 就等于 NDC 坐标)
        output.positionCS = float4(ndc_xy, 0.0, 1.0);
    }
    else
    {
        output.positionCS = TransformWorldToHClip(positionWS); // 转换到裁剪空间
    }
    output.screenPos = ComputeScreenPos(output.positionCS); // 计算屏幕位置
    output.base_uv = input.texcoord0.xy; // 存储原始UV用于后续计算

    // 渐变纹理UV（带旋转）
    output.ramp_uv = RotateTextureUV(input.texcoord0, _RampMapRotationParams);

    return output;
}

// 片段着色器
// 处理像素级效果，包括纹理采样、颜色混合、溶解、法线光照等
half4 Fragment(Varyings input) : SV_Target
{
    half3 finalRGB = 0;
    half finalAlpha = 1;

    // 流动向量计算（仅在启用时）
    float2 distortionVector = float2(0.0, 0.0);
    #if _ENABLE_DISTORTION_ON
    {
        //扭曲必须要是法线贴图
        half2 sample_distortion = SAMPLE_TEXTURE2D(_DistortionTex, sampler_DistortionTex, input.distortion_uv.xy).xy;
        // distortionVector = sample_distortion - 1.0;  // 转换流动方向
        distortionVector = sample_distortion * 2.0 - 1.0;
        // 流动调试模式：直接输出流动纹理采样结果
        if (_EnableDistortionDebuger)
        {
            return half4(sample_distortion.xxx, 1);
        }
    }
    #endif

    // 主纹理采样与颜色计算
    float2 main_uv = ApplyDistortion(input.uv.xy, distortionVector, _DistortionIntensityToMultiMap.x);
    half4 sample_main = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, main_uv);
    // 主纹理颜色 = 纹理颜色 * 主色调 * 顶点颜色 * 强度
    finalRGB = sample_main.rgb * _MainTexColor.rgb * input.color.rgb * _MainTexIntensity;
    finalAlpha = sample_main.a * _MainTexColor.a * input.color.a;

    // 第二纹理处理（仅在启用时）
    #if _ENABLE_SECOND_ON
    {
        // 第二纹理UV（应用流动扭曲）
        float2 second_uv = ApplyDistortion(input.second_uv.xy, distortionVector, _DistortionIntensityToMultiMap.y);
        half4 sample_second = SAMPLE_TEXTURE2D(_SecondTex, sampler_SecondTex, second_uv);
        half4 secondColor = 1;

        // 第二纹理颜色计算（渐变模式或直接采样）
        if (_EnableSecondGradient > 0.5)
        {
            // 基于指定通道插值两种颜色
            secondColor = lerp(_SecondColor01, _SecondColor02, sample_second[_SecondGradientChannel]);
        }
        else
        {
            // 直接使用纹理颜色乘以第二色调
            secondColor = sample_second * _SecondColor01;
        }

        // 第二纹理溶解效果
        half secondAlpha = 1;
        if (_EnableSecondDissolve > 0.5)
        {
            float dissolveValue;
            {
                // 溶解阈值来源（参数/顶点颜色/自定义数据）
                float4 source;
                source.x = _SecondDissolveThreshold;
                source.y = input.color.a;
                source.z = input.custom01[_SecondDissolveCustomDataChannel];
                source.w = input.custom02[_SecondDissolveCustomDataChannel];
                dissolveValue = 1 - source[_SecondDissolveSource];
            }

            // 溶解颜色混合
            half4 dissolveColor = 0;
            dissolveColor.rgb = lerp(secondColor.xyz, _SecondDissolveColor.xyz, _SecondDissolveColor.w);

            // 计算溶解因子（带边缘软化）
            float feather = max(_SecondDissolveSoftness, 9.99999975e-05); // 避免软化值为0
            half factor = GetDissolveFactor(sample_second.a, dissolveValue, feather);
            secondColor.rgb = lerp(dissolveColor, secondColor, factor);
            secondAlpha = factor;
        }
        else
        {
            secondAlpha = secondColor.a;
        }

        // 混合主纹理与第二纹理颜色
        finalRGB.rgb = lerp(finalRGB.rgb, secondColor, secondAlpha * input.color.a);

        // 混合透明度（根据模式选择）
        if (_EnableMultiMainAlpha)
        {
            // finalAlpha = finalAlpha * secondAlpha;  // 乘法混合（注释备用）
        }
        else
        {
            finalAlpha = lerp(finalAlpha, secondColor.a, secondAlpha); // 插值混合
        }
    }
    #endif

    // 渐变纹理处理（仅在启用时）
    #if _ENABLE_RAMP_ON
    {
        float2 ramp_uv = input.ramp_uv;

        // 根据来源调整渐变纹理UV（使用当前颜色/透明度作为采样坐标）
        if (_RampMapSource > 0.5)
        {
            float4 source = float4(finalRGB, finalAlpha);
            ramp_uv = float2(source[_RampMapSource - 1], 0.5);
        }

        // 采样渐变纹理并应用到最终颜色
        half4 sample_ramp = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, ramp_uv);
        finalRGB.rgb = finalRGB.rgb * sample_ramp.rgb * _RampIntensity;
        finalAlpha *= sample_ramp.a;

        // 渐变调试模式
        if (_EnableRampDebuger > 0.5)
        {
            return half4(sample_ramp.rgb, 1);
        }
    }
    #endif

    // 菲涅尔效果（仅在启用时）
    #if _ENABLE_FRESNEL_ON
    {
        // 从切线/法线的w分量重建世界空间位置
        float3 positionWS = float3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
        float3 viewDir = normalize(_WorldSpaceCameraPos - positionWS); // 视角方向

        // 计算菲涅尔因子（基于视角与法线的夹角）
        float fresnel = dot(viewDir, input.normalWS.xyz) * 0.5 + 0.5;
        // 菲涅尔参数（强度、软化范围、幂次）
        half4 fresnelIntensity = half4(_FresnelColorIntensity.xxx, _FresnelAlphaIntensity);
        half4 fresnelSoftnessMin = half4(_FresnelColorSoftnessMin.xxx, _FresnelAlphaSoftnessMin);
        half4 fresnelSoftnessMax = half4(_FresnelColorSoftnessMax.xxx, _FresnelAlphaSoftnessMax);

        // 计算最终菲涅尔因子（带软化过渡）
        half4 finalFresnel = smoothstep(fresnelSoftnessMin, fresnelSoftnessMax, fresnel) * fresnelIntensity;
        half4 fresnelColor = half4(_FresnelColor.rgb, _FresnelAlphaMode);
        half4 finalColor = half4(finalRGB, finalAlpha);

        // 混合菲涅尔颜色到最终颜色
        finalColor = lerp(finalColor, fresnelColor, finalFresnel);
        finalRGB = finalColor.rgb;
        finalAlpha = finalColor.a;

        // 菲涅尔调试模式
        if (_EnableFresnelDebuger > 0.5)
        {
            return finalFresnel;
        }
    }
    #endif

    // 遮罩效果（仅在启用时）
    #if _ENABLE_MASK_ON
    {
        // 遮罩UV（应用流动扭曲）
        float2 mask_uv = ApplyDistortion(input.mask_uv.xy, distortionVector, _DistortionIntensityToMultiMap.z);
        half sample_mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, mask_uv)[_MaskAlphaChannel];

        // 应用遮罩到透明度（支持反相和强度控制）
        finalAlpha *= lerp(1, lerp(sample_mask, 1 - sample_mask, _InvertMask), _MaskIntensity) * input.color.w;

        // 遮罩调试模式
        if (_EnableMaskDebuger)
        {
            return half4(sample_mask.xxx, 1);
        }
    }
    #endif

    // 溶解效果（仅在启用时）
    #if _ENABLE_DISSOLVE_ON
    {
        float dissolveValue;
        {
            // 溶解阈值来源（参数/顶点颜色/自定义数据）
            float4 source;
            source.x = _DissolveThreshold;
            source.y = input.color.a;
            source.z = input.custom01[_DissolveCustomDataChannel];
            source.w = input.custom02[_DissolveCustomDataChannel];
            dissolveValue = 1 - source[_DissolveSource];
        }

        // 溶解纹理UV（应用流动扭曲）
        float2 dissolve_uv = ApplyDistortion(input.dissolve_uv, distortionVector, _DistortionIntensityToMultiMap.w);
        half sample_dissolve = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, dissolve_uv)[_DissolveChannel];
        sample_dissolve = 1.0 - sample_dissolve; // 反转采样值以匹配溶解逻辑
        // 根据方向计算溶解因子
        half dissolve = 1;
        if (_DissolveDirection == 0)
        {
            dissolve = sample_dissolve; // 基于纹理本身
        }
        else if (_DissolveDirection == 1)
        {
            dissolve = input.base_uv.x + sample_dissolve; // 基于U方向
        }
        else if (_DissolveDirection == 2)
        {
            dissolve = input.base_uv.y + sample_dissolve; // 基于V方向
        }

        // 溶解颜色混合
        half4 dissolveColor = 0;
        dissolveColor.rgb = lerp(finalRGB.xyz, _DissolveColor.xyz, _DissolveColor.w);

        // 计算溶解因子（带边缘软化）
        float feather = max(_DissolveSoftness, 9.99999975e-05); // 避免软化值为0
        half factor = GetDissolveFactor(dissolve * lerp(1, finalAlpha, _DissolveBlendAlpha), dissolveValue, feather);
        finalRGB.rgb = lerp(dissolveColor, finalRGB, factor);
        finalAlpha *= factor;
    }
    #endif

    // 深度混合效果（仅在启用时）
    #if _ENABLE_DEPTHBLEND_ON
    {
        // 计算屏幕空间UV
        float2 screenUV = input.screenPos.xy / input.screenPos.w;

        // 采样场景深度并转换为线性深度
        float sceneDepthRaw = SampleSceneDepth(screenUV);
        float sceneDepth = LinearEyeDepth(sceneDepthRaw, _ZBufferParams);

        // 当前片段在观察空间的深度
        float fragmentDepth = input.positionCS.w;

        // 计算深度差值并生成过渡因子
        float depthDifference = sceneDepth - fragmentDepth;
        float intersectionFactor = saturate(depthDifference / _IntersectionSoftness); // 软化边缘

        // 根据混合模式应用深度效果
        if (_DepthBlendMode < 0.5)
        {
            finalAlpha *= intersectionFactor; // 影响透明度
        }
        else
        {
            finalRGB = lerp(_DepthBlendColor.rgb * finalRGB, finalRGB, intersectionFactor); // 影响颜色
        }
    }
    #endif

    // 最终颜色计算
    half4 finalColor = 1;

    // 根据混合模式输出最终颜色
    if (_BlendMode < 0.5)
    {
        finalColor = half4(finalRGB, finalAlpha); // 常规混合（带透明度）
    }
    else if (_BlendMode > 0.5 && _BlendMode < 1.5)
    {
        finalColor.rgb = finalRGB * finalAlpha; // 预乘透明度
    }
    else if (_BlendMode > 1.5)
    {
        finalColor.rgb = finalRGB;
        clip(finalAlpha - _Cutoff); // 裁剪（AlphaTest）
    }
    return finalColor;
}

#endif
