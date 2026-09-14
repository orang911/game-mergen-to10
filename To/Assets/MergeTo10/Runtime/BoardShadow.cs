using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace MergeTo10.Runtime
{
    // One union of all 25 silhouettes: overlapping shadows never accumulate darkness.
    public sealed class BoardShadow : MonoBehaviour
    {
        readonly Vector4[] blocks=new Vector4[25];
        readonly Vector4[] opacities=new Vector4[25];
        Func<IEnumerable<CellView>> source;
        Mesh mesh;
        Material material;
        public MeshRenderer Renderer { get; private set; }
        public int BlockCount { get; private set; }

        public void Setup(Func<IEnumerable<CellView>> cells)
        {
            source=cells;
            mesh=new Mesh { name="BoardShadow633" };
            mesh.vertices=new[]{Vector3.zero,new Vector3(6.33f,0,0),new Vector3(6.33f,-6.33f,0),new Vector3(0,-6.33f,0)};
            mesh.uv=new[]{Vector2.zero,Vector2.right,Vector2.one,Vector2.up};
            mesh.triangles=new[]{0,1,2,0,2,3};
            mesh.RecalculateBounds();
            gameObject.AddComponent<MeshFilter>().sharedMesh=mesh;
            material=new Material(Resources.Load<Shader>("M1Art/BoardShadow"));
            Renderer=gameObject.AddComponent<MeshRenderer>();
            Renderer.sharedMaterial=material;
            Renderer.sortingOrder=-800;
            Renderer.shadowCastingMode=ShadowCastingMode.Off;
            Renderer.receiveShadows=false;
            RenderPipelineManager.beginCameraRendering+=BeforeRender;
            Synchronize();
        }

        void BeforeRender(ScriptableRenderContext context,Camera camera) => Synchronize();
        void LateUpdate() => Synchronize();

        public void Synchronize()
        {
            if(material==null||source==null)return;
            int count=0;
            foreach(var cell in source())
            {
                if(count>=25)break;
                if(!cell||!cell.gameObject.activeInHierarchy||cell.Opacity<=.001f)continue;
                var center=cell.Position+Vector2.one*58;
                var scale=cell.transform.localScale;
                blocks[count]=new Vector4(center.x,center.y,56*Mathf.Abs(scale.x),56*Mathf.Abs(scale.y));
                opacities[count]=new Vector4(cell.Opacity,0,0,0);
                count++;
            }
            BlockCount=count;
            material.SetInt("_BlockCount",count);
            material.SetVectorArray("_Blocks",blocks);
            material.SetVectorArray("_Opacities",opacities);
        }

        void OnDestroy()
        {
            RenderPipelineManager.beginCameraRendering-=BeforeRender;
            if(mesh)Destroy(mesh);
            if(material)Destroy(material);
        }
    }
}

