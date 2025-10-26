using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace Nemo.Editor
{
    public static class TextureUtils
    {
        public enum ImageType : int
        {
            TGA = 0,
            PNG = 1,
            JPG = 2,
            EXR = 3,
        }

        private static readonly string[] s_SupportedTextureEExtensions =
        {
            ".png",
            ".tga",
            ".exr",
        };

        private enum Channel : int
        {
            R = 0x0001,
            G = 0x0010,
            B = 0x0100,
            A = 0x1000
        };

        [MenuItem("Assets/Nemo/图片/翻转 G 通道")]
        private static void FlipNormalMapGChannel()
        {
            var selectionPath = AssetDatabase.GetAssetPath(Selection.activeObject);

            Debug.Log(selectionPath);

            if (string.IsNullOrEmpty(selectionPath))
                return;

            var extension = Path.GetExtension(selectionPath);

            bool supported = false;

            foreach (var p in s_SupportedTextureEExtensions)
            {
                if (p.ToLower().Equals(extension.ToLower()))
                {
                    supported = true;
                    break;
                }
            }

            if (!supported)
            {
                Debug.LogError("暂不支持此图片格式");
                return;
            }

            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(selectionPath);

            if (texture == null)
            {
                Debug.LogError("图片资源实例化失败");
                return;
            }

            TextureImporter importer = (TextureImporter)AssetImporter.GetAtPath(selectionPath);

            if (importer == null)
                return;

            if (!importer.isReadable)
            {
                Debug.LogError("图片不可读");
                return;
            }

            if (importer.textureType == TextureImporterType.NormalMap)
            {
                Debug.LogError("暂不支持法线图");
                return;
            }

            var filename = Path.GetFileNameWithoutExtension(selectionPath);

            var srcPixels = texture.GetPixels();

            Texture2D temp = new Texture2D(texture.width, texture.height, TextureFormat.ARGB32, importer.mipmapEnabled);

            Color[] pixels = new Color[srcPixels.Length];

            for (int i = 0; i < srcPixels.Length; ++i)
            {
                pixels[i].r = srcPixels[i].r;
                pixels[i].g = 1.0f - srcPixels[i].g;
                pixels[i].b = srcPixels[i].b;
                pixels[i].a = srcPixels[i].a;
            }

            temp.SetPixels(pixels);
            temp.Apply();

            string outPath = selectionPath.Replace(filename, filename + "_INVG");

            byte[] bytes = temp.EncodeToPNG();
            File.WriteAllBytes(outPath, bytes);

            AssetDatabase.Refresh();
        }

        [MenuItem("Assets/Nemo/图片/通道分离(A)")]
        private static void SeperateChannelA()
        {
            _SeperateChannel((int)Channel.A, (channel) => { return "_a"; });
        }

        [MenuItem("Assets/Nemo/图片/通道分离(RGBA)")]
        private static void SeperateChannelRGBA()
        {
            _SeperateChannel((int)Channel.R | (int)Channel.G | (int)Channel.B | (int)Channel.A, (channel) =>
            {
                switch (channel)
                {
                    case Channel.R:
                        return "_r";
                    case Channel.G:
                        return "_g";
                    case Channel.B:
                        return "_b";
                    case Channel.A:
                        return "_a";
                }

                return "_unknow";
            });
        }

        [MenuItem("Assets/Nemo/图片/合成(RGBA)")]
        private static void CombineRGBA()
        {
            Texture2D r = null;
            Texture2D g = null;
            Texture2D b = null;
            Texture2D a = null;

            string outPath = "";

            foreach (var obj in Selection.objects)
            {
                var path = AssetDatabase.GetAssetPath(obj);

                if (path.Contains("_r"))
                {
                    r = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                    outPath = path.Replace("_r", "_rgba");
                }
                else if (path.Contains("_g"))
                {
                    g = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                }
                else if (path.Contains("_b"))
                {
                    b = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                }
                else if (path.Contains("_a"))
                {
                    a = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                }
            }

            if (r == null || g == null || b == null || a == null)
                return;

            var RPixels = r.GetPixels();
            var GPixels = g.GetPixels();
            var BPixels = b.GetPixels();
            var APixels = a.GetPixels();

            var temp = new Texture2D(r.width, r.height, TextureFormat.ARGB32, true);

            Color[] pixels = new Color[RPixels.Length];

            for (int i = 0; i < RPixels.Length; ++i)
            {
                pixels[i].r = RPixels[i].r;
                pixels[i].g = GPixels[i].r;
                pixels[i].b = BPixels[i].r;
                pixels[i].a = APixels[i].r;
            }

            temp.SetPixels(pixels);
            temp.Apply();

            byte[] bytes = temp.EncodeToPNG();
            File.WriteAllBytes(outPath, bytes);

            AssetDatabase.Refresh();
        }

        private static void _SeperateChannel(int channelMask, Func<Channel, string> getPostfixWithChannel)
        {
            var selectionPath = AssetDatabase.GetAssetPath(Selection.activeObject);

            Debug.Log(selectionPath);

            if (string.IsNullOrEmpty(selectionPath))
                return;

            var extension = Path.GetExtension(selectionPath);

            bool supported = false;

            foreach (var p in s_SupportedTextureEExtensions)
            {
                if (p.ToLower().Equals(extension.ToLower()))
                {
                    supported = true;
                    break;
                }
            }

            if (!supported)
            {
                Debug.LogError("暂不支持此图片格式");
                return;
            }

            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(selectionPath);

            if (texture == null)
            {
                Debug.LogError("图片资源实例化失败");
                return;
            }

            TextureImporter importer = (TextureImporter)AssetImporter.GetAtPath(selectionPath);

            if (importer == null)
                return;

            if (!importer.isReadable)
            {
                Debug.LogError("图片不可读");
                return;
            }

            if (importer.textureType == TextureImporterType.NormalMap)
            {
                Debug.LogError("暂不支持法线图");
                return;
            }

            var filename = Path.GetFileNameWithoutExtension(selectionPath);

            var srcPixels = texture.GetPixels();

            Action<Func<int, float>, string> action = (getColor, posfix) =>
            {
                Texture2D temp = new Texture2D(texture.width, texture.height, TextureFormat.ARGB32, importer.mipmapEnabled);

                Color[] pixels = new Color[srcPixels.Length];

                for (int i = 0; i < srcPixels.Length; ++i)
                {
                    pixels[i].r = pixels[i].g = pixels[i].b = getColor(i);
                    pixels[i].a = 1;
                }

                temp.SetPixels(pixels);
                temp.Apply();

                string outPath = selectionPath.Replace(filename, filename + posfix);

                byte[] bytes = temp.EncodeToPNG();
                File.WriteAllBytes(outPath, bytes);
            };

            if ((channelMask & (int)Channel.A) > 0)
            {
                action((i) => { return srcPixels[i].a; }, getPostfixWithChannel(Channel.A));
            }

            if ((channelMask & (int)Channel.G) > 0)
            {
                action((i) => { return srcPixels[i].g; }, getPostfixWithChannel(Channel.G));
            }

            if ((channelMask & (int)Channel.B) > 0)
            {
                action((i) => { return srcPixels[i].b; }, getPostfixWithChannel(Channel.B));
            }

            if ((channelMask & (int)Channel.R) > 0)
            {
                action((i) => { return srcPixels[i].r; }, getPostfixWithChannel(Channel.R));
            }

            AssetDatabase.Refresh();
        }

        [MenuItem("Assets/Nemo/图片/提取MipMap")]
        private static void ExtractAllMipmaps()
        {
            string outPath = "";

            foreach (var obj in Selection.objects)
            {
                var path = AssetDatabase.GetAssetPath(obj);

                var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                ;

                if (texture == null)
                    continue;

                for (int mip = 1; mip < texture.mipmapCount; ++mip)
                {
                    var srcPixels = texture.GetPixels32(mip);

                    Color32[] pixels = new Color32[srcPixels.Length];

                    int scale = (int)Math.Pow(2, mip);

                    var temp = new Texture2D(texture.width / scale, texture.height / scale, TextureFormat.ARGB32, true);

                    for (int i = 0; i < srcPixels.Length; ++i)
                    {
                        pixels[i] = srcPixels[i];
                    }

                    temp.SetPixels32(pixels);
                    temp.Apply();

                    byte[] bytes = temp.EncodeToPNG();
                    string name = Path.GetFileNameWithoutExtension(path);
                    outPath = path.Replace(name, name + "_mip" + mip.ToString());
                    File.WriteAllBytes(outPath, bytes);
                }
            }

            AssetDatabase.Refresh();
        }

        [MenuItem("Assets/Nemo/图片/LDR转HDR")]
        private static void GenerateHDRTexture()
        {
            var selectionPath = AssetDatabase.GetAssetPath(Selection.activeObject);

            if (string.IsNullOrEmpty(selectionPath))
                return;

            var extension = Path.GetExtension(selectionPath);

            var supported = false;

            foreach (var p in s_SupportedTextureEExtensions)
            {
                if (!p.ToLower().Equals(extension.ToLower())) continue;
                supported = true;
                break;
            }

            if (!supported)
            {
                Debug.LogError("暂不支持此图片格式");
                return;
            }

            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(selectionPath);

            if (texture == null)
            {
                Debug.LogError("图片资源实例化失败");
                return;
            }

            var importer = (TextureImporter)AssetImporter.GetAtPath(selectionPath);

            if (importer == null)
                return;

            if (!importer.isReadable)
            {
                Debug.LogError("图片不可读");
                return;
            }

            if (importer.textureType == TextureImporterType.NormalMap)
            {
                Debug.LogError("暂不支持法线图");
                return;
            }

            var srcPixels = texture.GetPixels();

            var hdr = new Texture2D(texture.width, texture.height, TextureFormat.RGBAFloat, false);
            var dstPixels = hdr.GetPixels();

            srcPixels.CopyTo(dstPixels, 0);
            hdr.SetPixels(dstPixels);
            hdr.Apply();

            var filename = Path.GetFileNameWithoutExtension(selectionPath);
            selectionPath = selectionPath.Replace(filename, filename + "_hdr");
            var outPath = selectionPath.Replace(Path.GetExtension(selectionPath), ".exr");
            Debug.Log("Out Path = " + outPath);

            var bytes = hdr.EncodeToEXR(Texture2D.EXRFlags.CompressZIP);
            File.WriteAllBytes(outPath, bytes);

            UnityEngine.Object.DestroyImmediate(hdr);

            AssetDatabase.Refresh();
        }

        private static readonly Vector4 s_DecodeInstructions = new Vector4(4.59479f, 1.00f, 0.00f, 0.00f);

        [MenuItem("Assets/Nemo/图片/HDR解压")]
        private static void DecodeHDR()
        {
            var selectionPath = AssetDatabase.GetAssetPath(Selection.activeObject);

            if (string.IsNullOrEmpty(selectionPath))
                return;

            var extension = Path.GetExtension(selectionPath);

            var supported = extension == ".exr";

            if (!supported)
            {
                Debug.LogError("仅支持exr图片格式");
                return;
            }

            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(selectionPath);

            if (texture == null)
            {
                Debug.LogError("图片资源实例化失败");
                return;
            }

            var importer = (TextureImporter)AssetImporter.GetAtPath(selectionPath);

            if (importer == null)
                return;

            if (!importer.isReadable)
            {
                Debug.LogError("图片不可读");
                return;
            }

            if (importer.textureType == TextureImporterType.NormalMap)
            {
                Debug.LogError("暂不支持法线图");
                return;
            }
            else if (importer.textureShape != TextureImporterShape.Texture2D)
            {
                Debug.LogError("仅支持2D贴图");
            }

            var srcPixels = texture.GetPixels();

            Texture2D decoded = new Texture2D(texture.width, texture.height, TextureFormat.RGBAFloat, false);
            var dstPixels = decoded.GetPixels();

            srcPixels.CopyTo(dstPixels, 0);

            var scaleFactor = s_DecodeInstructions.x * (float)Math.Pow(1.0f, s_DecodeInstructions.y);

            Debug.LogFormat("scaleFactor = {0}", scaleFactor);

            for (int i = 0; i < texture.width * texture.height; ++i)
            {
                dstPixels[i].r *= scaleFactor;
                dstPixels[i].g *= scaleFactor;
                dstPixels[i].b *= scaleFactor;
                dstPixels[i].a *= scaleFactor;
            }

            decoded.SetPixels(dstPixels);
            decoded.Apply();

            var filename = Path.GetFileName(selectionPath);
            var filenameWithoutExt = Path.GetFileNameWithoutExtension(selectionPath);
            var newFilename = filename.Replace(filenameWithoutExt, filenameWithoutExt + "_decoded");
            var outPath = selectionPath.Replace(filename, newFilename);

            Debug.Log("Out Path = " + outPath);

            byte[] bytes = decoded.EncodeToEXR(Texture2D.EXRFlags.CompressZIP);
            File.WriteAllBytes(outPath, bytes);

            UnityEngine.Object.DestroyImmediate(decoded);

            AssetDatabase.Refresh();
        }

        [MenuItem("Assets/Nemo/图片/6张图转CUBE")]
        public static void ToCube()
        {
            var selectObjs = Selection.objects;
            if (selectObjs.Length != 6)
            {
                Debug.Log("选6张图");
                return;
            }

            Texture2D[] sortedTexture2Ds = new Texture2D[6];
            bool isHDR = false;
            foreach (var selectObj in selectObjs)
            {
                var path = AssetDatabase.GetAssetPath(selectObj);
                var fileName = Path.GetFileNameWithoutExtension(path);
                if (fileName.EndsWith("x+"))
                {
                    if (fileName.Contains("hdr"))
                    {
                        isHDR = true;
                    }

                    sortedTexture2Ds[0] = selectObj as Texture2D;
                }

                if (fileName.EndsWith("x-"))
                {
                    sortedTexture2Ds[1] = selectObj as Texture2D;
                }

                if (fileName.EndsWith("y+"))
                {
                    sortedTexture2Ds[2] = selectObj as Texture2D;
                }

                if (fileName.EndsWith("y-"))
                {
                    sortedTexture2Ds[3] = selectObj as Texture2D;
                }

                if (fileName.EndsWith("z+"))
                {
                    sortedTexture2Ds[4] = selectObj as Texture2D;
                }

                if (fileName.EndsWith("z-"))
                {
                    sortedTexture2Ds[5] = selectObj as Texture2D;
                }
            }

            var everyTexW = sortedTexture2Ds[0].width;
            var everyTexH = sortedTexture2Ds[0].height;
            var newW = everyTexW * 6;
            var newH = everyTexH;
            Texture2D newTex;
            newTex = isHDR ? new Texture2D(newW, newH, TextureFormat.RGBAFloat, true) : new Texture2D(newW, newH, TextureFormat.RGB24, true);
            int i = 0;
            foreach (var texture in sortedTexture2Ds)
            {
                var colors = texture.GetPixels();
                // if (i < 2 || i > 3)
                {
                    var colorsCount = colors.Length;
                    for (int j = 0; j < (int)(colorsCount / 2); j++)
                    {
                        int x = j % everyTexW;
                        int y = (int)(j / everyTexW);
                        var j2 = (everyTexH - 1 - y) * everyTexW + x;
                        (colors[j], colors[j2]) = (colors[j2], colors[j]);
                    }
                }

                newTex.SetPixels(i * everyTexW, 0, everyTexW, everyTexH, colors);
                i++;
            }

            newTex.Apply();
            var bytes = isHDR ? newTex.EncodeToEXR(Texture2D.EXRFlags.CompressZIP) : newTex.EncodeToTGA();

            var outPath = Path.GetDirectoryName(AssetDatabase.GetAssetPath(sortedTexture2Ds[0])) + (isHDR ? "/cube.exr" : "/cube.tga");
            File.WriteAllBytes(outPath, bytes);
            AssetDatabase.Refresh();
        }

        [MenuItem("Assets/Nemo/图片/线性转Gamma")]
        public static void LinearToGammaTex()
        {
            var rawTexture = Selection.activeObject as Texture2D;
            if (!rawTexture)
            {
                return;
            }

            var selectionPath = AssetDatabase.GetAssetPath(Selection.activeObject);
            TextureImporter importer = AssetImporter.GetAtPath(selectionPath) as TextureImporter;
            if (!importer)
            {
                Debug.LogError("没有选中图片");
                return;
            }

            var rawReadable = importer.isReadable;
            importer.isReadable = true;
            var haveAlpha = importer.DoesSourceTextureHaveAlpha();
            importer.SaveAndReimport();
            var fileName = Path.GetFileNameWithoutExtension(selectionPath);
            var newFileName = fileName + "_gamma";
            var newFilePath = Path.GetDirectoryName(selectionPath) + "/" + newFileName + ".tga";

            var colors = rawTexture.GetPixels();
            var bytesCount = colors.Length;
            for (var i = 0; i < bytesCount; i++)
            {
                colors[i] = colors[i].gamma;
            }

            var texW = rawTexture.width;
            var texH = rawTexture.height;
            var texFormat = haveAlpha ? TextureFormat.RGBA32 : TextureFormat.RGB24;
            var newTex = new Texture2D(texW, texH, texFormat, true);
            newTex.SetPixels(colors);
            newTex.Apply();
            var bytes = newTex.EncodeToTGA();
            File.WriteAllBytes(newFilePath, bytes);
            AssetDatabase.Refresh();
            var importer1 = AssetImporter.GetAtPath(selectionPath) as TextureImporter;
            importer1.isReadable = rawReadable;
            importer1.SaveAndReimport();
            var importer2 = AssetImporter.GetAtPath(newFilePath) as TextureImporter;
            EditorUtility.CopySerialized(importer1, importer2);
            importer2.SaveAndReimport();
        }

        [MenuItem("Assets/Nemo/图片/Gamma转线性")]
        public static void GammaToLinearTex()
        {
            var rawTexture = Selection.activeObject as Texture2D;
            if (!rawTexture)
            {
                return;
            }

            var selectionPath = AssetDatabase.GetAssetPath(Selection.activeObject);
            TextureImporter importer = AssetImporter.GetAtPath(selectionPath) as TextureImporter;
            if (!importer)
            {
                Debug.LogError("没有选中图片");
                return;
            }

            var rawReadable = importer.isReadable;
            importer.isReadable = true;
            var haveAlpha = importer.DoesSourceTextureHaveAlpha();
            importer.SaveAndReimport();
            var fileName = Path.GetFileNameWithoutExtension(selectionPath);
            var newFileName = fileName + "_linear";
            var newFilePath = Path.GetDirectoryName(selectionPath) + "/" + newFileName + ".tga";

            var colors = rawTexture.GetPixels();
            var bytesCount = colors.Length;
            for (var i = 0; i < bytesCount; i++)
            {
                colors[i] = colors[i].linear;
            }

            var texW = rawTexture.width;
            var texH = rawTexture.height;
            var texFormat = haveAlpha ? TextureFormat.RGBA32 : TextureFormat.RGB24;
            var newTex = new Texture2D(texW, texH, texFormat, true);
            newTex.SetPixels(colors);
            newTex.Apply();
            var bytes = newTex.EncodeToTGA();
            File.WriteAllBytes(newFilePath, bytes);
            AssetDatabase.Refresh();
            var importer1 = AssetImporter.GetAtPath(selectionPath) as TextureImporter;
            importer1.isReadable = rawReadable;
            importer1.SaveAndReimport();
            var importer2 = AssetImporter.GetAtPath(newFilePath) as TextureImporter;
            EditorUtility.CopySerialized(importer1, importer2);
            importer2.SaveAndReimport();
        }

        [MenuItem("Assets/Nemo/图片/CSV转RAW")]
        public static void CSVToRaw()
        {
            var selectionPath = AssetDatabase.GetAssetPath(Selection.activeObject);

            if (string.IsNullOrEmpty(selectionPath))
                return;

            var extension = Path.GetExtension(selectionPath);

            if (extension != ".csv")
            {
                Debug.LogError("暂不支持此数据格式");
                return;
            }

            if (!File.Exists(selectionPath))
            {
                Debug.LogError("文件不存在");
                return;
            }

            var lines = File.ReadLines(selectionPath).ToArray();
            var columns = lines[0].Replace(" ", "").Split(",");

            var width = columns.Length - 1;
            var height = lines.Length - 1;

            var pixels = new float[width * height];

            for (var i = 1; i <= height; ++i)
            {
                var values = lines[i].Replace(" ", "").Split(",");
                for (var j = 1; j <= width; ++j)
                    pixels[(i - 1) * width + (j - 1)] = float.Parse(values[j]);
            }

            var outPath = selectionPath.Replace(".csv", ".raw");

            using (var fs = File.OpenWrite(outPath))
            using (var writer = new BinaryWriter(fs))
            {
                var bytes = new List<byte>();
                foreach (var v in pixels)
                    bytes.AddRange(BitConverter.GetBytes((short)(v / 300.0 * short.MaxValue)));
                writer.Write(bytes.ToArray());
            }

            AssetDatabase.Refresh();
        }

        [MenuItem("Assets/Nemo/图片/PNG转TGA")]
        public static void PNGToTGA()
        {
            var selections = Selection.objects;

            List<Texture2D> textures = new List<Texture2D>();
            foreach (var selection in selections)
            {
                var selectionPath = AssetDatabase.GetAssetPath(selection);

                if (string.IsNullOrEmpty(selectionPath))
                    return;

                var extension = Path.GetExtension(selectionPath);

                if (extension != ".png")
                {
                    Debug.LogError("暂不支持此数据格式");
                    return;
                }

                if (!File.Exists(selectionPath))
                {
                    Debug.LogError("文件不存在");
                    return;
                }

                var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(selectionPath);
                if (texture == null)
                {
                    Debug.LogError("图片资源实例化失败");
                    return;
                }

                textures.Add(texture);
            }

            SetTexturesReadable(textures);
            foreach (var texture in textures)
            {
                var assetPath = AssetDatabase.GetAssetPath(texture);
                var bytes = texture.EncodeToTGA();
                var outPath = assetPath.Replace(".png", ".tga");
                File.WriteAllBytes(outPath, bytes);
            }
            AssetDatabase.Refresh();
        }

        public static void SetTexturesReadable(List<Texture2D> texture2Ds)
        {
            foreach (var t2d in texture2Ds)
            {
                var path = AssetDatabase.GetAssetPath(t2d);
                var importer = AssetImporter.GetAtPath(path) as TextureImporter;
                var settings = importer.GetDefaultPlatformTextureSettings();
                if (importer != null && (!importer.isReadable ||
                                         importer.textureCompression != TextureImporterCompression.Uncompressed ||
                                         settings.format != TextureImporterFormat.RGBA32))
                {
                    if (!importer.isReadable)
                    {
                        importer.isReadable = true;
                    }

                    if (importer.textureCompression != TextureImporterCompression.Uncompressed)
                    {
                        importer.textureCompression = TextureImporterCompression.Uncompressed;
                    }

                    if (settings.format != TextureImporterFormat.RGBA32)
                    {
                        settings.format = TextureImporterFormat.RGBA32;
                        importer.SetPlatformTextureSettings(settings);
                    }

                    importer.SaveAndReimport();
                }
            }
        }

        public static void SaveRenderTexture(RenderTexture rt, string outPath, ImageType imageType, TextureFormat textureFormat = TextureFormat.RGBA32, bool mipChain = false)
        {
            if (rt == null)
                return;

            var active = RenderTexture.active;
            RenderTexture.active = rt;
            var tex2D = new Texture2D(rt.width, rt.height, textureFormat, false);
            tex2D.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
            tex2D.Apply();
            RenderTexture.active = active;

            byte[] bytes;
            switch (imageType)
            {
                case ImageType.TGA:
                    bytes = tex2D.EncodeToTGA();
                    break;
                case ImageType.PNG:
                    bytes = tex2D.EncodeToPNG();
                    break;
                case ImageType.JPG:
                    bytes = tex2D.EncodeToJPG();
                    break;
                case ImageType.EXR:
                    bytes = tex2D.EncodeToEXR();
                    break;
                default:
                    bytes = null;
                    break;
            }

            if (bytes != null)
                File.WriteAllBytes(outPath, bytes);
        }
    }
}