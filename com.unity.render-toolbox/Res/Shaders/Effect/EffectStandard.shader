Shader "XEffect/EffectStandard"
{
    Properties
    {
        //=========================================================================
        // 通用参数 (Common)
        //=========================================================================
        [Toggle]_EnableAlphaTest              ("Enable Alpha Test", Float) = 0                      // 启用透明度裁剪（开启后根据裁剪阈值隐藏部分像素）
        _Cutoff                       ("Cutoff", Range(0, 1)) = 0.5                                   // 透明度裁剪阈值（高于该值显示，低于隐藏）
        [Toggle]_EnableScreenParticle                ("Enable Screen Particle", Float) = 0                  // 启用屏幕空间粒子（开启后粒子基于屏幕空间渲染）
        //=========================================================================
        // 主纹理参数 (Main)
        //=========================================================================
        _MainTex                      ("MainTex", 2D) = "white" {}         // 主纹理（基础纹理）
        _MainTexColor                 ("Color", Color) = (1,1,1,1)      // 主纹理颜色（乘法混合）
        _MainTexIntensity             ("Intensity", Range(0, 200)) = 1      // 主纹理强度（控制纹理显示浓度）
        [Enum(X,0,Y,1,Z,2,W,3)]       _MainTexColorRampChannel("MainTex Color Ramp Channel", Float) = 0 // 主纹理颜色渐变通道：0=X，1=Y，2=Z，3=W
        _MainRotationParams           ("_MainRotationParams", Vector) = (1,0,0,0)                       // 主纹理旋转参数（控制纹理旋转角度/方向）
        [Enum(Disable,0,CustomData01,1,CustomData02,2,Time,3)] _MainAnimationSource("Mask Animation Source", Int) = 0  // 遮罩动画来源：0=禁用，1=CustomData01，2=CustomData02，3=时间
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _MainAnimationCustomDataChannel01("Mask CustomData Channel01", Int) = 0  // 遮罩U方向通道：0=禁用，1=X，2=Y，3=Z，4=W
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _MainAnimationCustomDataChannel02("Mask CustomData Channel02", Int) = 0  // 遮罩V方向通道：0=禁用，1=X，2=Y，3=Z，4=W
        _MainAnimationChannelAndSpeed ("Main Animation Channel And Speed", Vector) = (0, 0, 0, 0)  // 主动画通道与速度：X=X方向通道，Y=Y方向通道，Z=X方向速度，W=Y方向速度
        
        //=========================================================================
        // 次纹理参数 (Secondary)
        //=========================================================================
        [Toggle(_ENABLE_SECOND_ON)]   _EnableSecond("Second On", Float) = 0                         // 启用次纹理（开启后激活次纹理相关效果）
        [Toggle]                      _EnableMultiMainAlpha("Enable Multi Main Alpha", Float) = 0   // 启用主纹理透明度乘法：次纹理透明度 = 主纹理透明度 × 次纹理原透明度
        _SecondTex                    ("SecondTex", 2D) = "white" {}                                // 次纹理（辅助纹理，叠加在主纹理之上）
        [HDR]                         _SecondColor01("SecondColor01", Color) = (1,1,1,1)         // 次纹理颜色1（乘法混合，HDR格式）
        [HDR]                         _SecondColor02("SecondColor02", Color) = (1,1,1,1)         // 次纹理颜色2（乘法混合，HDR格式）
        [Toggle]                      _EnableSecondGradient("Enable Second Gradient", Float) = 0    // 启用次纹理渐变（控制次纹理颜色渐变效果）
        [Enum(X,0,Y,1,Z,2,W,3)]       _SecondGradientChannel("Second Gradient Channel", Float) = 0  // 次纹理渐变通道：0=X，1=Y，2=Z，3=W
        [Toggle]                      _ApplySecondAlpha("Apply Second Alpha", Float) = 0            // 应用次纹理透明度（开启后次纹理透明度生效）
        _SecondRotationParams         ("_SecondRotationParams", Vector) = (1,0,0,0)                 // 次纹理旋转参数（控制次纹理旋转角度/方向）
        [Enum(Disable,0,CustomData01,1,CustomData02,2,Time,3)] _SecondAnimationSource("Mask Animation Source", Int) = 0  // 次纹理遮罩动画来源：0=禁用，1=CustomData01，2=CustomData02，3=时间
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _SecondAnimationCustomDataChannel01("Mask CustomData Channel01", Int) = 0      // 次纹理遮罩U方向通道：0=禁用，1=X，2=Y，3=Z，4=W
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _SecondAnimationCustomDataChannel02("Mask CustomData Channel02", Int) = 0      // 次纹理遮罩V方向通道：0=禁用，1=X，2=Y，3=Z，4=W

        [Toggle]                      _EnableSecondDissolution("Second Dissolution", int) = 0       // 启用次纹理溶解效果
        _SecondDissolutionTex         ("Second DissolutionTex", 2D) = "white" {}                    // 次纹理溶解纹理（控制溶解形状）
        [HDR]                         _SecondDissolutionColor("Second Dissolution Color", Color) = (1,1,1,1)  // 次纹理溶解颜色（HDR格式，溶解边缘颜色）
        [Enum(Properties,0,VertexColorAlpha,1,CustomData01,2,CustomData02,3)] _SecondDissolutionSource("_DissolutionSource", Int) = 0  // 次纹理溶解来源：0=属性，1=顶点颜色Alpha，2=CustomData01，3=CustomData02
        [Enum(X,0,Y,1,Z,2,W,3)]       _SecondDissolutionCustomDataChannel("_DissolutionCustomDataChannel", Int) = 0  // 次纹理溶解CustomData通道：0=X，1=Y，2=Z，3=W
        _SecondDissolutionThreshold   ("Second Dissolution Threshold", Range(1, 0)) = 0.5           // 次纹理溶解阈值：值越小溶解范围越大
        _SecondDissolutionSoftness    ("Second Dissolution Softness", Range(0, 1)) = 0.1            // 次纹理溶解边缘柔化程度：值越大边缘越模糊

        //=========================================================================
        // 渐变纹理参数 (Ramp)
        //=========================================================================
        [Toggle(_ENABLE_RAMP_ON)]     _EnableRamp("Ramp On", Float) = 0              // 启用渐变纹理（开启后激活渐变相关效果）
        _EnableRampDebuger            ("Enable Ramp Debuger", Float) = 0             // 启用渐变纹理调试（开启后显示渐变调试信息）
        [Enum(UV,0,R,1,G,2,B,3,A,4)]  _RampMapSource("Ramp Channel", Float) = 0      // 渐变纹理来源通道：0=UV，1=R，2=G，3=B，4=A
        _RampMap                      ("RampMap", 2D) = "white" {}                   // 渐变纹理（控制颜色渐变过渡）
        _RampMapRotationParams        ("_SecondRotationParams", Vector) = (1,0,0,0)  // 渐变纹理旋转参数（控制渐变纹理旋转角度/方向）
        _RampIntensity                ("Ramp Intensity", Range(0, 100)) = 1          // 渐变纹理强度（控制渐变效果明显程度）

        //=========================================================================
        // 扭曲效果参数 (Distortion)
        //=========================================================================
        [Toggle(_ENABLE_DISTORTION_ON)]     _EnableDistortion("Distortion On", Float) = 0              // 启用流动效果（开启后激活纹理流动动画）
        _EnableDistortionDebuger            ("Enable Distortion Debuger", Float) = 0                   // 启用流动效果调试（开启后显示流动调试信息）
        _DistortionTex                      ("DistortionTex", 2D) = "white" {}                         // 流动纹理（基础流动效果纹理）
        _DistortionIntensityToMultiMap      ("Distortion Intensity To MultiMap", Vector) = (0,0,0,0)   // 流动强度到多纹理映射：X/Y/Z/W对应不同纹理的强度
        [Enum(X,0,Y,1,Z,2,W,3)]       _DistortionTexChannel("Distortion Channel", Float) = 3           // 流动纹理通道选择：0=X，1=Y，2=Z，3=W（基于材质RGBA输出）
        _DistortionRotationParams           ("_DistortionRotationParams", Vector) = (1,0,0,0)          // 流动纹理旋转参数（控制流动纹理旋转角度/方向）
        [Enum(Disable,0,CustomData01,1,CustomData02,2,Time,3)] _DistortionAnimationSource("Distortion Animation Source", Int) = 0  // 流动动画来源：0=禁用，1=CustomData01，2=CustomData02，3=时间
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _DistortionAnimationCustomDataChannel01("Distortion CustomData Channel01", Int) = 0  // 流动U方向通道：0=禁用，1=X，2=Y，3=Z，4=W
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _DistortionAnimationCustomDataChannel02("Distortion CustomData Channel02", Int) = 0  // 流动V方向通道：0=禁用，1=X，2=Y，3=Z，4=W
        [Enum(Properties,0,CustomData01,1,CustomData02,2)] _VertexAnimationStrengthSource("Distortion Animation Source", Int) = 0  // 顶点动画强度来源：0=属性，1=CustomData01，2=CustomData02
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _VertexAnimationStrengthCustomDataChannel01("Distortion CustomData Channel01", Int) = 0  // 顶点动画X方向通道：0=禁用，1=X，2=Y，3=Z，4=W
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _VertexAnimationStrengthCustomDataChannel02("Distortion CustomData Channel02", Int) = 0  // 顶点动画Y方向通道：0=禁用，1=X，2=Y，3=Z，4=W
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _VertexAnimationStrengthCustomDataChannel03("Distortion CustomData Channel02", Int) = 0  // 顶点动画Z方向通道：0=禁用，1=X，2=Y，3=Z，4=W
        _VertexAnimationStrength      ("Enable Vertex Animation Strength", Vector) = (0, 0, 0, 0)    // 顶点动画强度：XYZ=自身空间偏移，W=法线朝向偏移

        //=========================================================================
        // 遮罩参数 (Mask)
        //=========================================================================
        [Toggle(_ENABLE_MASK_ON)]     _EnableMask("Mask On", Float) = 0                      // 启用遮罩（开启后激活遮罩裁剪效果）
        [Toggle]                      _EnableMaskDebuger("Enable Mask Debuger", Float) = 0   // 启用遮罩调试（开启后显示遮罩调试信息）
        _MaskTex                      ("MaskTex", 2D) = "white" {}                           // 遮罩纹理（控制显示/隐藏区域）
        _MaskIntensity                ("Mask Intensity", Range(0, 1)) = 1                    // 遮罩强度：值越小遮罩效果越弱
        [Toggle]                      _InvertMask("Invert Mask", Float) = 0                  // 反转遮罩：开启后遮罩区域与原区域相反
        _MaskRotationParams           ("Mask Rotation Params", Vector) = (1, 0, 0, 0)        // 遮罩旋转参数（控制遮罩旋转角度/方向）
        [Enum(R,0,G,1,B,2,A,3)]       _MaskAlphaChannel("Mask Alpha Channel", Float) = 0     // 遮罩Alpha通道选择：0=R，1=G，2=B，3=A
        [Enum(Disable,0,CustomData01,1,CustomData02,2,Time,3)] _MaskAnimationSource("Mask Animation Source", Int) = 0 // 遮罩动画来源：0=禁用，1=CustomData01，2=CustomData02，3=时间
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _MaskAnimationCustomDataChannel01("Mask CustomData Channel01", Int) = 0     // 遮罩U方向通道：0=禁用，1=X，2=Y，3=Z，4=W
        [Enum(Disable,0,X,1,Y,2,Z,3,W,4)] _MaskAnimationCustomDataChannel02("Mask CustomData Channel02", Int) = 0     // 遮罩V方向通道：0=禁用，1=X，2=Y，3=Z，4=W

        //=========================================================================
        // 溶解效果参数 (Dissolve)
        //=========================================================================
        [Toggle(_ENABLE_DISSOLVE_ON)] _EnableDissolve("Dissolve On", Float) = 0             // 启用溶解效果（开启后激活全局溶解）
        _DissolveTex               ("DissolveTex", 2D) = "white" {}                            // 溶解纹理（控制全局溶解形状）
        [Enum(R,0,G,1,B,2,A,3)]       _DissolveChannel("_DissolveChannel", int) = 0            // 溶解通道选择：0=R，1=G，2=B，3=A
        [HDR]                         _DissolveColor("Dissolve Color", Color) = (1,1,1,1)   // 溶解颜色（HDR格式，溶解边缘颜色）
        [Enum(Disable,0,UV_X,1,UV_Y,2)] _DissolveDirection("Dissolve Direction", int) = 0      // 溶解方向：0=禁用，1=UV_X方向，2=UV_Y方向
        [Enum(Properties,0,VertexColorAlpha,1,CustomData01,2,CustomData02,3)] _DissolveSource("_DissolveSource", Int) = 0  // 溶解来源：0=属性，1=顶点颜色Alpha，2=CustomData01，3=CustomData02
        _DissolveThreshold         ("_DissolveThreshold", Range(1,-1)) = 1                     // 溶解阈值：值越小溶解范围越大
        [Toggle]                      _DissolveBlendAlpha("Dissolve Blend Alpha", Float) = 1   // 溶解混合Alpha：开启后溶解与透明度叠加
        [Enum(X,0,Y,1,Z,2,W,3)]       _DissolveCustomDataChannel("_DissolveCustomDataChannel", Int) = 0  // 溶解CustomData通道：0=X，1=Y，2=Z，3=W
        _DissolveSoftness          ("Dissolve Softness", Range(0,1)) = 0.1                     // 溶解边缘柔化程度：值越大边缘越模糊
        _DissolveRotationParams    ("Dissolve Rotation Params", Vector) = (1, 0, 0, 0)         // 溶解纹理旋转参数（控制溶解纹理旋转角度/方向）

        //=========================================================================
        // 深度混合参数 (Depth)
        //=========================================================================
        [Toggle(_ENABLE_DEPTHBLEND_ON)] _EnableDepthBlend("Dissolution On", Float) = 0             // 启用深度混合（开启后与场景深度交互）
        [Enum(SoftParticle,0,HardParticle,1)] _DepthBlendMode("Depth Blend Mode", Float) = 0       // 深度混合模式：0=软粒子（边缘柔化），1=硬粒子（边缘锐利）
        [HDR]                         _DepthBlendColor("Depth Blend Color", Color) = (1,1,1,1)  // 深度混合颜色（HDR格式，与深度交互的颜色）
        _IntersectionSoftness         ("Intersection Softness", Range(0, 1)) = 0.1                 // 深度交叉柔化：值越大与场景交叉边缘越模糊

        //=========================================================================
        // 菲涅尔效果参数 (Fresnel)
        //=========================================================================
        [Toggle(_ENABLE_FRESNEL_ON)]  _EnableFresnel("Enable Fresnel", Float) = 0                 // 启用菲涅尔效果（开启后边缘高亮）
        [Toggle]                      _EnableFresnelDebuger("Enable Fresnel Debuger", Float) = 0  // 启用菲涅尔调试（开启后显示菲涅尔调试信息）
        _FresnelPower                 ("Fresnel Power", Range(0, 10)) = 1                         // 菲涅尔强度：值越大边缘高亮越集中
        [HDR]                         _FresnelColor("Fresnel Color", Color) = (1,1,1,1)        // 菲涅尔颜色（HDR格式，边缘高亮颜色）
        _FresnelColorIntensity        ("Fresnel Color Intensity", Range(0, 1)) = 1                // 菲涅尔颜色强度：值越小颜色越淡
        _FresnelColorPower            ("Fresnel Color Power", Range(0, 10)) = 1                   // 菲涅尔颜色衰减：值越大颜色衰减越快
        _FresnelColorSoftnessMin      ("Fresnel Color Softness Min", Range(0, 1)) = 0             // 菲涅尔颜色柔化最小值：控制高亮区域起始
        _FresnelColorSoftnessMax      ("Fresnel Color Softness Max", Range(0, 1)) = 1             // 菲涅尔颜色柔化最大值：控制高亮区域结束
        [Enum(Decrease,0,Increase,1)] _FresnelAlphaMode("Fresnel Alpha Mode", Float) = 0          // 菲涅尔Alpha模式：0=衰减（边缘透明），1=增强（边缘不透明）
        [Toggle]                      _EnableFresnelAlpha("Enable Fresnel Alpha", float) = 1      // 启用菲涅尔Alpha：开启后菲涅尔影响透明度
        _FresnelAlphaIntensity        ("Fresnel Alpha Intensity", Range(0, 1)) = 1                // 菲涅尔Alpha强度：值越小透明度影响越弱
        _FresnelAlphaPower            ("Fresnel Alpha Power", Range(0, 10)) = 1                   // 菲涅尔Alpha衰减：值越大透明度衰减越快
        _FresnelAlphaSoftnessMin      ("Fresnel Alpha Softness Min", Range(0, 1)) = 0             // 菲涅尔Alpha柔化最小值：控制透明度起始
        _FresnelAlphaSoftnessMax      ("Fresnel Alpha Softness Max", Range(0, 1)) = 1             // 菲涅尔Alpha柔化最大值：控制透明度结束

        //=========================================================================
        // 屏幕扭曲参数 (Screen Distortion)
        //=========================================================================
        [Toggle(_ENABLE_SCREENDISTORTION_ON)] _EnableScreenDistortion("Enable Screen Distortion", Float) = 0       // 启用屏幕扭曲（开启后扭曲背景）
        [Toggle]                      _EnableScreenDistortionNormal("Enable Screen Distortion Normal", Float) = 0  // 启用法线屏幕扭曲：基于法线方向扭曲
        _ScreenDistortionChannel      ("Screen Distortion Channel", Float) = 3                                     // 屏幕扭曲通道：0=X，1=Y，2=Z，3=W（基于材质RGBA输出）
        _ScreenDistortionIntensity    ("Screen Distortion Intensity", Range(0, 1)) = 0.5                           // 屏幕扭曲强度：值越大扭曲越明显

        //=========================================================================
        // 渲染状态参数 (Render State)
        //=========================================================================
        [Enum()]                      _BlendMode("BlendMode", Float) = 0               // 混合模式（控制纹理/颜色混合规则）
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4.0     // 深度测试模式（控制是否显示在其他物体前面）
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("_SrcBlend", Float) = 1.0    // 源混合因子（混合时的源颜色权重）
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("_DstBlend", Float) = 0.0    // 目标混合因子（混合时的目标颜色权重）
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendA("_SrcBlendA", Float) = 1.0  // 源Alpha混合因子（Alpha通道的源权重）
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendA("_DstBlendA", Float) = 0.0  // 目标Alpha混合因子（Alpha通道的目标权重）
        [Toggle]                      _ZWrite("_ZWrite", Float) = 0.0                  // 深度写入：开启后写入深度缓冲区（影响其他物体显示）
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2       // 背面剔除模式：控制是否显示模型背面
        _RenderQueueOffset            ("Queue offset", Range(-20,20)) = 0.0            // 渲染队列偏移：调整材质的渲染顺序

        //=========================================================================
        // 模板测试参数 (Stencil) - 暂时禁用
        //=========================================================================
        [Header(Stencil)]
        _StencilComp                  ("Stencil Comparison", Float) = 8     // 模板测试比较规则（是否通过模板测试）
        _Stencil                      ("Stencil ID", Float) = 0             // 模板ID（与缓冲区中的模板值对比）
        _StencilOp                    ("Stencil Operation", Float) = 0      // 模板操作（通过测试后对缓冲区的操作）
        _StencilWriteMask             ("Stencil Write Mask", Float) = 255   // 模板写入掩码（控制哪些位可写入）
        _StencilReadMask              ("Stencil Read Mask", Float) = 255    // 模板读取掩码（控制哪些位可读取）
    }
    //DummyShaderTextExporter
    SubShader
    {
        LOD 200
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForward"
        }
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }
        Pass
        {
            Name "EffectStandard"
            Blend [_SrcBlend] [_DstBlend], [_SrcBlendA] [_DstBlendA]
            BlendOp Add
            ZTest [_ZTest]
            ZWrite [_ZWrite]
            Cull [_CullMode]

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "EffectStandard_Function.hlsl"
            #include "EffectStandard_Input.hlsl"
            #include "EffectStandard_Passes.hlsl"
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma shader_feature_local_fragment _ENABLE_MASK_ON
            #pragma shader_feature_local_fragment _ENABLE_SECOND_ON
            #pragma shader_feature_local_fragment _ENABLE_RAMP_ON
            #pragma shader_feature_local_fragment _ENABLE_DISTORTION_ON
            #pragma shader_feature_local_fragment _ENABLE_DISSOLVE_ON
            #pragma shader_feature_local_fragment _ENABLE_DEPTHBLEND_ON
            #pragma shader_feature_local_fragment _ENABLE_FRESNEL_ON
            ENDHLSL
        }
    }
    CustomEditor "EffectStandardShaderEditor"
}