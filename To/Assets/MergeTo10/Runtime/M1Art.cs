using System;
using System.Collections.Generic;
using UnityEngine;
namespace MergeTo10.Runtime
{
    public sealed class M1Art
    {
        [Serializable] public class Region {public string key,texture;public float x,y,width,height;}
        [Serializable] class Regions {public Region[] regions;}
        readonly Dictionary<string,Sprite> sprites=new Dictionary<string,Sprite>();
        public Material Material{get;private set;}
        public static readonly string[] Colors={"green","blue","yellow","purple","red"};
        public static readonly Color[] Tints={new Color(.72f,.80f,.54f),new Color(.80f,.72f,.81f),new Color(.93f,.96f,.58f),new Color(.60f,.53f,.79f),new Color(.82f,.66f,.78f)};
        public M1Art()
        {
            Material=new Material(Resources.Load<Shader>("M1Art/ParitySprite"));
            var data=JsonUtility.FromJson<Regions>(Resources.Load<TextAsset>("M1Art/regions").text);
            foreach(var r in data.regions)
            {
                var texture=Resources.Load<Texture2D>("M1Art/"+r.texture);
                sprites.Add(r.key,Sprite.Create(texture,new Rect(r.x,texture.height-r.y-r.height,r.width,r.height),new Vector2(.5f,.5f),100,0,SpriteMeshType.FullRect));
            }
            foreach(string name in new[]{"background","board_plate"})
            {
                var texture=Resources.Load<Texture2D>("M1Art/"+name);
                sprites.Add(name,Sprite.Create(texture,new Rect(0,0,texture.width,texture.height),new Vector2(.5f,.5f),100,0,SpriteMeshType.FullRect));
            }
        }
        public Sprite Get(string key)=>sprites[key];
        public SpriteRenderer Create(string name,Transform parent,string key,int order,Vector2 size)
        {
            var existing=WorldPrefabFactory.Child(parent,name);var go=existing?existing.gameObject:new GameObject(name);if(!existing)go.transform.SetParent(parent,false);
            var r=go.EnsureComponent<SpriteRenderer>();r.sharedMaterial=Material;r.sprite=Get(key);r.sortingOrder=order;
            if(!existing)SetSize(r,size);return r;
        }
        public static void SetSize(SpriteRenderer r,Vector2 pixels)
        {
            r.transform.localScale=new Vector3(pixels.x/r.sprite.rect.width,pixels.y/r.sprite.rect.height,1);
        }
        public void Dispose()
        {
            foreach(var sprite in sprites.Values)UnityEngine.Object.Destroy(sprite);
            UnityEngine.Object.Destroy(Material);
        }
    }
}
