using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// [ExecuteInEditMode]
public class RayMarching : MonoBehaviour
{
    [SerializeField]
    public MaterialPropertyBlock block;

    public Renderer rd;

    public float radius;
    // Start is called before the first frame update
    void Start()
    {
        rd = GetComponent<Renderer>();
        // if (block == null)
        //     block = new MaterialPropertyBlock();
        if (rd)
        {
            
            rd.material.SetVector("center", transform.position);
            rd.material.SetFloat("radius", radius);
            // rd.SetPropertyBlock(block);
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
