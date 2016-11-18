using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class MobileFlare : MonoBehaviour 
{
    #region Public Properties

    public Shader shader;

    public Material material
    {
        get
        {
            if (_mat == null)
            {
                _mat = new Material(shader);
                _mat.hideFlags = HideFlags.HideAndDontSave;
            }
            return _mat;
        }
    }

    #endregion

    #region Flare Properties

    [Range (0.1f, 1f)]
    public float threshold = 0.8f;

    [Range (0.1f, 10f)]
    public float intensity = 5f;

    [Range (1, 5)]
    public int ghostNum = 3;

    [Range (0.01f, 0.8f)]
    public float ghostDispersal = 0.23f;

    [Range (0.01f, 1f)]
    public float haloWidth = 0.41f;

    public Vector4 colorDistortion = new Vector4 (0.01f, 0.02f, 0.015f);

    public Texture2D gradient;

    [Range(0, 5)]
    public int downSampleNum = 1;

    [Range (0.1f, 20f)]
    public float blurSpreadSize = 5f;

    [Range (1, 10)]
    public int blurIterations = 2;

    #endregion

    #region Private Variables

    private Material _mat;

    #endregion

    #region MonoBehaviours

    private void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        if (shader != null)
        {
            material.SetFloat("_Threshold", threshold);
            material.SetFloat("_Intensity", intensity);
            material.SetInt("_GhostNum", ghostNum);
            material.SetFloat("_GhostDispersal", ghostDispersal);
            material.SetFloat("_HaloWidth", haloWidth);
            material.SetVector("_ColorDistortion", colorDistortion);
            material.SetTexture("_Gradient", gradient);
            float widthMod = 1.0f / (1.0f * (1 << downSampleNum));
            int rtWidth = source.width >> downSampleNum;
            int rtHright = source.height >> downSampleNum;
            RenderTexture downSampleBuffer = RenderTexture.GetTemporary(rtWidth, rtHright, 0, source.format);
            downSampleBuffer.filterMode = FilterMode.Bilinear;
            Graphics.Blit(source, downSampleBuffer, material, 0);
            RenderTexture ghostBuffer = RenderTexture.GetTemporary(rtWidth, rtHright, 0, source.format);
            ghostBuffer.filterMode = FilterMode.Bilinear;
            Graphics.Blit(downSampleBuffer, ghostBuffer, material, 1);
            RenderTexture.ReleaseTemporary(downSampleBuffer);
            for (int i = 0; i < blurIterations; i++)
            {
                material.SetFloat("_DownSampleValue", widthMod * blurSpreadSize * 1.0f * i);
                RenderTexture tempBuffer = RenderTexture.GetTemporary(rtWidth, rtHright, 0, source.format);
                tempBuffer.filterMode = FilterMode.Bilinear;
                Graphics.Blit(ghostBuffer, tempBuffer, material, 2);
                RenderTexture.ReleaseTemporary(ghostBuffer);
                ghostBuffer = tempBuffer;
                tempBuffer = RenderTexture.GetTemporary(rtWidth, rtHright, 0, source.format);
                tempBuffer.filterMode = FilterMode.Bilinear;
                Graphics.Blit(ghostBuffer, tempBuffer, material, 3);
                RenderTexture.ReleaseTemporary(ghostBuffer);
                ghostBuffer = tempBuffer;
            }
            material.SetTexture("_Flare", ghostBuffer);
            Graphics.Blit(source, destination, material, 4);
            RenderTexture.ReleaseTemporary(ghostBuffer);
        }
    }

    #endregion
}
