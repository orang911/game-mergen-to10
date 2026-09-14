using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class CrystalUpgradeView:MonoBehaviour {
  GameUiSurface ui;
  public bool Visible=>ui!=null;
  public void Show(){
   if(Visible)return;
   var combat=GetComponent<M2BattleDemo>();
   if(!combat.NavigationSuspended)return;
   ui=new GameUiSurface("CrystalUpgradeCanvas",1100,1);
   Art("crystal_background",0,0,941,1672);
   Art("crystal_upgrade_back_button_default_v03",29,31,115,109);
   var hit=GameUiSurface.Rect(ui.Root,"Back",23,25,127,121).gameObject.EnsureComponent<Image>();hit.color=Color.clear;
   hit.gameObject.EnsureComponent<Button>().onClick.AddListener(Hide);
   Counter(205,53,combat.Meta.State.Crystals,"currency_diamond",203,40,82,89);
   Counter(454,53,combat.Meta.State.Coins,"currency_coin",450,39,86,87);
   Art("crystal_upgrade_current_section_v03",16, 146, 908, 581);
   Label("当前水晶",46,"ffffff",250, 152, 440, 62);
   Art("crystal_upgrade_tower_lv03_v02",105, 272, 318, 374);
   Art("crystal_upgrade_current_info_panel_v03",460, 252, 432, 445);
   Label("Lv.03",32,"b7f8ff",476, 268, 160, 58);
   Detail(344,"crystal_upgrade_stat_attack_v02","攻击","120");
   Detail(414,"crystal_upgrade_stat_cooldown_v02","冷却","2.4秒");
   Detail(484,"crystal_upgrade_stat_range_v02","范围","3格");
   Label("已开启功能",26,"ffffff",500, 564, 350, 46);
   Label("基础攻击强化",24,"17345d",500, 615, 350, 52);
   Art("crystal_upgrade_materials_section_v03",16, 736, 908, 382);
   Label("升级所需素材",44,"ffffff",240, 745, 460, 76);
   Art("crystal_upgrade_material_cards_v03",48, 826, 844, 193);
   Art("crystal_upgrade_material_fragment_v02",67, 836, 170, 165);
   Label("水晶碎片",34,"17345d",237, 832, 205, 57);
   Label("18/30",30,"d63b20",239, 919, 187, 62);
   Art("currency_coin",505, 839, 145, 140);
   Label("金币",34,"17345d",667, 832, 205, 57);
   Label("3766/5000",30,"d63b20",660, 919, 196, 62);
   Art("crystal_upgrade_warning_bar_v03",46, 1034, 849, 68);
   Art("crystal_upgrade_warning_v02",169, 1045, 46, 47);
   Label("缺少：水晶碎片 ×12、金币 ×1234",23,"cc4a34",229, 1038, 620, 58);
   Art("crystal_upgrade_preview_section_v03",16, 1129, 908, 363);
   Label("升级预览",44,"ffffff",260, 1137, 420, 76);
   Art("crystal_upgrade_preview_stats_v03",199, 1215, 533, 262);
   Art("crystal_upgrade_tower_lv03_v02",46, 1267, 136, 174);
   Art("crystal_upgrade_tower_lv04_v02",760, 1256, 136, 178);
   Label("当前 Lv.03",22,"17345d",203, 1218, 239, 49);
   Label("升级后 Lv.04",22,"087eaa",475, 1218, 239, 49);
   Preview(1278,"攻击","120","160");
   Preview(1347,"冷却","2.4秒","2.0秒");
   Preview(1416,"范围","3格","4格");
   Art("crystal_upgrade_disabled_button_v02",145, 1515, 650, 132);
   Label("材料不足",44,"e7f1ff",145, 1518, 650, 115);ui.Complete();
  }
  void Art(string key,float x,float y,float w,float h){ui.Art(ui.Root,key,x,y,w,h);}
  void Label(string value,int size,string hex,float x,float y,float w,float h){
   ColorUtility.TryParseHtmlString("#"+hex,out var color);
   var text=ui.Label(ui.Root,value,size,color,x,y,w,h);
   if(hex=="ffffff"||hex=="b7f8ff"||hex=="e7f1ff"){var outline=text.gameObject.EnsureComponent<Outline>();outline.effectColor=new Color(.03f,.08f,.18f,.86f);outline.effectDistance=new Vector2(2,2);}
  }
  void Counter(float x,float y,int value,string icon,float ix,float iy,float iw,float ih){
   Art("crystal_counter",x,y,241,61);Art(icon,ix,iy,iw,ih);
   Label(value>=100000?Mathf.RoundToInt(value/1000f)+"K":Mathf.Max(0,value).ToString(),31,"ffffff",x+68,y+2,129,57);
   Art("crystal_plus",x+183,y+2,57,57);
  }
  void Detail(float y,string icon,string name,string value){
   Art(icon,493,y+8,44,46);Label(name,29,"17345d",548,y,130,64);Label(value,29,"17345d",696,y,171,64);
  }
  void Preview(float y,string name,string current,string next){
   string icon=name=="攻击"?"attack":name=="冷却"?"cooldown":"range";
   Art("crystal_upgrade_stat_"+icon+"_v02",217,y+5,37,37);
   Label(name,23,"17345d",263,y,82,46);Label(current,24,"17345d",350,y,86,46);
   Art("crystal_upgrade_stat_arrow_v02",477,y+6,42,34);Label(next,25,"087eaa",594,y,109,46);
  }
  public void Hide(){ui?.Dispose();ui=null;}
  void OnDisable(){Hide();}
  void OnDestroy(){Hide();}
 }
}
