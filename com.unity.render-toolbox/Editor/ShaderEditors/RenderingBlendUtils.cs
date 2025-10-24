namespace UnityEngine.Rendering.Universal
{
    public static class RenderingBlendUtils
    {
        public enum BlendMode
        {
            Alpha,
            Additive,
            Replace
        }

        // https://zhuanlan.zhihu.com/p/110517201
        // 因为正常场景不需要alpha通道写入 统一全部改成离屏渲染方式
        public static void CalculateRenderBlendMode(BlendMode blendMode,
            out UnityEngine.Rendering.BlendMode src, out UnityEngine.Rendering.BlendMode dst,
            out UnityEngine.Rendering.BlendMode srcA, out UnityEngine.Rendering.BlendMode dstA)
        {
            UnityEngine.Rendering.BlendMode srcEnd = UnityEngine.Rendering.BlendMode.Zero;   
            UnityEngine.Rendering.BlendMode dstEnd = UnityEngine.Rendering.BlendMode.Zero;   
            UnityEngine.Rendering.BlendMode srcAEnd = UnityEngine.Rendering.BlendMode.Zero;   
            UnityEngine.Rendering.BlendMode dstAEnd = UnityEngine.Rendering.BlendMode.Zero;
            bool isOffScreen = true;
            switch (blendMode)
            {

                case BlendMode.Alpha:
                    srcEnd = UnityEngine.Rendering.BlendMode.SrcAlpha;
                    dstEnd = UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                    if (isOffScreen)
                    {
                        srcAEnd = UnityEngine.Rendering.BlendMode.One;
                        dstAEnd = UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                    }
                    else
                    {
                        srcAEnd = UnityEngine.Rendering.BlendMode.SrcAlpha;
                        dstAEnd = UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                    }
                    break;


                case BlendMode.Additive:
                    srcEnd = UnityEngine.Rendering.BlendMode.SrcAlpha;
                    dstEnd = UnityEngine.Rendering.BlendMode.One;
                    if (isOffScreen)
                    {
                        srcAEnd = UnityEngine.Rendering.BlendMode.Zero;
                        dstAEnd = UnityEngine.Rendering.BlendMode.One;
                    }
                    else
                    {
                        srcAEnd = UnityEngine.Rendering.BlendMode.SrcAlpha;
                        dstAEnd = UnityEngine.Rendering.BlendMode.One;
                    }
                    break;

                case BlendMode.Replace:
                    srcEnd = UnityEngine.Rendering.BlendMode.One;
                    dstEnd = UnityEngine.Rendering.BlendMode.Zero;
                    if (isOffScreen)
                    {
                        srcAEnd = UnityEngine.Rendering.BlendMode.One;
                        dstAEnd = UnityEngine.Rendering.BlendMode.Zero;
                    }
                    else
                    {
                        srcAEnd = UnityEngine.Rendering.BlendMode.One;
                        dstAEnd = UnityEngine.Rendering.BlendMode.Zero;
                    }
                    break;
            }
            src = srcEnd;
            dst = dstEnd;
            srcA = srcAEnd;
            dstA = dstAEnd;

        }
    }
}