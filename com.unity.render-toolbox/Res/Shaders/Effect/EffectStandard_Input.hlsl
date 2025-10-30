#ifndef EFFECT_STANDARD_INPUT_INCLUDED
#define EFFECT_STANDARD_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
    half _EnableScreenParticle; // 是否启用屏幕空间粒子效果（1=启用）
    // 基础渲染模式参数
    int _BlendMode; // 混合模式：控制透明度与颜色混合算法（0=正常,1=叠加等）
    float _Cutoff; // 裁剪阈值：用于Alpha Test，大于该值的像素可见
    // 主纹理（MainTex）参数
    float4 _MainTex_ST; // 主纹理缩放(xy)与偏移(zw)
    float4 _MainTexColor; // 主纹理叠加颜色（RGBA）
    float _MainTexIntensity; // 主纹理颜色强度（0=无效果,1=正常）
    float4 _MainRotationParams; // 主纹理旋转参数（x=角度,y=中心偏移）
    int _MainAnimationSource; // 主纹理动画源（0=时间驱动,1=自定义数据驱动）
    int _MainAnimationCustomDataChannel01; // 动画参数通道1（控制偏移）
    int _MainAnimationCustomDataChannel02; // 动画参数通道2（控制速度）
    float4 _MainAnimationChannelAndSpeed; // 动画通道选择与速度系数
    int _MainTexColorRampChannel; // 主纹理颜色渐变通道（0=R,1=G,2=B,3=A）

    // 第二纹理与渐变控制
    int _EnableMultiMainAlpha; // 是否启用多主纹理Alpha混合（1=启用）
    float _EnableSecondGradient; // 是否启用第二渐变（1=启用）
    int _SecondGradientChannel; // 第二渐变采样通道（0=R,1=G等）
    float4 _SecondColor01; // 第二渐变起始颜色
    float4 _SecondColor02; // 第二渐变结束颜色
    float4 _SecondTex_ST; // 第二纹理缩放与偏移
    float4 _SecondDissolveTex_ST; // 第二溶解纹理缩放与偏移
    float4 _SecondRotationParams; // 第二纹理旋转参数
    int _SecondAnimationSource; // 第二纹理动画源（同主纹理）
    int _ApplySecondAlpha; // 是否应用第二纹理的Alpha通道（1=应用）
    int _SecondAnimationCustomDataChannel01; // 第二纹理动画通道1
    int _SecondAnimationCustomDataChannel02; // 第二纹理动画通道2
    float _EnableSecondDissolve; // 是否启用第二溶解效果（1=启用）
    float4 _SecondDissolveColor; // 第二溶解边缘颜色
    int _SecondDissolveSource; // 第二溶解数据源（0=纹理,1=自定义数据）
    int _SecondDissolveCustomDataChannel; // 第二溶解数据通道
    float _SecondDissolveThreshold; // 第二溶解阈值（0=完全溶解,1=不溶解）
    float _SecondDissolveSoftness; // 第二溶解边缘柔和度（值越大边缘越模糊）

    // 法线与光照参数
    float4 _NormalMap_ST; // 法线贴图缩放与偏移
    float _EnableNormalMap; // 是否启用法线贴图（1=启用）
    half _NormalMapIntensity; // 法线贴图强度（0=无凹凸,1=正常）
    float4 _LightColor; // 主光源颜色
    float4 _ShadowColor; // 阴影叠加颜色

    // 流动效果（Distortion）参数
    float4 _DistortionTex_ST; // 流动纹理缩放与偏移
    float4 _DistortionIntensityToMultiMap; // 流动对各纹理的影响强度（x=主纹理,y=第二纹理,z=遮罩,w=溶解）
    int _DistortionAnimationSource; // 流动动画源（0=时间,1=自定义数据）
    int _DistortionAnimationCustomDataChannel01; // 流动动画通道1（方向）
    int _DistortionAnimationCustomDataChannel02; // 流动动画通道2（速度）
    // float _DistortionIntensity;                 // 流动效果强度（预留）

    // 菲涅尔效果（边缘光）参数
    float _EnableFresnel; // 是否启用菲涅尔效果（1=启用）
    float _EnableFresnelDebuger; // 是否启用菲涅尔调试视图（1=启用）
    half4 _FresnelColor; // 菲涅尔边缘颜色
    half _FresnelColorIntensity; // 菲涅尔颜色强度
    half _FresnelColorPower; // 菲涅尔颜色衰减幂次（值越大范围越窄）
    half _FresnelAlphaMode; // 菲涅尔Alpha模式（0=叠加,1=替换）
    half _FresnelAlphaIntensity; // 菲涅尔Alpha强度
    half _FresnelAlphaPower; // 菲涅尔Alpha衰减幂次
    half _FresnelColorSoftnessMin; // 菲涅尔颜色柔和度最小值
    half _FresnelColorSoftnessMax; // 菲涅尔颜色柔和度最大值
    half _FresnelAlphaSoftnessMin; // 菲涅尔Alpha柔和度最小值
    half _FresnelAlphaSoftnessMax; // 菲涅尔Alpha柔和度最大值
    int _FresnelEdgeMode; // 菲涅尔边缘计算模式（0=视角依赖,1=固定范围）
    float _FresnelIntensity; // 菲涅尔整体强度缩放
    float _FresnelPower; // 菲涅尔基础衰减幂次
    float _FresnelInvert; // 是否反转菲涅尔效果（1=反转）

    // 遮罩（Mask）控制参数
    float _MaskIntensity; // 遮罩强度（0=无遮罩,1=完全遮罩）
    int _InvertMask; // 是否反转遮罩（1=反转）
    int _MaskAlphaChannel; // 遮罩使用的Alpha通道（0=R,1=G等）
    int _MaskAnimationSource; // 遮罩动画源（0=时间,1=自定义数据）
    float4 _MaskTex_ST; // 遮罩纹理缩放与偏移
    half4 _MaskRotationParams; // 遮罩旋转参数（x=角度,y=中心偏移）// 注：(0.0,1.0,-1.0,0.0)表示90度旋转
    int _MaskAnimationCustomDataChannel01; // 遮罩动画通道1
    int _MaskAnimationCustomDataChannel02; // 遮罩动画通道2

    // 溶解效果（Dissolve）参数
    float4 _DissolveTex_ST; // 溶解纹理缩放与偏移
    float4 _DissolveRotationParams; // 溶解纹理旋转参数
    int _DissolveChannel; // 溶解采样通道（0=R,1=G等）
    float _DissolveSoftness; // 溶解边缘柔和度
    int _DissolveDirection; // 溶解方向（0=垂直,1=水平,2=径向）
    half4 _DissolveColor; // 溶解边缘发光颜色
    int _DissolveSource; // 溶解数据源（0=纹理,1=自定义数据）
    float _DissolveThreshold; // 溶解阈值（0=完全溶解,1=不溶解）
    int _DissolveCustomDataChannel; // 溶解数据通道
    float4 _VertexAnimationStrength; // 顶点动画强度（xyz=方向, w=整体缩放）
    int _DissolveBlendAlpha; // 是否混合溶解Alpha（1=混合）

    // 屏幕扭曲效果参数
    int _ScreenDistortionChannel; // 扭曲采样通道（0=R,1=G等）
    float _EnableScreenDistortion; // 是否启用屏幕扭曲（1=启用）
    float _ScreenDistortionIntensity; // 扭曲强度（值越大扭曲越明显）

    // 深度混合效果参数
    float _EnableDepthBlend; // 是否启用深度混合（1=启用）
    int _DepthBlendMode; // 深度混合模式（0=交叉区域,1=深度测试失败区域）
    float4 _DepthBlendColor; // 深度混合叠加颜色
    float _IntersectionSoftness; // 交叉边缘柔和度

    // 渐变纹理（Ramp）参数
    float _EnableRamp; // 是否启用Ramp纹理（1=启用）
    int _RampMapSource; // Ramp纹理来源（0=内置,1=自定义纹理）
    float _EnableRampDebuger; // 是否启用Ramp调试视图（1=启用）
    float4 _RampMapRotationParams; // Ramp纹理旋转参数
    float _RampIntensity; // Ramp效果强度

    // 临时启用开关（调试用）
    float _EnableSecond; // 是否启用第二纹理（1=启用）
    float _EnableMask; // 是否启用遮罩（1=启用）
    float _EnableMaskDebuger; // 是否启用遮罩调试（1=启用）
    float _EnableDissolve; // 是否启用溶解效果（1=启用）
    float _EnableDistortion; // 是否启用流动效果（1=启用）
    int _EnableDistortionDebuger; // 是否启用流动调试（1=启用）
    float4 _DistortionRotationParams; // 流动纹理旋转参数
    int _DistortionTexChannel; // 流动纹理采样通道
    int _VertexAnimationStrengthSource; // 顶点动画强度来源
    int _VertexAnimationStrengthCustomDataChannel01; // 顶点动画通道1
    int _VertexAnimationStrengthCustomDataChannel02; // 顶点动画通道2
    int _VertexAnimationStrengthCustomDataChannel03; // 顶点动画通道3
    int _EnableScreenDistortionNormal; // 是否使用法线贴图驱动扭曲（1=启用）
CBUFFER_END

// 主纹理及其采样器
TEXTURE2D(_MainTex); // 主纹理：用于基础颜色、主图案显示，配合_MainTex_ST等参数控制缩放/偏移/动画
SAMPLER(sampler_MainTex); // 主纹理采样器：控制_MainTex的采样方式（过滤模式、寻址模式等）

// 第二纹理及其采样器
TEXTURE2D(_SecondTex); // 第二纹理：用于叠加次级图案或颜色，配合_SecondTex_ST等参数使用
SAMPLER(sampler_SecondTex); // 第二纹理采样器：控制_SecondTex的采样方式

// 遮罩纹理及其采样器
TEXTURE2D(_MaskTex); // 遮罩纹理：用于控制区域显示/隐藏或效果强度，通过_MaskIntensity等参数调节
SAMPLER(sampler_MaskTex); // 遮罩纹理采样器：控制_MaskTex的采样方式

// 溶解纹理及其采样器
TEXTURE2D(_DissolveTex); // 溶解纹理：用于主溶解效果的图案定义，通过_DissolutionThreshold控制溶解程度
SAMPLER(sampler_DissolveTex); // 溶解纹理采样器：控制_DissolutionTex的采样方式

// 流动纹理及其采样器
TEXTURE2D(_DistortionTex); // 流动纹理：用于实现流动效果（如液体、烟雾流动），配合_DistortionTex_ST和动画参数使用
SAMPLER(sampler_DistortionTex); // 流动纹理采样器：控制_DistortionTex的采样方式

// 第二溶解纹理及其采样器
TEXTURE2D(_SecondDissolveTex); // 第二溶解纹理：用于次级溶解效果的图案定义，配合第二溶解参数使用
SAMPLER(sampler_SecondDissolveTex); // 第二溶解纹理采样器：控制_SecondDissolutionTex的采样方式

// 渐变纹理及其采样器
TEXTURE2D(_RampMap); // 渐变纹理（Ramp图）：用于颜色渐变或光照衰减控制，通过_RampIntensity调节强度
SAMPLER(sampler_RampMap); // 渐变纹理采样器：控制_RampMap的采样方式（通常使用线性过滤实现平滑过渡）

#endif
