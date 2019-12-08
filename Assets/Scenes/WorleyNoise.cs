using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class WorleyNoise : MonoBehaviour
{
    //public region
    #region public parameters

    public Shader worleyNoiseShader = null;

    [Range(1, 100)]
    public float uvScale = 10f;

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
            worleyNoiseMat.hideFlags = HideFlags.HideAndDontSave;
        }
    }

    void OnRenderImage( RenderTexture src, RenderTexture dest )
    {
        if ( worleyNoiseMat != null )
        {
            worleyNoiseMat.SetFloat("_UVScale", uvScale);

            Graphics.Blit( src, dest, worleyNoiseMat );
        }
        else
        {
            Graphics.Blit( src, dest );
        }
    }
}
