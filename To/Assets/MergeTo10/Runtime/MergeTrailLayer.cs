using System.Collections.Generic;
using UnityEngine;

namespace MergeTo10.Runtime
{
    public sealed class MergeTrailLayer : MonoBehaviour
    {
        readonly List<MergeTrail> active=new List<MergeTrail>();
        Material material;
        public IReadOnlyList<MergeTrail> Active => active;
        public void Setup()
        {
            material=new Material(Resources.Load<Shader>("M1Art/MergeGhost"));
        }
        public MergeTrail Spawn(CellView source,Vector2 destination,float delay,float duration)
        {
            active.RemoveAll(item=>!item);
            var go=new GameObject("MergeAfterimage_"+source.Cell.Id);
            go.transform.SetParent(transform,false);
            var trail=go.AddComponent<MergeTrail>();
            active.Add(trail);
            for(int i=0;i<active.Count;i++)active[i].SetOrder(-100-i);
            trail.Setup(source,destination,delay,duration,material);
            return trail;
        }
        public void Clear()
        {
            foreach(var trail in active)
                if(trail){trail.gameObject.SetActive(false);Destroy(trail.gameObject);}
            active.Clear();
        }
        void OnDestroy(){Clear();if(material)Destroy(material);}
    }
}

