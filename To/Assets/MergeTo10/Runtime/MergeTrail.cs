using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;

namespace MergeTo10.Runtime
{
    public sealed class MergeTrail : MonoBehaviour
    {
        readonly SpriteRenderer[] parts=new SpriteRenderer[3];
        MaterialPropertyBlock properties;
        SortingGroup sorting;
        Vector2 origin,destination;
        Vector3 initialScale;
        float delay,duration;
        public float Opacity { get; private set; }
        public SpriteRenderer[] Renderers => parts;
        void Awake(){properties=new MaterialPropertyBlock();}

        public void SetOrder(int order)
        {
            if(!sorting)sorting=gameObject.AddComponent<SortingGroup>();
            sorting.sortingOrder=order;
        }

        public void Setup(CellView source,Vector2 end,float wait,float action,Material material)
        {
            origin=source.Position;destination=end;delay=wait;duration=action;
            initialScale=source.transform.localScale*.96f;
            // The frozen source copies its hidden Shadow texture too; preserve that behavior.
            parts[0]=CreatePart("Ghost_Shadow",source.TileRenderer.sprite,Vector2.one*112*.97f,new Vector2(0,6),new Color(.05f,.12f,.20f,.24f),0,material);
            parts[1]=CreatePart("Ghost_Backplate",source.TileRenderer.sprite,Vector2.one*112,Vector2.zero,source.TileRenderer.color,1,material);
            var glyph=source.GlyphRenderer;
            parts[2]=CreatePart("Ghost_Glyph",glyph.sprite,Vector2.Scale(glyph.sprite.rect.size,glyph.transform.localScale),Vector2.zero,glyph.color,2,material);
            Sample(0);
            StartCoroutine(Play());
        }

        SpriteRenderer CreatePart(string name,Sprite sprite,Vector2 size,Vector2 offset,Color color,int order,Material material)
        {
            var go=new GameObject(name);go.transform.SetParent(transform,false);
            go.transform.localPosition=new Vector3(offset.x/100,-offset.y/100,0);
            var renderer=go.AddComponent<SpriteRenderer>();
            renderer.sharedMaterial=material;renderer.sprite=sprite;renderer.color=color;renderer.sortingOrder=order;
            M1Art.SetSize(renderer,size);
            return renderer;
        }

        // Analytic source tween profile, also usable by deterministic visual probes.
        public static Vector3 Profile(float age,float delay,float duration)
        {
            float elapsed=age-delay,travel=Mathf.Max(.12f,duration*1.12f);
            if(elapsed<=0)return new Vector3(0,1,0);
            float t=Mathf.Clamp01(elapsed/travel);
            float scale=Mathf.Lerp(1,.74f,Mathf.Sin(t*Mathf.PI*.5f));
            float opacity=elapsed<=travel
                ?.38f*Mathf.Sin(Mathf.Clamp01(elapsed/Mathf.Min(.06f,travel*.45f))*Mathf.PI*.5f)
                :.38f*Mathf.Cos(Mathf.Clamp01((elapsed-travel)/.18f)*Mathf.PI*.5f);
            return new Vector3(1-(1-t)*(1-t),scale,Mathf.Max(0,opacity));
        }

        public void Sample(float age)
        {
            var profile=Profile(age,delay,duration);
            var position=Vector2.Lerp(origin,destination,profile.x)+Vector2.one*58;
            transform.localPosition=new Vector3(position.x/100,-position.y/100,0);
            transform.localScale=initialScale*profile.y;
            Opacity=profile.z;
            properties.SetFloat("_Fade",Opacity);
            foreach(var renderer in parts)if(renderer)renderer.SetPropertyBlock(properties);
        }

        IEnumerator Play()
        {
            float age=0,total=delay+Mathf.Max(.12f,duration*1.12f)+.18f;
            while(age<total){yield return null;age+=Time.deltaTime;Sample(age);}
            gameObject.SetActive(false);
            Destroy(gameObject);
        }
    }
}
