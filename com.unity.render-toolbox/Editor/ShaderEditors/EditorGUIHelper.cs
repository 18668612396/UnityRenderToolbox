using System;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

public static class EditorGUIHelper
{
    /// 静态字典存储模块折叠状态
    private static Dictionary<string, bool> m_ModuleFoldoutStates = new Dictionary<string, bool>();

    // 获取模块当前折叠状态
    public static bool GetModuleFoldoutState(string moduleName)
    {
        return m_ModuleFoldoutStates.TryGetValue(moduleName, out bool state) ? state : false;
    }

    // 设置模块折叠状态
    public static void SetModuleFoldoutState(string moduleName, bool expanded)
    {
        m_ModuleFoldoutStates[moduleName] = expanded;
    }

    /// <summary>
    /// 绘制一个可折叠的模块，并在内部处理折叠状态
    /// </summary>
    /// <param name="moduleName">模块的名称</param>
    /// <param name="drawContent">用于绘制模块内容的回调方法</param>
    /// <param name="isFldout">是否启用折叠</param>
    /// <param name="height">模块标题按钮的高度，0表示不显示标题按钮</param>
    /// <param name="enableSetting">是否显示设置按钮</param>
    /// <param name="defaultExpanded">模块默认是否展开</param>
    public static void DrawModuleContent(string moduleName, Action drawContent, Action setting = null, bool isFldout = true, int height = 20, bool defaultExpanded = false, MaterialProperty debuger = null)
    {
        // 确保模块状态初始化
        if (!m_ModuleFoldoutStates.ContainsKey(moduleName))
        {
            m_ModuleFoldoutStates[moduleName] = defaultExpanded;
        }

        // 标题区域
        EditorGUILayout.BeginVertical();
        EditorGUILayout.BeginHorizontal();
        GUILayout.Space(-3); // 左侧偏移

        // 标题按钮区域
        EditorGUILayout.BeginHorizontal();
        bool shouldShowContent = m_ModuleFoldoutStates[moduleName];

        GUIStyle style = new GUIStyle(GUI.skin.button);
        // 禁用悬停效果 - 使悬停状态与正常状态相同
        style.hover.background = Texture2D.redTexture;
        style.hover.textColor = style.normal.textColor;
        // 设置点击状态
        // style.active.background = Texture2D.blackTexture;
        // style.active.textColor = Color.white;
        style.alignment = TextAnchor.MiddleLeft;

        if (height > 0)
        {
            if (debuger != null)
            {
                debuger.floatValue = GUILayout.Toggle(debuger.floatValue > 0, "调试", style, GUILayout.Height(height), GUILayout.Width(35)) ? 1 : 0;
            }

            GUILayout.Space(-3); // 左侧偏移
            if (GUILayout.Button(moduleName, style, GUILayout.Height(height)) && isFldout)
            {
                m_ModuleFoldoutStates[moduleName] = !m_ModuleFoldoutStates[moduleName];
                shouldShowContent = m_ModuleFoldoutStates[moduleName];
                GUI.changed = true; // 标记GUI发生变化，触发重绘
            }
        }
        else
        {
            // 不显示标题按钮时默认展开
            shouldShowContent = true;
        }

        if (setting != null)
        {
            GUILayout.Space(-3); // 左侧偏移
            if (GUILayout.Button("三", GUILayout.Width(40), GUILayout.Height(height > 0 ? height : 17)))
            {
                setting?.Invoke();
            }
        }

        EditorGUILayout.EndHorizontal();

        GUILayout.Space(-3); // 左侧偏移
        EditorGUILayout.EndHorizontal();
        GUILayout.Space(-3); // 左侧偏移
        EditorGUILayout.EndVertical();

        // 内容区域 - 直接根据状态决定是否显示
        if (shouldShowContent && drawContent != null)
        {
            // 添加一点内容区域的间距
            EditorGUILayout.Space(2);
            // 调用回调绘制内容区域
            drawContent.Invoke();
        }
    }


    public static int BeginPlatformGrouping(string[] platformNames)
    {
        GUIStyle style = "frameBox";
        int num1 = 0; // 默认选择第一个平台

        string selectedPlatformName = EditorPrefs.GetString("CustomPlatformGrouping_SelectedPlatform", platformNames.Length > 0 ? platformNames[0] : "");

        for (int index = 0; index < platformNames.Length; ++index)
        {
            if (platformNames[index] == selectedPlatformName)
            {
                num1 = index;
                break;
            }
        }

        if (num1 == -1 && platformNames.Length > 0)
        {
            num1 = 0;
            EditorPrefs.SetString("CustomPlatformGrouping_SelectedPlatform", platformNames[0]);
        }

        int index1 = num1;
        bool enabled = GUI.enabled;
        GUI.enabled = true;
        EditorGUI.BeginChangeCheck();
        Rect rect = EditorGUILayout.BeginVertical(style);
        int length = platformNames.Length;
        int tabCount = length;

        int tabIndex = 0;
        int index2 = 0;
        while (index2 < length)
        {
            GUIContent content = new GUIContent(platformNames[index2]);
            GUIStyle tabStyle = null;
            Rect tabRect = GetTabRect(rect, tabIndex, tabCount, out tabStyle);
            if (GUI.Toggle(tabRect, index1 == index2, content, tabStyle))
                index1 = index2;

            ++index2;
            ++tabIndex;
        }

        GUILayoutUtility.GetRect(10f, 22f);
        GUI.enabled = enabled;
        if (EditorGUI.EndChangeCheck())
        {
            EditorPrefs.SetString("CustomPlatformGrouping_SelectedPlatform", platformNames[index1]);
            foreach (UnityEngine.Object obj in Resources.FindObjectsOfTypeAll(typeof(EditorWindow)))
            {
                if (obj is EditorWindow editorWindow)
                {
                    editorWindow.Repaint();
                }
            }
        }

        return index1;
    }

    public static void EndPlatformGrouping()
    {
        EditorGUILayout.EndVertical();
    }

    public static bool BeginHeaderToggleGrouping(string platformNames)
    {
        GUIStyle style = "frameBox";

        GUI.enabled = true;
        Rect rect = EditorGUILayout.BeginVertical(style);

        GUIContent content = new GUIContent(platformNames);
        GUIStyle tabStyle = null;
        Rect tabRect = GetTabRect(rect,0,1,out tabStyle);
        if (GUI.Toggle(tabRect, false, content, tabStyle))
        {
        }
        EditorGUILayout.Space(22);
        return true;
    }

    private static GUIStyle s_TabOnlyOne;
    private static GUIStyle s_TabFirst;
    private static GUIStyle s_TabMiddle;
    private static GUIStyle s_TabLast;

    private static Rect GetTabRect(Rect rect, int tabIndex, int tabCount, out GUIStyle tabStyle)
    {
        if (EditorGUIHelper.s_TabOnlyOne == null)
        {
            EditorGUIHelper.s_TabOnlyOne = (GUIStyle)"Tab onlyOne";
            EditorGUIHelper.s_TabFirst = (GUIStyle)"Tab first";
            EditorGUIHelper.s_TabMiddle = (GUIStyle)"Tab middle";
            EditorGUIHelper.s_TabLast = (GUIStyle)"Tab last";
        }

        tabStyle = EditorGUIHelper.s_TabMiddle;
        if (tabCount == 1)
            tabStyle = EditorGUIHelper.s_TabOnlyOne;
        else if (tabIndex == 0)
            tabStyle = EditorGUIHelper.s_TabFirst;
        else if (tabIndex == tabCount - 1)
            tabStyle = EditorGUIHelper.s_TabLast;
        float num1 = rect.width / (float)tabCount;
        int num2 = Mathf.RoundToInt((float)tabIndex * num1);
        int num3 = Mathf.RoundToInt((float)(tabIndex + 1) * num1);
        return new Rect(rect.x + (float)num2, rect.y, (float)(num3 - num2), 22f);
    }

    public static void EndHeaderToggleGrouping()
    {
        EditorGUILayout.EndVertical();
    }
}