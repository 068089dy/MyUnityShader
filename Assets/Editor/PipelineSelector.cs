using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class PipelineSettingWindow : EditorWindow
{
    public RenderPipelineAsset urpAsset;
    [MenuItem("MyPipline/Select Pipeline")]
    private static void SelectUrp()
    {
        
        var window = (PipelineSettingWindow)GetWindow(typeof(PipelineSettingWindow));
        window.titleContent = new GUIContent("SelectPipeline");
        window.Show();
    }

    private void Awake()
    {
        urpAsset = AssetDatabase.LoadAssetAtPath<RenderPipelineAsset>(PlayerPrefs.GetString("DefaultUrpPipelineAsset"));
    }


    private void OnGUI()
    {
        GUILayout.Label("Base Settings", EditorStyles.boldLabel);
        
        urpAsset = (RenderPipelineAsset)EditorGUILayout.ObjectField("urp asset", urpAsset, typeof(RenderPipelineAsset));

        if (GUILayout.Button("Select Urp"))
        {
            if (urpAsset != null)
            {
                PlayerPrefs.SetString("DefaultUrpPipelineAsset", AssetDatabase.GetAssetPath(urpAsset));
                QualitySettings.renderPipeline = urpAsset;
                GraphicsSettings.defaultRenderPipeline = urpAsset;
            }
        }
        
        if (GUILayout.Button("Select Built-in"))
        {
            
            QualitySettings.renderPipeline = null; 
            GraphicsSettings.defaultRenderPipeline = null;
            
        }
    }
}