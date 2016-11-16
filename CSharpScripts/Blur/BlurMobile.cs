using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class BlurMobile : MonoBehaviour 
{
	#region Public Variables

	public Shader shader;

	[Range(0, 6), Tooltip("DownSample iterations. The larger the faster. ")]
	public int DownSampleNum = 2;
	
	[Range(0.0f, 20.0f), Tooltip("How blur the final result is. ")]
	public float BlurSpreadSize = 3.0f;
	
	[Range(0, 8), Tooltip("How many times do we iterate. ")]
	public int BlurIterations = 3;

	#endregion

	#region Private Attributes

	private Material material
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

	private Material _mat;

	#endregion

    #region MonoBehaviours

    private void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        if (shader != null)
        {
            float width = 1.0f / (1.0f * (1 << DownSampleNum));
            material.SetFloat("_DownSampleValue", BlurSpreadSize * width);
            source.filterMode = FilterMode.Bilinear;
            int rtWidth = source.width >> DownSampleNum;
            int rtHeight = source.height >> DownSampleNum;
            RenderTexture renderBuffer = RenderTexture.GetTemporary(rtWidth, rtHeight, 0, source.format);
            renderBuffer.filterMode = FilterMode.Bilinear;
            Graphics.Blit(source, renderBuffer, material, 0);
            for (int i = 0; i < BlurIterations; i++)
            {
                float iterationOffset = i * 1.0f;
                _mat.SetFloat("_DownSampleValue", BlurSpreadSize * width + iterationOffset);
                RenderTexture tempBuffer = RenderTexture.GetTemporary(rtWidth, rtHeight, 0, source.format);
                tempBuffer.filterMode = FilterMode.Bilinear;
                Graphics.Blit(renderBuffer, tempBuffer, material, 1);
                RenderTexture.ReleaseTemporary(renderBuffer);
                renderBuffer = tempBuffer;
                tempBuffer = RenderTexture.GetTemporary(rtWidth, rtHeight, 0, source.format);
                tempBuffer.filterMode = FilterMode.Bilinear;
                Graphics.Blit(renderBuffer, tempBuffer, material, 2);
                RenderTexture.ReleaseTemporary(renderBuffer);
                renderBuffer = tempBuffer;
            }
            Graphics.Blit(renderBuffer, destination);
            RenderTexture.ReleaseTemporary(renderBuffer);
        }
    }

    #endregion
}
