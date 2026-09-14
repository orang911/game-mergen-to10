using UnityEditor;
using UnityEngine;
namespace MergeTo10.Editor
{
    public class M1TextureImporter:AssetPostprocessor
    {
        void OnPreprocessTexture()
        {
            if(!assetPath.StartsWith("Assets/MergeTo10/Resources/M1Art/")&&!assetPath.StartsWith("Assets/MergeTo10/Resources/M2Art/")&&!assetPath.StartsWith("Assets/MergeTo10/Resources/Campaign/"))return;
            var importer=(TextureImporter)assetImporter;
            importer.textureType=TextureImporterType.Default;
            importer.mipmapEnabled=false;importer.sRGBTexture=true;
            importer.npotScale=TextureImporterNPOTScale.None;
            importer.textureCompression=TextureImporterCompression.Uncompressed;
            importer.maxTextureSize=4096;importer.filterMode=FilterMode.Bilinear;importer.wrapMode=TextureWrapMode.Clamp;
        }
    }
}
