using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
public class FrameLimit : MonoBehaviour
{
    // Start is called before the first frame update
    public int targetFrameRate = 30;
    public Text fpsTx;
 
    private void Start()
    {
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = targetFrameRate;
    }

    // Update is called once per frame
    void Update()
    {
        if (fpsTx)
        {
            fpsTx.text = $"FPS:{(int) (1 / Time.deltaTime)}";
        }
    }
}
