using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor.Rendering;
using UnityEngine.Rendering;


public abstract class ModularShaderEditor : ShaderGUI
    {
        private bool initialized = false;

        private MaterialEditor m_MaterialEditor;
        private MaterialProperty[] m_Properties;
        protected Material material;

        private bool[] showModule = new bool[0];


        protected abstract string BeforeModuleName { get; }
        protected abstract string MainModuleName { get; }
        protected abstract string AfterModuleName { get; }

        /// <summary>
        /// 自定义模块属性 ModuleProperties
        /// </summary>
        protected abstract Dictionary<(string ModuleName, string PropertyName, string keyword), Action<MaterialEditor>> ModuleProperties { get; }

        /// <summary>
        /// 最先绘制的GUI，OnBeforeDefaultGUI
        /// </summary>
        /// <param name="materialEditor"></param>
        protected abstract void OnBeforeDefaultGUI(MaterialEditor materialEditor);

        private void OnBeforeGUI()
        {
            // BeginDrawModule("BeforeDefault", 0, true, false);
            // {
            //     OnBeforeDefaultGUI(m_MaterialEditor);
            // }
            // EndDrawModule();
        }


        /// <summary>
        /// 主要属性模块 OnMainDefaultGUI
        /// </summary>
        /// <param name="materialEditor"></param>
        protected abstract void OnMainDefaultGUI(MaterialEditor materialEditor);

        /// <summary>
        /// 最后绘制的GUI，OnAfterDefaultGUI
        /// </summary>
        /// <param name="materialEditor"></param>
        protected abstract void OnAfterDefaultGUI(MaterialEditor materialEditor);

        /// <summary>
        /// 用于存储每个模块的折叠状态，由于是ShaderGUI，所以无法存储这个值，每次打开的时候默认为true
        /// </summary>
        private Dictionary<string, bool> m_ModuleStates = new Dictionary<string, bool>();

        /// <summary>
        /// 主绘制入口
        /// </summary>
        /// <param name="materialEditor"></param>
        /// <param name="properties"></param>
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            m_Properties = properties;
            m_MaterialEditor = materialEditor;
            material = materialEditor.target as Material;
            //做一些初始化工作
            if (!initialized && material != null)
            {
                initialized = true;
            }
            InitializeModuleStates();
            // 开始水平布局
            EditorGUILayout.BeginHorizontal();
            GUILayout.Space(-15);
            // 主垂直区域
            GUIStyle style = new GUIStyle(EditorStyles.helpBox);
            // 禁用悬停效果 - 使悬停状态与正常状态相同
            // style.normal.background = Texture2D.blackTexture;
            EditorGUILayout.BeginVertical(style);
            
            EditorGUIHelper.DrawModuleContent(BeforeModuleName, () => OnBeforeDefaultGUI(materialEditor), null, false, 0, true);
            EditorGUIHelper.DrawModuleContent(MainModuleName, () => OnMainDefaultGUI(materialEditor), null, isFldout: false, height: 30, true);

            // 创建活动模块的临时列表以避免集合修改异常
            var activeModules = m_ModuleStates
                .Where(m => m.Value)
                .Select(m => m.Key)
                .ToList();
            for (int i = 0; i < activeModules.Count; i++)
            {
                var moduleName = activeModules[i];
                // 在这里绘制模块内容
                var moduleEntry = ModuleProperties.FirstOrDefault(x => x.Key.ModuleName == moduleName);
                if (m_ModuleStates.ContainsKey(moduleName) && m_ModuleStates[moduleName])
                {
                    // 使用无返回值版本的DrawModule
                    EditorGUIHelper.DrawModuleContent(moduleName,
                        () =>
                        {
                            moduleEntry.Value?.Invoke(m_MaterialEditor);
                        },
                        () =>
                        {
                            var menu = new GenericMenu();
                            var activeModules = m_ModuleStates
                                .Where(m => m.Value)
                                .Select(m => m.Key)
                                .ToList();
                            int currentIndex = activeModules.IndexOf(moduleName);

                            // 添加向上移动选项
                            if (currentIndex > 0)
                            {
                                menu.AddItem(new GUIContent("向上移动"), false, () => MoveModule(moduleName, true));
                            }
                            else
                            {
                                menu.AddDisabledItem(new GUIContent("向上移动"));
                            }

                            // 添加向下移动选项
                            if (currentIndex < activeModules.Count - 1)
                            {
                                menu.AddItem(new GUIContent("向下移动"), false, () => MoveModule(moduleName, false));
                            }
                            else
                            {
                                menu.AddDisabledItem(new GUIContent("向下移动"));
                            }

                            menu.AddItem(new GUIContent("移除模块"), false, () => { RemoveModule(moduleName); });
                            menu.ShowAsContext();
                        },
                        defaultExpanded: true,debuger: material.HasProperty(moduleEntry.Key.PropertyName + "Debuger") ? FindProperty(moduleEntry.Key.PropertyName + "Debuger") : null); // 默认展开

                }
            }
            EditorGUILayout.EndVertical();
            EditorGUILayout.EndHorizontal();


            EditorGUILayout.Space();
            EditorGUILayout.BeginHorizontal();
            GUILayout.Space(-15);
            if (GUILayout.Button("添加模块", GUILayout.Height(30)))
            {
                ShowModuleSelector();
            }
            EditorGUILayout.EndHorizontal();
            
            EditorGUIHelper.DrawModuleContent(AfterModuleName, () => OnAfterDefaultGUI(materialEditor), null, isFldout: false, height: 0, true);
        }

        private void InitializeModuleStates()
        {
            m_ModuleStates.Clear();
            foreach (var module in ModuleProperties)
            {
                bool isEnabled = material.HasProperty(module.Key.PropertyName)
                                 && material.GetFloat(module.Key.PropertyName) > 0.5f;
                m_ModuleStates[module.Key.ModuleName] = isEnabled;
                SetShaderKeyword(module.Key.keyword, isEnabled);
            }

            // 创建适当大小的数组并初始化为true或false
            var activeModuleCount = m_ModuleStates.Count(kv => kv.Value);
            showModule = new bool[activeModuleCount];
            for (int i = 0; i < showModule.Length; i++)
            {
                showModule[i] = true; // 或者根据需要设置默认展开状态
            }
        }

        private void ShowModuleSelector()
        {
            GenericMenu menu = new GenericMenu();

            foreach (var module in ModuleProperties)
            {
                string moduleName = module.Key.ModuleName;
                if (!m_ModuleStates.ContainsKey(moduleName) || !m_ModuleStates[moduleName])
                {
                    menu.AddItem(new GUIContent(moduleName), false, () => AddModule(moduleName));
                }
                else
                {
                    menu.AddDisabledItem(new GUIContent(moduleName));
                }
            }

            menu.ShowAsContext();
        }

        private void AddModule(string moduleName)
        {
            // 记录变更前的状态
            Undo.RegisterCompleteObjectUndo(material, "Add Module");

            if (!m_ModuleStates.ContainsKey(moduleName))
            {
                m_ModuleStates.Add(moduleName, true);
            }
            else
            {
                m_ModuleStates[moduleName] = true;
            }

            var moduleEntry = ModuleProperties.First(x => x.Key.ModuleName == moduleName);
            if (material.HasProperty(moduleEntry.Key.PropertyName))
            {
                material.SetFloat(moduleEntry.Key.PropertyName, 1.0f);
                EditorUtility.SetDirty(material);
            }
            SetShaderKeyword(moduleEntry.Key.keyword, true);
        }

        private void RemoveModule(string moduleName)
        {
            // 记录变更前的状态
            Undo.RegisterCompleteObjectUndo(material, "Remove Module");

            m_ModuleStates[moduleName] = false;

            var moduleEntry = ModuleProperties.First(x => x.Key.ModuleName == moduleName);
            if (material.HasProperty(moduleEntry.Key.PropertyName))
            {
                material.SetFloat(moduleEntry.Key.PropertyName, 0.0f);
                EditorUtility.SetDirty(material);
            }
            SetShaderKeyword(moduleEntry.Key.keyword, false);
        }

        // 在 ModularShaderEditor 类中添加移动模块的辅助方法
        private void MoveModule(string moduleName, bool moveUp)
        {
            // 记录变更前的状态
            Undo.RegisterCompleteObjectUndo(material, $"Move Module {(moveUp ? "Up" : "Down")}");

            var activeModules = m_ModuleStates
                .Where(m => m.Value)
                .Select(m => m.Key)
                .ToList();

            int currentIndex = activeModules.IndexOf(moduleName);
            if (currentIndex < 0) return;

            int newIndex = moveUp ? currentIndex - 1 : currentIndex + 1;

            // 检查新位置是否有效
            if (newIndex >= 0 && newIndex < activeModules.Count)
            {
                // 交换位置
                var temp = activeModules[currentIndex];
                activeModules[currentIndex] = activeModules[newIndex];
                activeModules[newIndex] = temp;

                // 更新模块顺序
                m_ModuleStates.Clear();
                foreach (var module in activeModules)
                {
                    m_ModuleStates[module] = true;
                }
            }
        }


        public void DoPopup(MaterialEditor materialEditor, GUIContent label, MaterialProperty property, string[] options)
        {
            DoPopup(label, property, options, materialEditor);
        }

        public void DoPopup(GUIContent label, MaterialProperty property, string[] options, MaterialEditor materialEditor)
        {
            if (property == null)
                throw new ArgumentNullException("property");

            EditorGUI.showMixedValue = property.hasMixedValue;

            var mode = property.floatValue;
            EditorGUI.BeginChangeCheck();
            mode = EditorGUILayout.Popup(label, (int)mode, options);
            if (EditorGUI.EndChangeCheck())
            {
                materialEditor.RegisterPropertyChangeUndo(label.text);
                property.floatValue = mode;
            }

            EditorGUI.showMixedValue = false;
        }

        #region Utility Methods

        private void SetShaderKeyword(string keyword, bool enable)
        {
            if (enable)
                material.EnableKeyword(keyword);
            else
                material.DisableKeyword(keyword);
        }

        /// <summary>
        /// 查找材质属性
        /// </summary>
        protected MaterialProperty FindProperty(string propertyName)
        {
            var result = FindProperty(propertyName, m_Properties, false);
            if (result == null)
            {
                Debug.LogError($"没有找到参数 ： {propertyName} ");
                return null;
            }

            return result;
        }

        #endregion
    }
