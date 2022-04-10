using UnityEngine;
using UnityEngine.Rendering;

partial class CameraRender
{
    partial void initGBuffer();
    partial void deferredRenderGBufferPass(bool useDynamicBatching, bool useGPUInstancing);
    partial void deferredRenderLightingPass();
    partial void DrawDeferred(bool useDynamicBatching, bool useGPUInstancings);
    partial void deferredRenderAOPass();
    partial void Cleanupdr();

    static Shader m_shader = Shader.Find("MyPipeline/DeferredRender");
    Material m_deferredRenderingMaterial = new Material(m_shader);
    static ShaderTagId m_gBufferPassId = new ShaderTagId("gBufferPass");
    static int[] geometricTextureId =
    {
        Shader.PropertyToID("_GPosition"),
        Shader.PropertyToID("_GNormal"),
        Shader.PropertyToID("_GAlbedo"),
        Shader.PropertyToID("_GMaterial")
    };
    static int aoTextureId = Shader.PropertyToID("_AoTexture"),
        samplesId = Shader.PropertyToID("samples");
    RenderTargetIdentifier[] m_renderTarget;
    static Vector4[] m_aosample;
    const string m_gbufferName = "GBufferPass";
    RenderBuffer defaultColorBuffer;
    RenderBuffer defaultDepthBuffer;
    Texture2D m_noiseTexture = Resources.Load<Texture2D>("Blue_Noise");
 //   RenderTexture 
    int width = 2018;
    int height = 2048;

    partial void initGBuffer()
    {
        if(m_aosample == null)
        {
            m_aosample = new Vector4[64];
            for(int i = 0; i < m_aosample.Length; i++)
            {
                m_aosample[i] = new Vector4(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f,1.0f), Random.Range(0.0f,1.0f),1.0f);
            }
        }
        //if(width != m_camera.pixelWidth || height != m_camera.pixelHeight)
        //{
        //if(m_camera.cameraType == CameraType.Game)
        //{
        //    defaultColorBuffer = m_camera.targetTexture.colorBuffer;
        //    defaultDepthBuffer = m_camera.targetTexture.depthBuffer;

        //    width = m_camera.targetTexture.width;
        //    height = m_camera.targetTexture.height;
        //    Debug.Log("3");
        //}
        //else
        if (m_camera.activeTexture != null)
        {
            defaultColorBuffer = m_camera.activeTexture.colorBuffer;
            defaultDepthBuffer = m_camera.activeTexture.depthBuffer;

            width = m_camera.activeTexture.width;
            height = m_camera.activeTexture.height;
            Debug.Log("1");

        }
        else
        {
            defaultColorBuffer = Graphics.activeColorBuffer;
            defaultDepthBuffer = Graphics.activeDepthBuffer;
            width = m_camera.pixelWidth;
            height = m_camera.pixelHeight;
            Debug.Log("2");
        }
        //Debug.Log(width);
        //Debug.Log(height);
        //for(int i = 0; i < geometricTextureId.Length; i++)
        //{
        //    m_buffer.ReleaseTemporaryRT(geometricTextureId[i]);
        //}
        m_buffer.GetTemporaryRT(geometricTextureId[0], width, height, 0, FilterMode.Point, RenderTextureFormat.ARGBFloat);
        m_buffer.GetTemporaryRT(geometricTextureId[1], width, height, 0, FilterMode.Point, RenderTextureFormat.ARGBFloat);
        m_buffer.GetTemporaryRT(geometricTextureId[2], width, height, 0, FilterMode.Point, RenderTextureFormat.ARGB32);
        m_buffer.GetTemporaryRT(geometricTextureId[3], width, height, 0, FilterMode.Point, RenderTextureFormat.ARGB32);
        ExecuteBuffer();
        m_renderTarget = new RenderTargetIdentifier[geometricTextureId.Length];
        for (int i = 0; i < geometricTextureId.Length; i++)
        {
            //m_renderTarget[i] = geometricTextureId[i];
            m_renderTarget[i] = geometricTextureId[i];
        }
        //}
        //Debug.Log(m_camera.pixelWidth);
        //Debug.Log(m_camera.pixelHeight);
        //Debug.Log(m_camera.activeTexture.width);
        //Debug.Log(m_camera.activeTexture.height);
        //Debug.Log(m_camera.targetTexture.width);
        //Debug.Log(m_camera.targetTexture.height);
    }

    partial void deferredRenderGBufferPass(bool useDynamicBatching, bool useGPUInstancing)
    {
        m_buffer.SetRenderTarget(m_renderTarget, defaultDepthBuffer);
        m_buffer.ClearRenderTarget(true, true, Color.white);
        ExecuteBuffer();
        var sortingSettings = new SortingSettings(m_camera) { criteria = SortingCriteria.CommonOpaque };
        var drawingSettings = new DrawingSettings(m_gBufferPassId, sortingSettings)
        {
            enableDynamicBatching = useDynamicBatching,
            enableInstancing = useGPUInstancing,
 //           perObjectData = PerObjectData.Lightmaps | PerObjectData.LightProbe | PerObjectData.LightProbeProxyVolume
        };
        var filteringSettings = new FilteringSettings(RenderQueueRange.all);
        drawingSettings.SetShaderPassName(1, m_gBufferPassId);
        m_context.DrawRenderers(m_cullResult, ref drawingSettings, ref filteringSettings);
        ExecuteBuffer();
    }

    partial void deferredRenderAOPass()
    {
        m_buffer.BeginSample("aogen");
        m_buffer.GetTemporaryRT(aoTextureId, width, height, 0, FilterMode.Point, RenderTextureFormat.ARGB32);
        m_buffer.SetRenderTarget(aoTextureId);
        for (int i = 0; i < 2; i++)
        {
            m_buffer.SetGlobalTexture(geometricTextureId[i], m_renderTarget[i]);
        }
        m_buffer.ClearRenderTarget(false, true, Color.white);
        m_buffer.SetGlobalVectorArray(samplesId, m_aosample);
        m_buffer.DrawProcedural(Matrix4x4.identity, m_deferredRenderingMaterial, 1, MeshTopology.Triangles, 3);
        m_buffer.EndSample("aogen");
        ExecuteBuffer();
    }

    partial void Cleanupdr()
    {
        for (int i = 0; i < geometricTextureId.Length; i++)
        {
            m_buffer.ReleaseTemporaryRT(geometricTextureId[i]);
        }
        m_buffer.ReleaseTemporaryRT(aoTextureId);
        ExecuteBuffer();
    }
    partial void deferredRenderLightingPass()
    {
        m_buffer.BeginSample("deferred lighting pass");
        m_buffer.SetRenderTarget(defaultColorBuffer,defaultDepthBuffer);
        for (int i = 0; i < m_renderTarget.Length; i++)
        {
            m_buffer.SetGlobalTexture(geometricTextureId[i], m_renderTarget[i]);
        }
        m_buffer.SetGlobalTexture(aoTextureId, aoTextureId);
        m_buffer.DrawProcedural(Matrix4x4.identity, m_deferredRenderingMaterial, 0, MeshTopology.Triangles, 3);
        m_buffer.EndSample("deferred lighting pass");
        ExecuteBuffer();
    }

    partial void DrawDeferred(bool useDynamicBatching, bool useGPUInstancing)
    {
        initGBuffer();
        deferredRenderGBufferPass(useDynamicBatching, useGPUInstancing);
        deferredRenderAOPass();
        deferredRenderLightingPass();
    }
}
