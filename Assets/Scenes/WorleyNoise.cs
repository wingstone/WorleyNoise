using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class WorleyNoise : MonoBehaviour
{

    public enum DisplayEnum
    {
        DISPLAY_DISTANCE,
        DISPLAY_LIGHT,
        DISPLAY_VOLUME,
    };

    string[] DisplayKeywordsStrings = 
    {
        "DISPLAY_DISTANCE",
        "DISPLAY_LIGHT",
        "DISPLAY_VOLUME",
    };

    //public region
    #region public parameters
    
    public DisplayEnum displayType = DisplayEnum.DISPLAY_DISTANCE;

    //basic control
    [Header("Basic prameters")]
    public Shader worleyNoiseShader = null;
    [Range(1, 100)]
    public float uvScale = 10f;
    [Range(1, 100)]
    public float normalIntensity = 10f;

    //light control
    [Header("Light prameters")]
    public Color diffuseColor = Color.gray;
    public Color specularColor = Color.gray;
    [Range(0, 1)]
    public float roughness = 0.5f;
    public Vector4 lightDir = new Vector4(1,0,0);

    //volume color
    [Header("Volume prameters")]
    public Color volumeColor = Color.gray;

    #endregion


    //private region
    #region private parameters

    private Material worleyNoiseMat = null;
    DisplayEnum oldDisplayType = DisplayEnum.DISPLAY_DISTANCE;
    bool isFirst = true;
    #endregion

    void UpdateMaterial()
    {
        worleyNoiseMat.SetFloat("_UVScale", uvScale);
        worleyNoiseMat.SetFloat("_NormalIntensity", normalIntensity);

        worleyNoiseMat.SetColor("_DiffuseColor", diffuseColor);
        worleyNoiseMat.SetColor("_SpecularColor", specularColor);
        worleyNoiseMat.SetFloat("_Roughness", roughness);
        worleyNoiseMat.SetVector("_LightDirection", lightDir);

        worleyNoiseMat.SetColor("_VolumeColor", volumeColor);

        if ( oldDisplayType != displayType || isFirst)
        {
            for (int i = 0; i < 3; i++)
            {
                if (i == (int)displayType )
                {
                    worleyNoiseMat.EnableKeyword(DisplayKeywordsStrings[i]);
                }
                else
                {
                    worleyNoiseMat.DisableKeyword(DisplayKeywordsStrings[i]);
                }
            }
            oldDisplayType = displayType;
            isFirst = false;
        }
    }


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
            UpdateMaterial();
            worleyNoiseMat.hideFlags = HideFlags.HideAndDontSave;
        }
    }

    void OnRenderImage( RenderTexture src, RenderTexture dest )
    {
        if ( worleyNoiseMat != null )
        {
            UpdateMaterial();

            Graphics.Blit( src, dest, worleyNoiseMat );
        }
        else
        {
            Graphics.Blit( src, dest );
        }
    }
}
