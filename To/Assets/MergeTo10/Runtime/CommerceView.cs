using System;
using System.Collections;
using MergeTo10.Core;
using UnityEngine;
using UnityEngine.UI;

namespace MergeTo10.Runtime {
 // Frozen secondary_ui_controller: benefits/piggy/purchase_confirm. Local simulation only.
 [RequireComponent(typeof(M2BattleDemo))]
 public sealed class CommerceView : MonoBehaviour {
  public bool LocalSimulationEnabled = true;
  GameUiSurface ui;
  M2BattleDemo combat;
  RectTransform panel, content;
  bool purchased, dirty, submitting;
  string returnPage = "", pendingProduct = "";
  Text notice;
  float noticeAge;
  public string PageId { get; private set; } = "";
  public string LastPurchaseResult { get; private set; } = "";
  public bool Visible => ui != null;
  public bool PurchasedState => purchased;
  const float BenefitScale = 714f / 454f;
  static Color Hex(string hex) { ColorUtility.TryParseHtmlString("#" + hex, out var c); return c; }

  public void ShowBenefits() { Open("benefits"); }
  public void ShowPiggy() { purchased = false; Open("piggy"); }
  void Open(string page) {
   var owner = GetComponent<M2BattleDemo>();
   if (!owner || !owner.Ready || !owner.NavigationSuspended) return;
   if (combat != owner) { if (combat) combat.Meta.Changed -= OnMetaChanged; combat = owner; }
   combat.Meta.Changed -= OnMetaChanged;
   combat.Meta.Changed += OnMetaChanged;
   pendingProduct = returnPage = "";
   LastPurchaseResult = "";
   Draw(page, true);
  }
  void OnMetaChanged() { dirty = true; }
  void LateUpdate() {
   if (Visible && dirty && !submitting) Draw(PageId, false);
   if (notice) { noticeAge += Time.unscaledDeltaTime; if (noticeAge >= 1) { Destroy(notice.gameObject); notice = null; } else if (noticeAge > .8f) { var c = notice.color; c.a = .94f * (1 - (noticeAge - .8f) / .2f); notice.color = c; } }
  }
  void Draw(string page, bool animate) {
   StopAllCoroutines(); ui?.Dispose(); ui = null; notice = null; dirty = false; PageId = page;
   ui = new GameUiSurface("CommerceCanvas", 1300, .45f, "Commerce_"+page+(page=="purchase_confirm"?"_"+pendingProduct:""));
   var shadeTexture=Resources.Load<Texture2D>("Campaign/commerce_shade_v01");
   ui.Shade.sprite=Sprite.Create(shadeTexture,new Rect(0,0,4,4),Vector2.one*.5f);
   ui.Shade.gameObject.EnsureComponent<CommerceOwnedSprite>().Value=ui.Shade.sprite;
   ui.Shade.color=Color.white;
   ui.Shade.gameObject.EnsureComponent<Button>().onClick.AddListener(Hide);
   var shadeArt=ui.Art(ui.Root,"commerce_shade_v01",0,0,941,1672);shadeArt.name="CommerceVisibleShade";
   panel = GameUiSurface.Rect(ui.Root, "CommercePanel", 121, page == "benefits" ? 501 : 479, 700, 714);
   GameUiSurface.CenterPivot(panel);
   var shell = ui.Art(panel, "piggy_bank_panel_v01", 0, 0, 700, 714, 28);
   shell.name = "CommerceShell"; shell.raycastTarget = true;
   // The shell blocks taps inside the panel; only the outside veil closes it.
   float width = page == "benefits" ? 700 : page == "piggy" ? 539 : 518;
   float height = page == "benefits" ? 714 : page == "piggy" ? 583 : 552;
   float scale = Mathf.Min(700 / width, 714 / height);
   content = GameUiSurface.Rect(panel, "Content", (700 - width * scale) / 2, (714 - height * scale) / 2, width, height);
   content.localScale = Vector3.one * scale;
   if (page == "benefits") BuildBenefits(); else if (page == "piggy") BuildPiggy(); else BuildConfirmation();
   ui.Complete();if (animate) StartCoroutine(Enter());
  }
  IEnumerator Enter() {
   var group = panel.gameObject.EnsureComponent<CanvasGroup>();
   for (float time = 0; time < .2f; time += Time.unscaledDeltaTime) {
    float t = Mathf.Clamp01(time / .2f) - 1;
    float back = 1 + 2.70158f * t * t * t + 1.70158f * t * t;
    panel.localScale = Vector3.one * Mathf.LerpUnclamped(.92f, 1, back);
    group.alpha = Mathf.Clamp01(time / .14f); yield return null;
   }
   panel.localScale = Vector3.one; group.alpha = 1;
  }
  Rect B(float x, float y, float w, float h) => new Rect(Mathf.Round(x * BenefitScale), Mathf.Round(y * BenefitScale), Mathf.Round(w * BenefitScale), Mathf.Round(h * BenefitScale));
  Image Art(string key, Rect r, string name = null, bool aspect = false) {
   var art = ui.Art(content, key, r.x, r.y, r.width, r.height); art.preserveAspect = aspect; if (name != null) art.name = name; return art;
  }
  Text Copy(string name, string value, Rect r, int font, string color = "17345d", int weight = 700, float outline = 0, string outlineColor = "17345d") {
   var text = ui.Label(content, value, font, Hex(color), r.x, r.y, r.width, r.height, weight); text.name = name;
   if (outline > 0) { var effect = text.gameObject.EnsureComponent<CommerceTextOutline>(); effect.effectColor = Hex(outlineColor); effect.effectDistance = new Vector2(2, 2); }
   return text;
  }
  Text BenefitCopy(string name, string value, Rect r, int font, string color = "17345d", int weight = 700, int outline = 0, string outlineColor = "17345d") => Copy(name, value, B(r.x,r.y,r.width,r.height), Mathf.RoundToInt(font*BenefitScale), color, weight, Mathf.Round(outline*BenefitScale), outlineColor);
  Button ActionButton(string name, string key, string copy, Rect r, int font, Action action, bool enabled = true, float press = .97f, int outline = 3, string outlineColor = "17345d") {
   var image = Art(key, r, name); image.raycastTarget = true;
   var button = image.gameObject.EnsureComponent<Button>(); button.targetGraphic = image; button.transition = Selectable.Transition.None; button.interactable = enabled;
   button.onClick.AddListener(() => { if (button.interactable) action(); });
   var text = ui.Label(image.transform, copy, font, Color.white, 0, 0, r.width, r.height, 900);
   var edge = text.gameObject.EnsureComponent<CommerceTextOutline>(); edge.effectColor = Hex(outlineColor); edge.effectDistance = new Vector2(2, 2);
   if (!enabled) { image.color = new Color(.72f,.76f,.82f,.92f); text.color = image.color; }
   GameUiSurface.CenterPivot(image.rectTransform);
   var feedback = image.gameObject.EnsureComponent<CommerceButtonFeedback>(); feedback.PressScale = press;
   return button;
  }
  void BuildBenefits() {
   Art("benefits_offer_card_v01", B(225,82,200,298), "BenefitCard_remove_ads");
   Art("benefits_offer_card_v01", B(20,82,200,298), "BenefitCard_double_coin");
   Art("benefits_title_ribbon_v01", B(-5,0,342,75), "BenefitTitleRibbon");
   Art("benefits_icon_shield_star_v01", B(24,14,72,58), "BenefitShieldIcon", true);
   Art("benefits_icon_coin_stack_v01", B(50,98,132,102), "BenefitCoinIcon", true);
   Art("benefits_icon_no_ad_base_v01", B(251,98,124,104), "BenefitNoAdIcon", true);
   BenefitCopy("BenefitTitle","权益",new Rect(80,16,122,48),34,"ffffff",900,2);
   BenefitCopy("BenefitDoubleMarker","x2",new Rect(140,165,55,37),34,"66bc16",900,2,"17320a");
   BenefitCopy("BenefitAdMarker","AD",new Rect(259,118,108,64),44,"f7f8f6",900,3,"16191e");
   BenefitCopy("BenefitName_double_coin","双倍金币",new Rect(27,210.5f,180,38),26,"17345d",900,2,"f7f8f4");
   BenefitCopy("BenefitName_remove_ads","去广告",new Rect(238,210.5f,180,38),26,"17345d",900,2,"f7f8f4");
   BenefitCopy("BenefitCopy_double_coin","挑战结算金币 +100%",new Rect(30,260,174,40),15,"17243a");
   BenefitCopy("BenefitCopy_remove_ads","移除非主动广告\n奖励广告保留",new Rect(241,258,174,58),15,"17243a");
   Art("benefits_button_entitled_v01",B(41,293,158,46),"BenefitPermanentPlate");
   BenefitCopy("BenefitPermanent","永久生效",new Rect(45,297,150,35),17,"17345d",900,1,"e8ffc6");
   bool owned = combat.Meta.State.DoubleCoin && combat.Meta.State.RemoveAds;
   ActionButton("BenefitsPurchaseButton","benefits_button_purchase_v01",owned?"已拥有":"¥6",B(104,359,232,74),Mathf.RoundToInt(34*BenefitScale),()=>RequestPurchase("benefits_bundle"),!owned,.97f,Mathf.RoundToInt(3*BenefitScale),"7a3d08");
  }
  void BuildPiggy() {
   Art("piggy_bank_title_ribbon_v01",new Rect(39,4,460,85),"PiggyBankTitleRibbon");
   Copy("PiggyBankTitle","存钱罐",new Rect(86,13,367,58),38,"ffffff",900,3);
   int selected = purchased ? 3 : combat.Meta.State.Piggy <= 0 ? 0 : combat.Meta.State.Piggy < 1000 ? 1 : 2;
   string[] names = {"未积累","积累中","已满","已购买"}, icons = {"empty","progress","full","purchased"};
   for (int i=0;i<4;i++) {
    var r = new Rect(26+i*121,124,115,143);
    if (selected==i) {
     Art("commerce_piggy_selection_v01",new Rect(r.x-8,r.y-8,r.width+16,r.height+16),"PiggyBankSelectedFrame_"+(i+1));
    }
    var card=Art("piggy_bank_stage_card_default_v01",r,"PiggyBankStageCard_"+(i+1)); if(i==selected)card.color=Hex("57d4ff");
    Art("piggy_bank_stage_"+icons[i]+"_v01",new Rect(r.x+5,r.y+13,105,88),"PiggyBankStageIcon_"+(i+1),true);
    Copy("PiggyBankStageLabel_"+(i+1),names[i],new Rect(r.x+3,r.y+107,109,27),16,i==selected?"ffffff":"17345d",700,i==selected?2:0);
   }
   Art("piggy_bank_progress_track_v01",new Rect(66,300,407,40),"PiggyBankProgressTrack");
   if(combat.Meta.State.Piggy>0) {
    // Source NinePatch margins L/R=18, T/B=14, minimum visible width=36.
    var fill=ui.Art(content,"piggy_bank_progress_fill_v01",73,302,Mathf.Max(36,394*Mathf.Clamp01(combat.Meta.State.Piggy/1000f)),36);
    fill.name="PiggyBankProgressFill";
    var old=fill.sprite;
    var replacement=Sprite.Create(old.texture,old.rect,Vector2.one*.5f,100,0,SpriteMeshType.FullRect,new Vector4(18,14,18,14));
    fill.sprite=replacement;fill.type=Image.Type.Sliced;
    // Owned by the view alongside the surface's original sprite.
    fill.gameObject.EnsureComponent<CommerceOwnedSprite>().Value=replacement;
   }
   Copy("PiggyBankProgressText",combat.Meta.State.Piggy+"/1000",new Rect(66,299,407,40),20,"ffffff",700,3);
   Art("piggy_bank_info_panel_v01",new Rect(58,365,422,53),"PiggyBankInfoPanel");
   Copy("PiggyBankInfoText","挑战可积累金币",new Rect(72,373,394,36),19);
   ActionButton("PiggyBankPurchaseButton","piggy_bank_purchase_button_default_v01",purchased?"已领取":"¥12",new Rect(99,443,341,101),36,()=>RequestPurchase("piggy_bank"),!purchased,.97f,4);
  }
  public void RequestPurchase(string product) {
   if(submitting || (product=="benefits_bundle" && PageId!="benefits") || (product=="piggy_bank" && PageId!="piggy"))return;
   if(product!="benefits_bundle" && product!="piggy_bank")return;
   if(product=="benefits_bundle" && combat.Meta.State.DoubleCoin && combat.Meta.State.RemoveAds)return;
   if(product=="piggy_bank" && (purchased || combat.Meta.State.Piggy<=0)) { ShowNotice("当前尚未积累"); return; }
   pendingProduct=product; returnPage=PageId; Draw("purchase_confirm",true);
  }
  void BuildConfirmation() {
   if(pendingProduct=="benefits_bundle") {
    Copy("PurchaseTitle","确认购买",new Rect(42,18,434,58),34);
    Art("purchase_divider_horizontal_v01",new Rect(42,78,434,19));
    Art("purchase_divider_vertical_v01",new Rect(257,106,14,240));
    Art("purchase_icon_double_coin_base_v01",new Rect(67,99,158,158),"PurchaseDoubleCoinIcon",true);
    Art("purchase_icon_no_ad_base_v01",new Rect(293,99,158,158),"PurchaseNoAdIcon",true);
    Copy("PurchaseDoubleName","双倍金币",new Rect(32,247,228,38),26);
    Copy("PurchaseAdsName","去广告",new Rect(258,247,228,38),26);
    Copy("PurchaseDoubleCopy","结算金币 +100%",new Rect(28,285,236,32),17);
    Copy("PurchaseAdsCopy","移除非主动广告\n奖励广告保留",new Rect(270,280,220,58),16);
    Art("purchase_status_tag_permanent_v01",new Rect(174,337,170,57));
    Copy("PurchasePermanent","永久生效",new Rect(174,345,170,42),22,"276b1e");
    Copy("PurchasePrice","¥6",new Rect(174,393,170,51),36);
   } else {
    Copy("PurchaseTitle","确认购买",new Rect(42,72,434,72),34);
    Copy("PurchasePrompt","确认购买该商品？",new Rect(45,190,428,58),26);
    Copy("PurchasePrice","¥12",new Rect(45,245,428,58),36);
   }
   float y=pendingProduct=="benefits_bundle"?456:340;
   ActionButton("PurchaseCancelButton","button_blue_default","取消",new Rect(35,y,192,80),26,CancelPurchase,true,.96f);
   ActionButton("PurchaseConfirmButton","button_yellow_default","确认购买",new Rect(291,y,192,80),26,ConfirmPurchase,true,.96f);
  }
  public void CancelPurchase() { if(PageId!="purchase_confirm" || submitting)return; var page=returnPage; pendingProduct=""; returnPage=""; Draw(page,true); }
  public void ConfirmPurchase() {
   if(PageId!="purchase_confirm" || submitting || pendingProduct.Length==0)return;
   submitting=true;
   try {
    // An injected simulator (e.g. failure tests) takes precedence. Never install an SDK or charge money.
    var original=combat.Meta.LocalPurchase;
    if(original==null && LocalSimulationEnabled)combat.Meta.LocalPurchase=id=>id=="benefits_bundle"||id=="piggy_bank";
    string result;
    try { result=combat.Meta.Purchase(pendingProduct); }
    finally { combat.Meta.LocalPurchase=original; }
    LastPurchaseResult=result;
    if(result=="ok") {
     if(pendingProduct=="piggy_bank")purchased=true;
     GetComponent<CampaignPersistence>()?.SaveStable();
     var page=returnPage; pendingProduct=returnPage=""; Draw(page,true); ShowNotice("购买成功");
    } else ShowNotice(result=="owned"?"已经拥有":result=="empty"?"当前尚未积累":result=="payment_failed"?"购买失败":"暂时无法购买");
   } finally { submitting=false; }
  }
  void ShowNotice(string message) {
   if(!Visible)return; if(notice)Destroy(notice.gameObject); noticeAge=0;
   notice=ui.Label(panel,message,29,new Color(.04f,.13f,.28f,.94f),170,599,360,70); notice.name="CommerceNotice";
  }
  public void Hide() {
   if(submitting)return; StopAllCoroutines(); if(combat)combat.Meta.Changed-=OnMetaChanged;
   ui?.Dispose();ui=null;notice=null;PageId=pendingProduct=returnPage="";dirty=false;
  }
  void OnDisable(){Hide();}
  void OnDestroy(){Hide();}
 }
}
