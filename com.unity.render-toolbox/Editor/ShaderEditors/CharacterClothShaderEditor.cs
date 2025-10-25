using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class CharacterClothShaderEditor : ModularShaderEditor
{
    protected override string BeforeModuleName => "";
    protected override string MainModuleName => "Main";
    protected override string AfterModuleName => "";

    protected override Dictionary<(string ModuleName, string PropertyName, string keyword), Action<MaterialEditor>> ModuleProperties => new Dictionary<(string ModuleName, string PropertyName, string keyword), Action<MaterialEditor>>
    {
        // 2. 在初始化元组时，传入对应的 ShaderKeyword 实例
        { ("第二层纹理", "_EnableSecond", "_KEYWORD_SECOND"), DrawSecondModule },
        { ("细节纹理数组", "_EnableDetailArray", "_ENABLE_DETAIL_ARRAY"), DrawDetailArray },
        { ("次表面散射", "_EnableSubSurfaceScattering", "_ENABLE_SSS"), DrawSubSurfaceScattering},
    };



    protected override void OnBeforeDefaultGUI(MaterialEditor materialEditor)
    {
        ModelInputs(materialEditor);
        //关闭pass
        if (FindProperty("_EnableSubSurfaceScattering").floatValue > 0.5)
        {
            material.SetShaderPassEnabled("SubSurfaceScatteringDiffuse", true);
        }
        else
        {
            material.SetShaderPassEnabled("SubSurfaceScatteringDiffuse", false);
        }
    }

    protected override void OnMainDefaultGUI(MaterialEditor materialEditor)
    {
        materialEditor.TexturePropertySingleLine(new GUIContent("主贴图"), FindProperty("_BaseMap"), FindProperty("_Color"), FindProperty("_ColorIntensity"));
        materialEditor.TexturePropertySingleLine(new GUIContent("遮罩贴图", "R:高光范围,G:静态阴影,B:高光强度,A:材质通道"), FindProperty("_MaskMap"));
        materialEditor.TexturePropertySingleLine(new GUIContent("法线贴图"), FindProperty("_NormalMap"));
    }

    private void DrawSecondModule(MaterialEditor materialEditor)
    {
        EditorGUI.indentLevel = 0;
        materialEditor.TexturePropertySingleLine(new GUIContent("刺绣主纹理"), FindProperty("_SecondBaseMap"));
        materialEditor.TexturePropertySingleLine(new GUIContent("刺绣遮罩"), FindProperty("_SecondMaskMap"));
        materialEditor.TexturePropertySingleLine(new GUIContent("刺绣法线"), FindProperty("_SecondNormalMap"));
    }
    private void DrawSubSurfaceScattering(MaterialEditor materialEditor)
    {
        EditorGUI.indentLevel = 0;
        materialEditor.TexturePropertySingleLine(new GUIContent("次表面散射贴图"),
            FindProperty("_ScatteringMap"));
        materialEditor.ShaderProperty(FindProperty("_ScatteringColor"), "散射颜色");
        materialEditor.ShaderProperty(FindProperty("_ScatteringIntensity"), "散射强度");
            
    }

    private int m_SelectedTab = 0;
    private readonly string[] m_TabNames = { "第一层", "第二层", "第三层", "第四层" };

    private void DrawDetailArray(MaterialEditor materialEditor)
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
        materialEditor.ShaderProperty(FindProperty("_MaterialType"), "材质类型");
        materialEditor.ShaderProperty(FindProperty("_Cull"), "剔除模式");
        EditorGUI.BeginChangeCheck();
        materialEditor.ShaderProperty(FindProperty("_RenderMode"), "渲染模式");
        FindProperty("_RenderQueueOffset").floatValue = EditorGUILayout.IntSlider("渲染队列偏移", (int)FindProperty("_RenderQueueOffset").floatValue, -15, 15);
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
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest + (int)FindProperty("_RenderQueueOffset").floatValue;
                FindProperty("_SrcBlend").floatValue = (float)src;
                FindProperty("_DstBlend").floatValue = (float)dst;
                FindProperty("_SrcBlendA").floatValue = (float)srcA;
                FindProperty("_DstBlendA").floatValue = (float)dstA;
            }
            else
            {
                RenderingBlendUtils.CalculateRenderBlendMode(RenderingBlendUtils.BlendMode.Replace,
                    out var src, out var dst, out var srcA, out var dstA);
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry + (int)FindProperty("_RenderQueueOffset").floatValue;
                FindProperty("_SrcBlend").floatValue = (float)src;
                FindProperty("_DstBlend").floatValue = (float)dst;
                FindProperty("_SrcBlendA").floatValue = (float)srcA;
                FindProperty("_DstBlendA").floatValue = (float)dstA;
            }
        }
        else
        {
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
                FindProperty($"_DetailArea{i}_DetailIndex").floatValue =
                    EditorGUILayout.IntSlider("Mask索引", (int)FindProperty($"_DetailArea{i}_DetailIndex").floatValue, 0, FindProperty("_DetailTextureArray").textureValue != null ? (FindProperty("_DetailTextureArray").textureValue as Texture2DArray).depth - 1 : 0);

                materialEditor.ShaderProperty(FindProperty($"_DetailArea{i}_DiffuseColor"), "颜色");
                materialEditor.ShaderProperty(FindProperty($"_DetailArea{i}_DiffuseIntensity"), "颜色强度");
                materialEditor.ShaderProperty(FindProperty($"_DetailArea{i}_Smoothness"), "光滑度");
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

            //绘制一个slider 范围是纹理数组的深度
            FindProperty($"_DetailArea{i}_NormalIndex").floatValue =
                EditorGUILayout.IntSlider("Normal索引", (int)FindProperty($"_DetailArea{i}_NormalIndex").floatValue, 0, FindProperty("_DetailTextureArray").textureValue != null ? (FindProperty("_DetailTextureArray").textureValue as Texture2DArray).depth - 1 : 0);
            materialEditor.ShaderProperty(FindProperty($"_DetailArea{i}_NormalIntensity"), new GUIContent("Normal强度"));
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
            EditorGUILayout.LabelField("缩放", GUILayout.Width(40));
            scale = EditorGUILayout.Vector2Field("", scale);
        }
        EditorGUILayout.EndHorizontal();
        rotation = EditorGUILayout.Slider("旋转", rotation, 0, 359.99f);
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
                GUILayout.Label(tempTex, GUILayout.Width(size), GUILayout.Height(size));
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