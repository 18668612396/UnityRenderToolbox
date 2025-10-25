using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RendererUtils;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;

public class SubSurfaceScatteringRenderFeature : ScriptableRendererFeature
{
    SubSurfaceScatteringRenderPass m_SubSurfaceScatteringRenderPass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_SubSurfaceScatteringRenderPass = new SubSurfaceScatteringRenderPass();

        // Configures where the render pass should be injected.
        m_SubSurfaceScatteringRenderPass.renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_SubSurfaceScatteringRenderPass);
    }
}

public class SubSurfaceScatteringRenderPass : ScriptableRenderPass
{
    private readonly string m_ProfilerTag = "SubSurfaceScatteringDiffuse";

    //定义ShaderLightMode
    private readonly ShaderTagId m_ShaderLightModeTag = new ShaderTagId("SubSurfaceScatteringDiffuse");
    private RenderTextureDescriptor m_TargetDescriptor;

    // This class stores the data needed by the RenderGraph pass.
    // It is passed as a parameter to the delegate function that executes the RenderGraph pass.
    private class PassData
    {
        public TextureHandle sss; //有两张，第一张是绘制法线，第二张是绘制深度

        // public TextureHandle depth;//暂时先不用
        public RendererListHandle rendererListHandle;
    }


    // RecordRenderGraph is where the RenderGraph handle can be accessed, through which render passes can be added to the graph.
    // FrameData is a context container through which URP resources can be accessed and managed.
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        // This adds a raster render pass to the graph, specifying the name and the data type that will be passed to the ExecutePass function.
        using (var builder = renderGraph.AddRasterRenderPass<PassData>(m_ProfilerTag, out var passData))
        {
            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
            UniversalRenderingData renderingData = frameData.Get<UniversalRenderingData>();
            // 使用通用摄像机描述符作为我们纹理的基础
            var cameraTargetDesc = cameraData.cameraTargetDescriptor;
            // a. 法线纹理描述符和句柄 (Handle)
            TextureDesc sssDesc = new TextureDesc(cameraTargetDesc.width, cameraTargetDesc.height)
            {
                colorFormat = GraphicsFormat.R16G16B16A16_SNorm, // 这是 R10G10B10A2 对应的 GraphicsFormat
                name = "_SubSurfaceScatteringDiffuse"
            };
            passData.sss = renderGraph.CreateTexture(sssDesc);
            // b. 深度纹理描述符和句柄

            /*
            // R32_SFloat 是 RFloat 的 GraphicsFormat, 提供最佳精度
            TextureDesc depthDesc = new TextureDesc(cameraTargetDesc.width, cameraTargetDesc.height)
            {
                colorFormat = GraphicsFormat.R32_SFloat,
                name = "_DepthTexture"
            };
            */

            //设置RenderList
            DrawingSettings drawingSettings =
                new DrawingSettings(m_ShaderLightModeTag, new SortingSettings(cameraData.camera))
                {
                    perObjectData = PerObjectData.LightProbe, // 启用 Light Probe 数据传递（包括 SH）
                    enableDynamicBatching = true, // 启用动态批处理
                    enableInstancing = true // 启用实例化
                };
            FilteringSettings filteringSettings =
                new FilteringSettings(RenderQueueRange.opaque, cameraData.camera.cullingMask);
            // 创建渲染器列表
            var rendererListParams =
                new RendererListParams(renderingData.cullResults, drawingSettings, filteringSettings);
            passData.rendererListHandle = renderGraph.CreateRendererList(rendererListParams);
            // passData.depth = renderGraph.CreateTexture(depthDesc);//暂时先不用
            builder.UseRendererList(passData.rendererListHandle);
            //设置渲染目标
            builder.SetRenderAttachment(passData.sss, 0); // 设置法线纹理为渲染目标的第一个附件
            // builder.SetRenderAttachment(passData.depth, 1); // 设置深度纹理为渲染目标的第二个附件,暂时先不用
            builder.SetGlobalTextureAfterPass(passData.sss, Shader.PropertyToID("_SubSurfaceScatteringDiffuse"));
            // builder.SetGlobalTextureAfterPass(passData.depth, Shader.PropertyToID("_DepthTexture"));//暂时先不用
            // c. 设置深度纹理
            if (resourceData.activeDepthTexture.IsValid())
                builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture);

            builder.SetRenderFunc((PassData data, RasterGraphContext context) => ExecutePass(data, context));
        }
    }

    // This static method is passed as the RenderFunc delegate to the RenderGraph render pass.
    // It is used to execute draw commands.
    static void ExecutePass(PassData data, RasterGraphContext context)
    {
        context.cmd.DrawRendererList(data.rendererListHandle);
    }

    // NOTE: This method is part of the compatibility rendering path, please use the Render Graph API above instead.
    // This method is called before executing the render pass.
    // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
    // When empty this render pass will render to the active camera render target.
    // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
    // The render pipeline will ensure target setup and clearing happens in a performant manner.
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
    }

    // NOTE: This method is part of the compatibility rendering path, please use the Render Graph API above instead.
    // Here you can implement the rendering logic.
    // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
    // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
    // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
    }

    // NOTE: This method is part of the compatibility rendering path, please use the Render Graph API above instead.
    // Cleanup any allocated resources that were created during the execution of this render pass.
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }
}