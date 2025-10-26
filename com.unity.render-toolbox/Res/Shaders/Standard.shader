Shader "RenderToolbox/Standard"
{
    Properties
    {
        // ----- 主贴图 -----
        [Toggle(_ENABLE_ALPHA_TEST_ON)]_EnableAlphaTest("Enable Alpha Test", Float) = 0
        _Cutoff("Alpha Cutoff", Range(0,1)) = 0.5
        _BaseMap("Main Texture", 2D) = "white" {}
        _Color("Main Color", Color) = (1,1,1,1)
        _ColorIntensity("Color Intensity", Range(0,5)) = 1
        _MaskMap("Mask Map", 2D) = "blue" {}
        _Smoothness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalIntensity("Normal Intensity", Range(0,1)) = 1
        // ----- 第二套贴图 -----
        [Toggle]_EnableSecond("Enable Second Texture", Float) = 0
        _SecondBaseMap("Main Texture", 2D) = "white" {}
        _SecondColor("Main Color", Color) = (1,1,1,1)
        _SecondColorIntensity("Color Intensity", Range(0,5)) = 1
        _SecondNormalMap("Normal Map", 2D) = "bump" {}
        _SecondMaskMap("Mask Map", 2D) = "black" {}
        // 次表面散射
        [Toggle(_ENABLE_SSS)]_EnableSubSurfaceScattering("Enable SubSurface Scattering", Float) = 0
        _ScatteringMap("Scattering Map", 2D) = "white" {}
        [HDR]_ScatteringColor("Scattering Color", Color) = (1,1,1,1)
        _ScatteringIntensity("Scattering Intensity", Range(0,10)) = 1

        [Toggle(ENABLE_DETAIL_ARRAY)]_EnableDetailArray("Enable Detail Texture Array", Float) = 0
        _DetailTextureArray("Detail Texture Array", 2DArray) = "" {}
        // ----- 区域 0 -----
        [Toggle]_DetailArea0_Enable("区域0-启用", Float) = 0
        _DetailArea0_DetailIndex("区域0-Mask索引", Float) = 1
        [HDR]_DetailArea0_BaseColor("区域0-细节颜色", Color) = (1,1,1,1)
        [HDR]_DetailArea0_DetailColor("区域0-细节颜色", Color) = (1,1,1,1)
        _DetailArea0_BaseSmoothness("区域0-基础光滑度", Range(0,1)) = 1.0
        _DetailArea0_DetailSmoothness("区域0-细节光滑度", Range(0,1)) = 0.0
        _DetailArea0_BaseMapMatrix ("区域0-Transform", Vector) = (1,0,0,1)
        _DetailArea0_NormalIndex("区域0-Normal索引", Int) = 0
        _DetailArea0_NormalIntensity("区域0-Normal强度", Range(0,1)) = 1
        _DetailArea0_NormalMapMatrix ("区域0-Normal Transform", Vector) = (1,0,0,1)
        // ----- 区域 1 -----
        [Toggle]_DetailArea1_Enable("区域1-启用", Float) = 0
        _DetailArea1_DetailIndex("区域1-Mask索引", Float) = 2
        [HDR]_DetailArea1_BaseColor("区域0-细节颜色", Color) = (1,1,1,1)
        [HDR]_DetailArea1_DetailColor("区域1-颜色", Color) = (1,1,1,1)
        _DetailArea1_BaseSmoothness("区域0-基础光滑度", Range(0,1)) = 1.0
        _DetailArea1_DetailSmoothness("区域0-细节光滑度", Range(0,1)) = 0.0
        _DetailArea1_BaseMapMatrix ("区域1-Transform", Vector) = (1,0,0,1)
        _DetailArea1_NormalIndex("区域1-Normal索引", Int) = 0
        _DetailArea1_NormalIntensity("区域1-Normal强度", Range(0,1)) = 1
        _DetailArea1_NormalMapMatrix ("区域1-Normal Transform", Vector) = (1,0,0,1)
        // ----- 区域 2 -----
        [Toggle]_DetailArea2_Enable("区域2-启用", Float) = 0
        _DetailArea2_DetailIndex("区域2-Mask索引", Float) = 3
        [HDR]_DetailArea2_BaseColor("区域0-细节颜色", Color) = (1,1,1,1)
        [HDR]_DetailArea2_DetailColor("区域2-颜色", Color) = (1,1,1,1)
        _DetailArea2_DetailColorIntensity("区域2-颜色强度", Range(0,5)) = 1
        _DetailArea2_BaseSmoothness("区域0-基础光滑度", Range(0,1)) = 1.0
        _DetailArea2_DetailSmoothness("区域0-细节光滑度", Range(0,1)) = 0.0
        _DetailArea2_BaseMapMatrix ("区域2-Transform", Vector) = (1,0,0,1)
        _DetailArea2_NormalIndex("区域2-Normal索引", Int) = 0
        _DetailArea2_NormalIntensity("区域2-Normal强度", Range(0,1)) = 1
        _DetailArea2_NormalMapMatrix ("区域2-Normal Transform", Vector) = (1,0,0,1)
        // ----- 区域 3 -----
        [Toggle]_DetailArea3_Enable("区域3-启用", Float) = 0
        _DetailArea3_DetailIndex("区域3-Mask索引", Float) = 4
        [HDR]_DetailArea3_BaseColor("区域0-细节颜色", Color) = (1,1,1,1)
        [HDR]_DetailArea3_DetailColor("区域3-颜色", Color) = (1,1,1,1)
        _DetailArea3_DetailColorIntensity("区域3-颜色强度", Range(0,5)) = 1
        _DetailArea3_BaseSmoothness("区域0-基础光滑度", Range(0,1)) = 1.0
        _DetailArea3_DetailSmoothness("区域0-细节光滑度", Range(0,1)) = 0.0
        _DetailArea3_BaseMapMatrix ("区域3-Transform", Vector) = (1,0,0,1)
        _DetailArea3_NormalIndex("区域3-Normal索引", Int) = 0
        _DetailArea3_NormalIntensity("区域3-Normal强度", Range(0,1)) = 1
        _DetailArea3_NormalMapMatrix ("区域3-Normal Transform", Vector) = (1,0,0,1)

        [Enum(Opaque,0,Transparent,1)] _RenderMode ("渲染模式", float) = 0
        _RenderQueueOffset ("Render Queue Offset",range(-15,15)) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull剔除模式", float) = 2
        [Enum(Off,0,On,1)] _ZWrite("Z Write", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend混合源乘子", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend混合目标乘子", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendA ("SrcBlendA混合源乘子", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendA ("DstBlendA混合目标乘子", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _OutlineSrcBlend ("SrcBlend混合源乘子", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _OutlineDstBlend ("DstBlend混合目标乘子", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
            "ShaderModel" = "2.0"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Cull Off
            Cull [_Cull]
            Blend [_SrcBlend] [_DstBlend], [_SrcBlendA] [_DstBlendA]
            ZWrite [_ZWrite]
            ZTest LEqual
            Stencil
            {
                Ref 1
                Comp Always
                Pass Replace
                ZFail Keep
            }

            HLSLPROGRAM
            #pragma vertex LitPassVertex
            #pragma fragment LisPassFragment
            // -------------------------------------
            #pragma shader_feature_local _ENABLE_SSS
            #pragma shader_feature_local _ENABLE_ALPHA_TEST_ON
            // -------------------------------------
            #include "Standard_Inputs.hlsl"
            #include "Standard_Passes.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "SubSurfaceScatteringDiffuse"
            Tags
            {
                "LightMode" = "SubSurfaceScatteringDiffuse"
            }
            Cull Off
            Cull [_Cull]
            Blend [_SrcBlend] [_DstBlend], [_SrcBlendA] [_DstBlendA]
            ZWrite [_ZWrite]
            ZTest LEqual
            Stencil
            {
                Ref 1
                Comp Always
                Pass Replace
                ZFail Keep
            }

            HLSLPROGRAM
            #pragma vertex LitPassVertex
            #pragma fragment SubSurfaceScatteringPassFragment
            #pragma shader_feature_local _ENABLE_ALPHA_TEST_ON
            #include "Standard_Inputs.hlsl"
            #include "Standard_Passes.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ENABLE_ALPHA_TEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local _ENABLE_ALPHA_TEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }

    }
    CustomEditor "StandardShaderEditor"
}