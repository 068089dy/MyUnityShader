using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class GenerateLight : EditorWindow
{
    
    [MenuItem("MyLight/Generate Current Scene")]
    public static void GenerateLightCurScene()
    {
        if (!Lightmapping.isRunning)
        {
            Lightmapping.Bake();
        }
    }
    
    [MenuItem("MyLight/Generate")]
    public static void GenerateLightM()
    {
        if (!Lightmapping.isRunning)
        {
            Lightmapping.BakeMultipleScenes(new string[]
            {
                "Assets/Shader/RayMarching/VolumeCloud/VolumnScene.unity"
            });
        }
    }
    
    [MenuItem("MyLight/Stop")]
    public static void ForceStopLightM()
    {
        if (Lightmapping.isRunning)
        {
            Lightmapping.ForceStop();
        }
    }

//    private void OnGUI()
//    {
//        GUILayout.Label("Base Settings", EditorStyles.boldLabel);
//        if (GUILayout.Button("Generate"))
//        {
//            GenerateLightM();
//        }
//    }
}
