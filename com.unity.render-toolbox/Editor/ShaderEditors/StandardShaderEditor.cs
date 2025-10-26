using System;
using System.Collections;
using System.Collections.Generic;
using RenderToolbox.Editor;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class StandardShaderEditor : ModularShaderEditor
{
    protected override string BeforeModuleName => "";
    protected override string MainModuleName => "Main";
    protected override string AfterModuleName => "";

    protected override Dictionary<(string ModuleName, string PropertyName, string keyword), Action<MaterialEditor>> ModuleProperties => new Dictionary<(string ModuleName, string PropertyName, string keyword), Action<MaterialEditor>>
    {
        // 2. 在初始化元组时，传入对应的 ShaderKeyword 实例
        { ("第二层纹理", "_EnableSecond", "KEYWORD_SECOND"), DrawSecondModule },
        { ("细节纹理数组", "_EnableDetailArray", "ENABLE_DETAIL_ARRAY"), DrawDetailArrayModule },
        { ("自发光", "_EnableEmission", ""), DrawEmissionModule },
        { ("流动特效", "_EnableEffect", "ENABLE_EFFECT"), DrawEffectModule },
    };

    protected override void OnBeforeDefaultGUI(MaterialEditor materialEditor)
    {
        ModelInputs(materialEditor);
    }

    protected override void OnMainDefaultGUI(MaterialEditor materialEditor)
    {
        materialEditor.TexturePropertySingleLine(new GUIContent("主贴图", "RGB:主颜色,A:透明通道"), FindProperty("_BaseMap"), FindProperty("_Color"), FindProperty("_ColorIntensity"));
        materialEditor.TexturePropertySingleLine(new GUIContent("遮罩贴图", "R:光滑度,G:金属度,B:暂无,A:(自发光/特效)遮罩"), FindProperty("_MaskMap"));
        EditorGUI.indentLevel = 2;
        materialEditor.ShaderProperty(FindProperty("_Smoothness"), "光滑度");
        materialEditor.ShaderProperty(FindProperty("_Metallic"), "金属度");
        EditorGUI.indentLevel = 0;
        materialEditor.TexturePropertySingleLine(new GUIContent("法线贴图", "RG:法线XY,B:环境遮蔽"), FindProperty("_NormalMap"));
        materialEditor.TextureScaleOffsetProperty(FindProperty("_BaseMap"));
    }

    private void DrawEmissionModule(MaterialEditor materialEditor)
    {
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("自发光颜色", GUILayout.Width(100));
        {
            FindProperty("_EmissionColor").colorValue = EditorGUILayout.ColorField(FindProperty("_EmissionColor").colorValue);
            FindProperty("_EmissionIntensity").floatValue = EditorGUILayout.Slider(FindProperty("_EmissionIntensity").floatValue, 0f, 50f);
        }
        EditorGUILayout.EndHorizontal();
    }

    private void DrawSecondModule(MaterialEditor materialEditor)
    {
        EditorGUI.indentLevel = 0;
        materialEditor.TexturePropertySingleLine(new GUIContent("刺绣主纹理"), FindProperty("_SecondBaseMap"), FindProperty("_SecondColor"), FindProperty("_SecondColorIntensity"));
        materialEditor.TexturePropertySingleLine(new GUIContent("刺绣遮罩"), FindProperty("_SecondMaskMap"));
        materialEditor.TexturePropertySingleLine(new GUIContent("刺绣法线"), FindProperty("_SecondNormalMap"));
        materialEditor.TextureScaleOffsetProperty(FindProperty("_SecondBaseMap"));
    }

    private enum RGB_R_G_B_A
    {
        RGB = -1,
        R = 0,
        G = 1,
        B = 2,
        A = 3
    }

    private enum R_G_B_A
    {
        R = 0,
        G = 1,
        B = 2,
        A = 3
    }

    private void DrawEffectModule(MaterialEditor materialEditor)
    {
        //提示
        EditorGUILayout.HelpBox("注意：每个纹理的流动速度依靠其Offset值来控制", MessageType.Info);

        materialEditor.ShaderProperty(FindProperty("_EffectBlendMode"), "混合模式");
        materialEditor.ShaderProperty(FindProperty("_EffectMultiEmissionMask"), "叠加自发光通道为遮罩");
        materialEditor.TexturePropertySingleLine(new GUIContent("遮罩纹理"), FindProperty("_EffectMaskMap"),FindProperty("_EffectMaskMapChannel"));
        
        EditorGUILayout.BeginHorizontal();
        {
            // EditorGUILayout.BeginHorizontal();
            
            // EditorGUILayout.LabelField("遮罩通道", GUILayout.Width(80));
            FindProperty("_EffectMaskMapChannel").floatValue = (int)(R_G_B_A)EditorGUILayout.EnumPopup((R_G_B_A)(int)FindProperty("_EffectMaskMapChannel").floatValue);
            // EditorGUILayout.EndHorizontal();
        }
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.BeginVertical("helpbox");
        {
            materialEditor.TexturePropertySingleLine(new GUIContent("主纹理"), FindProperty("_EffectBaseMap"), FindProperty("_EffectColor"), FindProperty("_EffectColorIntensity"));
            materialEditor.TextureScaleOffsetProperty(FindProperty("_EffectBaseMap"));
            EditorGUILayout.BeginHorizontal();
            {
                // EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("颜色通道", GUILayout.Width(80));
                FindProperty("_EffectBaseMapColorChannel").floatValue = (int)(RGB_R_G_B_A)EditorGUILayout.EnumPopup((RGB_R_G_B_A)(int)FindProperty("_EffectBaseMapColorChannel").floatValue);
                // EditorGUILayout.EndHorizontal();
                // EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("透明通道", GUILayout.Width(80));
                FindProperty("_EffectBaseMapAlphaChannel").floatValue = (int)(R_G_B_A)EditorGUILayout.EnumPopup((R_G_B_A)(int)FindProperty("_EffectBaseMapAlphaChannel").floatValue);
                // EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.EndHorizontal();
        }
        EditorGUILayout.EndVertical();

        EditorGUILayout.BeginVertical("helpbox");
        {
            materialEditor.ShaderProperty(FindProperty("_EnableDistortionMap"), "使用扭曲纹理");
            if (FindProperty("_EnableDistortionMap").floatValue > 0.5f)
            {
                EditorGUILayout.HelpBox("必须使用法线贴图以达到扭曲效果。", MessageType.Info);
                materialEditor.TexturePropertySingleLine(new GUIContent("扭曲纹理"), FindProperty("_EffectDistortionMap"));
                materialEditor.TextureScaleOffsetProperty(FindProperty("_EffectDistortionMap"));
                materialEditor.ShaderProperty(FindProperty("_EffectDistortionBaseMapIntensity"), "主纹理扭曲强度");
            }
        }
        EditorGUILayout.EndVertical();
    }


    private int m_SelectedTab = 0;
    private readonly string[] m_TabNames = { "第一层", "第二层", "第三层", "第四层" };

    private void DrawDetailArrayModule(MaterialEditor materialEditor)
    {
        EditorGUI.indentLevel = 0;
        materialEditor.TexturePropertySingleLine(new GUIContent("纹理数组"), FindProperty("_DetailTextureArray"));
        // m_SelectedTab = GUILayout.Toolbar(m_SelectedTab, m_TabNames, GUILayout.Height(20));
        m_SelectedTab = GUILayout.Toolbar(m_SelectedTab, m_TabNames, GUILayout.Height(24));
        DrawDetailAreaTab(materialEditor, m_SelectedTab);
    }

    protected override void OnAfterDefaultGUI(MaterialEditor materialEditor)
    {
    }

    public void ModelInputs(MaterialEditor materialEditor)
    {
        materialEditor.ShaderProperty(FindProperty("_Cull"), "剔除模式");
        EditorGUI.BeginChangeCheck();
        materialEditor.ShaderProperty(FindProperty("_RenderMode"), "渲染模式");
        // if (EditorGUI.EndChangeCheck())
        // {
        if (FindProperty("_RenderMode").floatValue == 0)
        {
            materialEditor.ShaderProperty(FindProperty("_EnableAlphaTest"), "Alpha裁剪");
            if (FindProperty("_EnableAlphaTest").floatValue > 0.5)
            {
                materialEditor.ShaderProperty(FindProperty("_Cutoff"), "Alpha裁剪阈值");
                RenderingBlendUtils.CalculateRenderBlendMode(RenderingBlendUtils.BlendMode.Replace,
                    out var src, out var dst, out var srcA, out var dstA);
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                FindProperty("_SrcBlend").floatValue = (float)src;
                FindProperty("_DstBlend").floatValue = (float)dst;
                FindProperty("_SrcBlendA").floatValue = (float)srcA;
                FindProperty("_DstBlendA").floatValue = (float)dstA;
                FindProperty("_ZWrite").floatValue = 1.0f;
            }
            else
            {
                RenderingBlendUtils.CalculateRenderBlendMode(RenderingBlendUtils.BlendMode.Replace,
                    out var src, out var dst, out var srcA, out var dstA);
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
                FindProperty("_SrcBlend").floatValue = (float)src;
                FindProperty("_DstBlend").floatValue = (float)dst;
                FindProperty("_SrcBlendA").floatValue = (float)srcA;
                FindProperty("_DstBlendA").floatValue = (float)dstA;
                FindProperty("_ZWrite").floatValue = 1.0f;
            }
        }
        else
        {
            FindProperty("_RenderQueueOffset").floatValue = EditorGUILayout.IntSlider("渲染队列偏移", (int)FindProperty("_RenderQueueOffset").floatValue, -15, 15);
            materialEditor.ShaderProperty(FindProperty("_ZWrite"), "深度写入");
            RenderingBlendUtils.CalculateRenderBlendMode(RenderingBlendUtils.BlendMode.Alpha,
                out var src, out var dst, out var srcA, out var dstA);
            material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent + (int)FindProperty("_RenderQueueOffset").floatValue;
            FindProperty("_SrcBlend").floatValue = (float)src;
            FindProperty("_DstBlend").floatValue = (float)dst;
            FindProperty("_SrcBlendA").floatValue = (float)srcA;
            FindProperty("_DstBlendA").floatValue = (float)dstA;
        }
    }

    private void DrawDetailAreaTab(MaterialEditor materialEditor, int i)
    {
        EditorGUILayout.BeginVertical("helpbox");
        materialEditor.ShaderProperty(FindProperty($"_DetailArea{i}_Enable"), "启用");

        if (FindProperty($"_DetailArea{i}_Enable").floatValue < 0.5f)
            GUI.enabled = false;
        EditorGUILayout.BeginHorizontal("helpbox");
        {
            EditorGUILayout.BeginVertical("box");
            {
                ///////////////////////////////////////
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("基础纹理索引", GUILayout.Width(100));
                {
                    FindProperty($"_DetailArea{i}_DetailIndex").floatValue =
                        EditorGUILayout.IntSlider("", (int)FindProperty($"_DetailArea{i}_DetailIndex").floatValue, 0, FindProperty("_DetailTextureArray").textureValue != null ? (FindProperty("_DetailTextureArray").textureValue as Texture2DArray).depth - 1 : 0);
                }
                EditorGUILayout.EndHorizontal();
                ///////////////////////////////////////
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("颜色(底部)", GUILayout.Width(100));
                {
                    materialEditor.ShaderProperty(FindProperty($"_DetailArea{i}_BaseColor"), new GUIContent(""));
                }
                EditorGUILayout.EndHorizontal();
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("颜色(细节)", GUILayout.Width(100));
                {
                    materialEditor.ShaderProperty(FindProperty($"_DetailArea{i}_DetailColor"), new GUIContent(""));
                }
                EditorGUILayout.EndHorizontal();


                ///////////////////////////////////////
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("光滑度(底部/细节)", GUILayout.Width(100));
                {
                    FindProperty($"_DetailArea{i}_BaseSmoothness").floatValue = EditorGUILayout.Slider(FindProperty($"_DetailArea{i}_BaseSmoothness").floatValue, 0f, 1f);
                    FindProperty($"_DetailArea{i}_DetailSmoothness").floatValue = EditorGUILayout.Slider(FindProperty($"_DetailArea{i}_DetailSmoothness").floatValue, 0f, 1f);
                }
                EditorGUILayout.EndHorizontal();
                DrawDetailRotationScale(materialEditor, $"_DetailArea{i}_BaseMapMatrix");
            }
            EditorGUILayout.EndVertical();
            int index = (int)FindProperty($"_DetailArea{i}_DetailIndex").floatValue;
            ShowDetailTexturePreview(index, 120);
        }
        EditorGUILayout.EndVertical();


        EditorGUILayout.BeginHorizontal("helpbox");
        {
            EditorGUILayout.BeginVertical("box");
            GUIStyle headerStyle = new GUIStyle(EditorStyles.boldLabel);
            headerStyle.fontSize = 20;
            EditorGUILayout.LabelField("法线贴图设置", headerStyle, GUILayout.Height(40));
            ///////////////////////////////////////
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("法线纹理索引", GUILayout.Width(100));
            {
                FindProperty($"_DetailArea{i}_NormalIndex").floatValue =
                    EditorGUILayout.IntSlider("", (int)FindProperty($"_DetailArea{i}_NormalIndex").floatValue, 0, FindProperty("_DetailTextureArray").textureValue != null ? (FindProperty("_DetailTextureArray").textureValue as Texture2DArray).depth - 1 : 0);
            }
            EditorGUILayout.EndHorizontal();
            ///////////////////////////////////////
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("法线强度", GUILayout.Width(100));
            {
                materialEditor.ShaderProperty(FindProperty($"_DetailArea{i}_NormalIntensity"), new GUIContent(""));
            }
            EditorGUILayout.EndHorizontal();
            //绘制一个slider 范围是纹理数组的深度
            DrawDetailRotationScale(materialEditor, $"_DetailArea{i}_NormalMapMatrix");
            EditorGUILayout.EndVertical();

            //在这里显示该层的纹理
            int index = (int)FindProperty($"_DetailArea{i}_NormalIndex").floatValue;
            ShowDetailTexturePreview(index, 120);
        }

        EditorGUILayout.EndVertical();
        EditorGUILayout.EndVertical();
        GUI.enabled = true;
    }

    private void DrawDetailRotationScale(MaterialEditor materialEditor, string propertyName)
    {
        var (scale, rotation) = GetRotationScaleFromMatrix(FindProperty(propertyName).vectorValue);
        EditorGUILayout.BeginHorizontal();
        {
            EditorGUILayout.LabelField("缩放", GUILayout.Width(100));
            scale = EditorGUILayout.Vector2Field("", scale);
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("旋转", GUILayout.Width(100));
        {
            rotation = EditorGUILayout.Slider("", rotation, 0, 359.99f);
        }
        EditorGUILayout.EndHorizontal();

        //将修改后的旋转和缩放值合成回矩阵
        FindProperty(propertyName).vectorValue = GetMatrixFromRotationScale(rotation, scale);
    }

    /// <summary>
    /// 从一个代表2x2变换矩阵的Vector4中分解出非统一缩放和旋转角度。
    /// M = R * S
    /// </summary>
    /// <param name="matrixData">存储矩阵的Vector4 (m00, m01, m10, m11)</param>
    /// <returns>返回一个元组 (Tuple)，包含一个Vector2的缩放值和一个float的角度值。</returns>
    public static (Vector2 scale, float rotationDegrees) GetRotationScaleFromMatrix(Vector4 matrixData)
    {
        float m00 = matrixData.x;
        float m01 = matrixData.y;
        float m10 = matrixData.z;
        float m11 = matrixData.w;

        // 1. 计算缩放 (Scale)
        // 缩放值是矩阵列向量的长度（模）
        Vector2 scale = new Vector2(
            new Vector2(m00, m10).magnitude,
            new Vector2(m01, m11).magnitude
        );
        // 2. 计算旋转 (Rotation)
        // 使用atan2从第一列向量中稳定地提取角度（弧度）
        // m10/scale.x = sin(θ), m00/scale.x = cos(θ)
        // Atan2(sin, cos) -> θ
        // 添加一个微小的epsilon值防止在scale.x为0时除以0
        float angleRad = Mathf.Atan2(m10, m00);
        float angleDeg = angleRad * Mathf.Rad2Deg;

        // (可选) 将角度标准化到 0-360 范围，便于UI显示
        if (angleDeg < 0)
        {
            angleDeg += 360f;
        }

        return (scale, angleDeg);
    }

    /// <summary>
    /// 根据给定的旋转角度和非统一缩放值，构建一个代表2x2变换矩阵的Vector4。
    /// 矩阵顺序为 M = R * S (先缩放，后旋转)
    /// </summary>
    /// <param name="rotationDegrees">旋转角度 (0-360度)</param>
    /// <param name="scale">非统一缩放值 (Vector2)</param>
    /// <returns>返回一个代表矩阵的Vector4 (m00, m01, m10, m11)。</returns>
    public static Vector4 GetMatrixFromRotationScale(float rotationDegrees, Vector2 scale)
    {
        // 将角度从度转换为弧度
        float angleRad = rotationDegrees * Mathf.Deg2Rad;
        float s = Mathf.Sin(angleRad);
        float c = Mathf.Cos(angleRad);

        // 根据公式 M = R * S 计算矩阵的四个元素
        // R = | c  -s |   S = | sx  0 |
        //     | s   c |       | 0  sy |
        //
        // M = | c*sx  -s*sy |
        //     | s*sx   c*sy |
        float m00 = scale.x * c;
        float m01 = -scale.y * s;
        float m10 = scale.x * s;
        float m11 = scale.y * c;

        return new Vector4(m00, m01, m10, m11);
    }

    private void ShowDetailTexturePreview(int index, int size = 100)
    {
        EditorGUILayout.BeginVertical("box");
        //在这里显示该层的纹理
        if (FindProperty("_DetailTextureArray").textureValue != null)
        {
            Texture2DArray array = FindProperty("_DetailTextureArray").textureValue as Texture2DArray;
            if (array != null && index >= 0 && index < array.depth)
            {
                Texture2D tempTex = new Texture2D(array.width, array.height, array.format, false);
                Graphics.CopyTexture(array, index, 0, tempTex, 0, 0);
                // GUILayout.Label(tempTex, GUILayout.Width(size), GUILayout.Height(size));
                if (GUILayout.Button(tempTex, GUILayout.Width(size), GUILayout.Height(size)))
                {
                    //点击后在项目窗口选中该纹理
                    string path = AssetDatabase.GetAssetPath(array);
                    Texture2DArrayImporter importer = AssetImporter.GetAtPath(path) as Texture2DArrayImporter;
                    if (importer != null)
                    {
                        var texture = importer.GetTextureAtSlice(index);
                        // Selection.activeObject = texture;
                        EditorGUIUtility.PingObject(texture);
                    }
                }

                UnityEngine.Object.DestroyImmediate(tempTex);
            }
            else
            {
                GUILayout.Label("索引超出范围或数组为空", GUILayout.Width(size), GUILayout.Height(size));
            }
        }
        else
        {
            GUILayout.Label("请先设置纹理数组", GUILayout.Width(size), GUILayout.Height(size));
        }

        EditorGUILayout.EndVertical();
    }
}