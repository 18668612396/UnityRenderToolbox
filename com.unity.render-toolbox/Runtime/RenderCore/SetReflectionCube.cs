using UnityEngine;

[ExecuteAlways]
public class SetReflectionCube : MonoBehaviour
{
    public Cubemap reflectionCube;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalTexture("_ReflectionCube", reflectionCube);
    }
}
