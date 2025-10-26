Shader "RenderToolbox/Eyeball"
{
    Properties
    {
        //瞳孔
        _PupilBaseMap("瞳孔纹理", 2D) = "black" {}
        _PupilNormalMap("瞳孔法线", 2D) = "bump" {}
        _PupilSize("瞳孔大小", Range(0,1)) = 0.5
        _PupilColor("瞳孔颜色", Color) = (0,0,0,1)
        _PupilFeather("瞳孔半径", Range(0,0.1)) = 0.5
        _ScleraSmoothness("瞳孔平滑度", Range(0,1)) = 0.5
        _PupilInsideSmoothness("瞳孔内侧平滑度", Range(0,1)) = 0.5
        //眼白 
        _ScleraBaseMap("眼白纹理", 2D) = "white" {}
        _ScleraColor("眼白颜色", Color) = (1,1,1,1)
        //眼角膜
        [Header(Cornea)]
        _CorneaCubemap("角膜立方体贴图", CUBE) = "" {}
        _CorneaSmoothness("角膜平滑度", Range(0,1)) = 0.9
        //瞳孔
        _PupilHeight("瞳孔高度", Range(0,1)) = 0.5//这里由于使用基于物理的折射，所以需要使用一个高度值来控制瞳孔折射的程度
        _OffsetW("折射偏移", Vector) = (0,0,1,1) //这个应该是折射的方向
        _RefractStrength("折射强度", float) = 0.5
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
            HLSLPROGRAM
            #pragma vertex LitPassVertex
            #pragma fragment LisPassFragment
            // -------------------------------------
            #pragma shader_feature_local _ENABLE_SSS
            #pragma shader_feature_local _ENABLE_ALPHA_TEST_ON
            // -------------------------------------
            #include "Eyeball_Inputs.hlsl"
            #include "Eyeball_Passes.hlsl"
            ENDHLSL
        }
    }
}