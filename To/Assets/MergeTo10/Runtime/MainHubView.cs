using System;
using System.Collections.Generic;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using MergeTo10.Core;
namespace MergeTo10.Runtime {
 public sealed class MainHubView:MonoBehaviour {
  [Serializable] public sealed class Item {public string name,kind,key,text;public float x,y,w,h;public int font,align,outline;public bool aspect;public float[] color,border;}
  [Serializable] public sealed class Layout {public Item[] items;public int forestFrames;public float forestFps;}
  readonly Dictionary<string,Text> labels=new Dictionary<string,Text>();
  readonly Dictionary<string,Button> buttons=new Dictionary<string,Button>();
  readonly Dictionary<string,Image> images=new Dictionary<string,Image>();
  Sprite coinSprite,diamondSprite;Sprite[] forest;float forestAge,forestWait,forestFps;int forestIndex;
  CanvasGroup intro;float introAge;
  GameObject lockedNotice;
  readonly List<Sprite> sprites=new List<Sprite>();
  GameUiSurface ui;M2BattleDemo combat;
  public Action<string> EntryRequested;
  public Func<string,bool> EntryAvailable;
  public bool Visible=>ui!=null;
  public bool IntroFinished=>Visible&&introAge>=.24f;
  public string CoinText=>labels.TryGetValue("CoinValue",out var label)?label.text:"";
  public void Show(M2BattleDemo owner){
   Hide();combat=owner;ui=new GameUiSurface("MainHubCanvas",1000,1);
   var layout=JsonUtility.FromJson<Layout>(Resources.Load<TextAsset>("Campaign/hub_layout").text);
   intro=ui.Root.gameObject.EnsureComponent<CanvasGroup>();introAge=0;intro.alpha=0;
   forestAge=forestWait=0;forestIndex=0;forestFps=layout.forestFps;forest=new Sprite[layout.forestFrames];
   foreach(var item in layout.items){
    var rect=GameUiSurface.Rect(ui.Root,item.name,item.x,item.y,item.w,item.h);
    Color color=new Color(item.color[0],item.color[1],item.color[2],item.color[3]);
    if(item.kind=="text"){
     var text=rect.gameObject.EnsureComponent<Text>();text.font=Resources.Load<Font>("Campaign/chapter_900");text.fontSize=item.font;text.text=item.text;text.color=color;
     text.alignment=item.align==0?TextAnchor.MiddleLeft:TextAnchor.MiddleCenter;text.raycastTarget=false;text.verticalOverflow=VerticalWrapMode.Overflow;
     if(item.outline>0){var outline=rect.gameObject.EnsureComponent<Outline>();outline.effectColor=new Color(.025f,.045f,.09f);outline.effectDistance=new Vector2(2,2);}
     labels[item.name]=text;
    }else{
     var image=rect.gameObject.EnsureComponent<Image>();image.raycastTarget=item.kind=="button";
     images[item.name]=image;
     if(item.name=="Alert")images[item.y<600?"TaskAlert":"SigninAlert"]=image;
     if(!string.IsNullOrEmpty(item.key)){
      var texture=Resources.Load<Texture2D>("Campaign/"+item.key);
      var border=new Vector4(item.border[0],item.border[1],item.border[2],item.border[3]);
      var sprite=Sprite.Create(texture,new Rect(0,0,texture.width,texture.height),Vector2.one*.5f,100,0,SpriteMeshType.FullRect,border);sprites.Add(sprite);
      image.sprite=sprite;image.color=color;image.preserveAspect=item.aspect;if(border.sqrMagnitude>0)image.type=Image.Type.Sliced;
     }else image.color=Color.clear;
     if(item.kind=="button"){var button=rect.gameObject.EnsureComponent<Button>();button.targetGraphic=image;button.transition=Selectable.Transition.None;string name=item.name;button.interactable=EntryAvailable?.Invoke(name)??false;button.onClick.AddListener(()=>EntryRequested?.Invoke(name));buttons[name]=button;}
    }
   }
   coinSprite=LoadSprite("currency_coin");diamondSprite=LoadSprite("currency_diamond");
   for(int i=0;i<forest.Length;i++)forest[i]=LoadSprite("hub_forest_"+i);
   ui.Complete();Refresh();
  }
  Sprite LoadSprite(string key){var texture=Resources.Load<Texture2D>("Campaign/"+key);var sprite=Sprite.Create(texture,new Rect(0,0,texture.width,texture.height),Vector2.one*.5f,100);sprites.Add(sprite);return sprite;}
  void Update(){
   if(!Visible)return;introAge+=Time.unscaledDeltaTime;intro.alpha=1-Mathf.Pow(1-Mathf.Clamp01(introAge/.24f),2);
   if(forest.Length>1&&forestFps>0&&images.TryGetValue("ForestIsland",out var island)){
    if(forestWait>0){forestWait-=Time.unscaledDeltaTime;if(forestWait<=0){forestAge=0;forestIndex=0;}}
    else{forestAge+=Time.unscaledDeltaTime;forestIndex=Mathf.Min(forest.Length-1,(int)(forestAge*forestFps));if(forestAge>=forest.Length/forestFps)forestWait=UnityEngine.Random.Range(5f,10f);}
    island.sprite=forest[forestIndex];
   }
   Refresh();
  }
  void Refresh(){
   Set("CrystalValue",Format(combat.Meta.State.Crystals));Set("CoinValue",Format(combat.Meta.State.Coins));
   Set("Label","继续游戏");
   int task=0;while(task<4&&combat.Meta.State.TaskClaimed[task])task++;
   string[] titles={"完成 1 次挑战","合成 20 次","击败 30 个怪物","今日登录"};int[] targets={1,20,30,1},rewards={10,30,50,20};
   Set("MissionTitle",task<4?titles[task]:"今日任务已完成");
   Set("MissionProgressText",task<4?combat.Meta.State.TaskProgress[task]+"/"+targets[task]:"4/4");
   if(images.TryGetValue("Fill",out var fill)){float ratio=task<4?Mathf.Clamp01(combat.Meta.State.TaskProgress[task]/(float)targets[task]):1;fill.rectTransform.sizeDelta=new Vector2(390*ratio,44);fill.enabled=ratio>0;fill.transform.SetSiblingIndex(Mathf.Max(0,labels["MissionProgressText"].transform.GetSiblingIndex()));}
   foreach(string name in new[]{"MissionRewardSlot","MissionRewardIcon"})if(images.TryGetValue(name,out var art))art.enabled=task<4;
   if(labels.TryGetValue("MissionRewardCount",out var reward)){reward.enabled=task<4;if(task<4)reward.text=rewards[task].ToString();}
   if(task<4&&images.TryGetValue("MissionRewardIcon",out var icon))icon.sprite=task==0||task==3?diamondSprite:coinSprite;
   bool claimable=combat.Meta.ActivityPoints>=100&&!combat.Meta.State.ActivityClaimed;for(int i=0;i<4;i++)claimable|=combat.Meta.CanClaimTask(i);
   if(images.TryGetValue("TaskAlert",out var taskAlert))taskAlert.enabled=claimable;
   if(images.TryGetValue("SigninAlert",out var signinAlert))signinAlert.enabled=combat.Meta.SignAvailable;
  }
  public void ShowLockedNotice(){
   if(!Visible)return;if(lockedNotice)Destroy(lockedNotice);
   var panel=GameUiSurface.Rect(ui.Root,"LockedNotice",190,785,561,102).gameObject.EnsureComponent<Image>();panel.color=new Color(.025f,.1f,.24f,.94f);panel.raycastTarget=false;
   var border=panel.gameObject.EnsureComponent<Outline>();border.effectDistance=Vector2.one*4;border.effectColor=new Color(.34f,.68f,1,.96f);
   ui.Label(panel.transform,"未解锁，敬请期待",38,Color.white,0,0,561,102,900);
   lockedNotice=panel.gameObject;StartCoroutine(FadeNotice(lockedNotice));
  }
  IEnumerator FadeNotice(GameObject notice){
   var group=notice.EnsureComponent<CanvasGroup>();for(float age=0;notice&&age<1.54f;age+=Time.unscaledDeltaTime){group.alpha=age<.12f?age/.12f:age<1.32f?1:1-(age-1.32f)/.22f;yield return null;}if(notice)Destroy(notice);
  }
  void Set(string name,string value){if(labels.TryGetValue(name,out var text))text.text=value;}
  static string Format(int value)=>value>=100000?Mathf.RoundToInt(value/1000f)+"K":Mathf.Max(0,value).ToString();
  public void Hide(){StopAllCoroutines();ui?.Dispose();ui=null;lockedNotice=null;foreach(var sprite in sprites)if(sprite)Destroy(sprite);sprites.Clear();labels.Clear();buttons.Clear();images.Clear();}
  void OnDestroy(){Hide();}
 }
}
