using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class WorleyNoise : MonoBehaviour
{
    //public region
    #region public parameters

    //basic control
    public Shader worleyNoiseShader = null;
    [Range(1, 100)]
    public float uvScale = 10f;
    [Range(1, 100)]
    public float normalIntensity = 10f;

    //material control
    public Color diffuseColor = Color.gray;
    public Color specularColor = Color.gray;
    [Range(0, 1)]
    public float roughness = 0.5f;
    public Vector4 lightDir = new Vector4(1,0,0);

    #endregion


    //private region
    #region private parameters

    private Material worleyNoiseMat = null;

    #endregion


    void OnEnable()
    {
        if ( worleyNoiseMat == null )
        {
            if ( worleyNoiseShader == null )
            {
                worleyNoiseShader = Shader.Find( "Custom/WorleyNoiseShader" );
            }
            
            if ( worleyNoiseShader == null )
            {
                Debug.LogError( "Can't find WorleyNoise Shader" );
                return;
            }

            worleyNoiseMat = new Material( worleyNoiseShader );
            worleyNoiseMat.SetFloat("_UVScale", uvScale);
            worleyNoiseMat.SetFloat("_NormalIntensity", normalIntensity);

            worleyNoiseMat.SetColor("_DiffuseColor", diffuseColor);
            worleyNoiseMat.SetColor("_SpecularColor", specularColor);
            worleyNoiseMat.SetFloat("_Roughness", roughness);
            worleyNoiseMat.SetVector("_LightDirection", lightDir);

            worleyNoiseMat.hideFlags = HideFlags.HideAndDontSave;
        }
    }

    void OnRenderImage( RenderTexture src, RenderTexture dest )
    {
        if ( worleyNoiseMat != null )
        {
            worleyNoiseMat.SetFloat("_UVScale", uvScale);
            worleyNoiseMat.SetFloat("_NormalIntensity", normalIntensity);

            worleyNoiseMat.SetColor("_DiffuseColor", diffuseColor);
            worleyNoiseMat.SetColor("_SpecularColor", specularColor);
            worleyNoiseMat.SetFloat("_Roughness", roughness);
            worleyNoiseMat.SetVector("_LightDirection", lightDir);

            Graphics.Blit( src, dest, worleyNoiseMat );
        }
        else
        {
            Graphics.Blit( src, dest );
        }
    }
}
