using System.Collections;
using MergeTo10.Core;
using UnityEngine;
using UnityEngine.Rendering;
namespace MergeTo10.Runtime
{
    public sealed class CellView:MonoBehaviour
    {
        public Cell Cell{get;private set;}
        public Vector2 Position{get;private set;}
        M1Art art;SpriteRenderer tile,glyph,highlight;SortingGroup group;
        Coroutine motion,glow,pop;float popScale=1,alpha=1;
        public bool HighlightVisible=>highlight!=null&&highlight.enabled;
        public SpriteRenderer HighlightRenderer=>highlight;
        public SpriteRenderer TileRenderer=>tile;
        public SpriteRenderer GlyphRenderer=>glyph;
        public float Opacity=>alpha;
        public void Setup(Cell cell,M1Art assets,int order)
        {
            Cell=cell;art=assets;group=gameObject.EnsureComponent<SortingGroup>();group.sortingOrder=order;
            tile=art.Create("Backplate",transform,"tile_"+M1Art.Colors[(cell.Level-1)%5],0,new Vector2(112,112));
            highlight=art.Create("ChainHighlight",transform,"tile_"+M1Art.Colors[(cell.Level-1)%5],1,new Vector2(112,112));
            highlight.enabled=false;
            glyph=art.Create("Glyph",transform,"glyph_"+cell.Level,2,Vector2.one);
            Refresh();SetPosition(LayoutMapper.CellTopLeft(cell.X,cell.Y));
        }
        public void SetPosition(Vector2 position)
        {
            Position=position;
            transform.localPosition=new Vector3((position.x+58)/100,-(position.y+58)/100,0);
        }
        public void Refresh()
        {
            int index=(Cell.Level-1)%5;tile.sprite=art.Get("tile_"+M1Art.Colors[index]);
            highlight.sprite=tile.sprite;M1Art.SetSize(tile,new Vector2(112,112));
            glyph.sprite=art.Get("glyph_"+Cell.Level);
            var sz=glyph.sprite.rect.size;M1Art.SetSize(glyph,sz*(112*.62f/Mathf.Max(sz.x,sz.y)));
            SetAlpha(alpha);
        }
        void SetAlpha(float a)
        {
            alpha=a;var tint=M1Art.Tints[(Cell.Level-1)%5];tint.a=a;tile.color=tint;glyph.color=new Color(1,1,1,a);
        }
        void SetPop(float scale){popScale=scale;transform.localScale=Vector3.one*scale;}
        static float QuadOut(float t)=>1-(1-t)*(1-t);
        static float QuadInOut(float t)=>t<.5f?2*t*t:1-Mathf.Pow(-2*t+2,2)/2;
        static float BackOut(float t){float a=t-1;return 1+2.70158f*a*a*a+1.70158f*a*a;}
        IEnumerator Animate(float seconds,System.Action<float> apply)
        {
            float t=0;apply(0);
            while(t<seconds){yield return null;t+=Time.deltaTime;apply(Mathf.Clamp01(t/seconds));}
        }
        public void MoveTo(Vector2 target,float seconds,bool cubic=false)
        {
            if(motion!=null)StopCoroutine(motion);var start=Position;
            motion=StartCoroutine(Animate(seconds,t=>SetPosition(Vector2.LerpUnclamped(start,target,cubic?1-Mathf.Pow(1-t,3):QuadOut(t)))));
        }
        public IEnumerator Absorb(Vector2 target,float delay,float duration,int order)
        {
            if(motion!=null){StopCoroutine(motion);motion=null;SetPosition(LayoutMapper.CellTopLeft(Cell.X,Cell.Y));}
            if(pop!=null){StopCoroutine(pop);pop=null;}
            SetPop(1);
            group.sortingOrder=order;
            if(delay>0)yield return new WaitForSeconds(delay);
            var start=Position;
            yield return Animate(duration,t=>{SetPosition(Vector2.Lerp(start,target,QuadInOut(t)));SetPop(Mathf.Lerp(1,.86f,t));});
            yield return Animate(.06f,t=>SetAlpha(1-t));
            gameObject.SetActive(false);
        }
        public void InvalidShake()
        {
            if(motion!=null)StopCoroutine(motion);
            motion=StartCoroutine(Shake());
        }
        IEnumerator Shake()
        {
            var origin=LayoutMapper.CellTopLeft(Cell.X,Cell.Y);SetPosition(origin);
            foreach(float x in new[]{8f,-8f,0f})
            {var start=Position;yield return Animate(.04f,t=>SetPosition(Vector2.Lerp(start,origin+new Vector2(x,0),t)));}
            motion=null;
        }
        public void ResultPop()
        {
            if(pop!=null)StopCoroutine(pop);
            pop=StartCoroutine(Pop());
        }
        IEnumerator Pop()
        {
            SetPop(.9f);
            StartCoroutine(Animate(.12f,t=>glyph.color=new Color(1,1,1,QuadOut(t))));
            yield return Animate(.09f,t=>SetPop(Mathf.LerpUnclamped(.9f,1.14f,BackOut(t))));
            yield return Animate(.11f,t=>SetPop(Mathf.Lerp(1.14f,1,QuadOut(t))));
            SetPop(1);pop=null;
        }
        public void BeginHighlight(float duration)
        {
            if(glow!=null)StopCoroutine(glow);
            highlight.enabled=true;
            glow=StartCoroutine(Animate(Mathf.Max(.16f,duration),t=>{
                float s=(1-Mathf.Cos(Mathf.PI*t))*.5f;
                highlight.color=Color.Lerp(new Color(1,.92f,.24f,.22f),new Color(1,.94f,.34f,.9f),s);
                M1Art.SetSize(highlight,Vector2.one*112*Mathf.Lerp(.96f,1.05f,s));
            }));
        }
        public void CompleteHighlight()
        {
            if(glow!=null)StopCoroutine(glow);
            glow=StartCoroutine(FinishGlow());
        }
        IEnumerator FinishGlow()
        {
            yield return Animate(.08f,t=>{
                highlight.color=Color.Lerp(new Color(1,.94f,.34f,.9f),new Color(1,1,.76f,1),t);
                M1Art.SetSize(highlight,Vector2.one*112*Mathf.LerpUnclamped(1.05f,1.10f,BackOut(t)));
            });
            yield return Animate(.20f,t=>{
                highlight.color=Color.Lerp(new Color(1,1,.76f,1),new Color(1,1,1,0),Mathf.Sin(t*Mathf.PI*.5f));
                M1Art.SetSize(highlight,Vector2.one*112*Mathf.Lerp(1.1f,1,QuadOut(t)));
            });
            highlight.enabled=false;glow=null;
        }
    }
}
