using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode,ImageEffectAllowedInSceneView]
public class BloomEffect : MonoBehaviour
{
    public Material mat;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        int width = source.width;
        int height = source.height;
        
        RenderTexture tmpSource = RenderTexture.GetTemporary(width, height, 0, source.format);  
        RenderTexture tmpDest = RenderTexture.GetTemporary(width, height, 0, source.format);  
        Graphics.Blit(source, tmpSource);
        for (int i = 0; i < 4; i++)
        {
            width/=2;
            height/=2;

            tmpDest = RenderTexture.GetTemporary(width, height, 0, source.format);  
            Graphics.Blit(tmpSource, tmpDest);

            RenderTexture.ReleaseTemporary(tmpSource);
            tmpSource = tmpDest;
        }
        
        Graphics.Blit(tmpDest, destination);
        RenderTexture.ReleaseTemporary(tmpDest);
        
        Graphics.Blit(tmpSource, tmpDest);

        RenderTexture.ReleaseTemporary(tmpSource);
        tmpSource = tmpDest;

        for (int i = 0; i < 4; i++)
        {
            width*=2;
            height*=2;

            tmpDest = RenderTexture.GetTemporary(width, height, 0, source.format);  
            Graphics.Blit(tmpSource, tmpDest);

            RenderTexture.ReleaseTemporary(tmpSource);
            tmpSource = tmpDest;
        }
        
        Graphics.Blit(tmpDest, destination);
        RenderTexture.ReleaseTemporary(tmpDest);
    }
}
