using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using MergeTo10.Runtime;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using Object=UnityEngine.Object;

namespace MergeTo10.Editor {
 public static class PrefabAuthoringTools {
  public const string Root="Assets/MergeTo10/Resources/Prefabs";
  const string Pending="MergeTo10.PrefabBake";
  static string output,error;static int phase;static double started,next;
  static M2BattleDemo combat;static NavigationIntegration navigation;
  static readonly List<string> interfaces=new List<string>();
  static void Log(string message,string stack,LogType type){if((type==LogType.Exception||type==LogType.Error)&&!stack.Contains("UnityEditor.Search.SearchDatabase"))error=message+"\n"+stack;}
  static object Call(object target,string method,params object[] args)=>target.GetType().GetMethod(method,BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic).Invoke(target,args);
  static void Set(object target,string field,object value)=>target.GetType().GetField(field,BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic).SetValue(target,value);
  [MenuItem("Merge To 10/Prefabs/Open Editable Game Scene")]
  public static void OpenEditable(){if(!EditorApplication.isPlaying&&EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())EditorSceneManager.OpenScene("Assets/MergeTo10/Scenes/NavigationIntegration.unity");}
  // Batch-only initial migration. Never rebakes over a designer's existing prefab edits.
  public static void Bake(){
   if(!Application.isBatchMode)throw new InvalidOperationException("Run initial bake in the isolated validation project.");
   output=Environment.GetEnvironmentVariable("PREFAB_OUTPUT");Directory.CreateDirectory(output);
   if(Directory.Exists(Root+"/UI")&&Directory.GetFiles(Root+"/UI","*.prefab").Length>0)throw new InvalidOperationException("Prefabs already exist; initial bake will not overwrite authored assets.");
   Directory.CreateDirectory(Root+"/UI");Directory.CreateDirectory(Root+"/Core");Directory.CreateDirectory(Root+"/Board");Directory.CreateDirectory(Root+"/Combat");Directory.CreateDirectory(Root+"/Shared");AssetDatabase.Refresh();
   EditorSceneManager.OpenScene("Assets/MergeTo10/Scenes/NavigationIntegration.unity");
   var owner=Object.FindFirstObjectByType<M2BattleDemo>();owner.GetComponent<CampaignPersistence>().PathOverride=Path.Combine(output,"fixture_profile.json");
   EditorSceneManager.SaveScene(owner.gameObject.scene,"Assets/MergeTo10/Scenes/PrefabBakeFixture.unity");
   SessionState.SetBool(Pending,true);SessionState.SetString(Pending+"Output",output);SessionState.SetBool(Pending+"Captured",false);
   EditorApplication.isPlaying=true;
  }
  [InitializeOnLoadMethod] static void Resume(){
   if(!SessionState.GetBool(Pending,false))return;
   output=SessionState.GetString(Pending+"Output","");started=EditorApplication.timeSinceStartup;phase=0;next=0;error=null;
   if(SessionState.GetBool(Pending+"Captured",false)){EditorApplication.delayCall+=FinishScenes;return;}
   interfaces.Clear();EditorApplication.update-=Tick;EditorApplication.update+=Tick;Application.logMessageReceived+=Log;
  }
  static void Tick(){try{
   if(error!=null)throw new Exception(error);if(EditorApplication.timeSinceStartup-started>180)throw new Exception("Prefab bake timeout at phase "+phase);
   if(!EditorApplication.isPlaying||EditorApplication.timeSinceStartup<next)return;
   if(!combat){combat=Object.FindFirstObjectByType<M2BattleDemo>();if(!combat)return;navigation=combat.GetComponent<NavigationIntegration>();}
   var owner=combat.gameObject;
   if(phase==0){var loading=owner.GetComponent<LoadingView>();if(!loading||!loading.Visible)return;loading.enabled=false;SaveUi("LoadingCanvas");loading.enabled=true;phase++;return;}
   if(!combat.Ready||!navigation.Ready||owner.GetComponent<LoadingView>().Visible)return;
   switch(phase){
    case 1: SaveUi("MainHubCanvas");SaveUi("BattleHudCanvas");SaveUi("EnergyHudCanvas");SaveWorld();owner.GetComponent<NavigationSettingsView>().Show(null);break;
    case 2: SaveUi("NavigationSettingsCanvas");owner.GetComponent<NavigationSettingsView>().Hide(false);owner.GetComponent<DailyProgressView>().Show();break;
    case 3: SaveUi("DailyProgressCanvas");owner.GetComponent<DailyProgressView>().Hide();owner.GetComponent<CrystalUpgradeView>().Show();break;
    case 4: SaveUi("CrystalUpgradeCanvas");owner.GetComponent<CrystalUpgradeView>().Hide();owner.GetComponent<CommerceView>().ShowBenefits();break;
    case 5: SaveUi("CommerceCanvas","Commerce_benefits");owner.GetComponent<CommerceView>().RequestPurchase("benefits_bundle");break;
    case 6: SaveUi("CommerceCanvas","Commerce_purchase_confirm_benefits_bundle");owner.GetComponent<CommerceView>().CancelPurchase();owner.GetComponent<CommerceView>().ShowPiggy();break;
    case 7: SaveUi("CommerceCanvas","Commerce_piggy");combat.Meta.State.Piggy=100;owner.GetComponent<CommerceView>().RequestPurchase("piggy_bank");break;
    case 8: SaveUi("CommerceCanvas","Commerce_purchase_confirm_piggy_bank");owner.GetComponent<CommerceView>().Hide();navigation.EnterBattle();break;
    case 9: if(owner.GetComponent<M1BoardDemo>().Busy)return;owner.GetComponent<BattlePauseView>().Show();break;
    case 10: SaveUi("BattlePauseCanvas");owner.GetComponent<BattlePauseView>().Resume();owner.GetComponent<ExitConfirmationView>().Show(()=>{},()=>{});break;
    case 11: SaveUi("ExitConfirmationCanvas");owner.GetComponent<ExitConfirmationView>().Cancel();Call(combat,"SetGate",M2BattleDemo.ChapterGate.NodeComplete);break;
    case 12: SaveUi("ChapterNodeCanvas");Call(combat,"SetGate",M2BattleDemo.ChapterGate.CrystalReward);break;
    case 13: SaveUi("CrystalChoiceCanvas");Call(combat,"SetGate",M2BattleDemo.ChapterGate.None);Call(owner.GetComponent<ImprintChoiceView>(),"Show");break;
    case 14:
     SaveUi("ImprintChoiceCanvas");Call(owner.GetComponent<ImprintChoiceView>(),"Hide");
     File.WriteAllLines(Path.Combine(output,"interfaces.txt"),interfaces);AssetDatabase.SaveAssets();
     SessionState.SetBool(Pending+"Captured",true);EditorApplication.update-=Tick;Application.logMessageReceived-=Log;EditorApplication.update+=WaitForEdit;EditorApplication.isPlaying=false;return;
   }
   phase++;next=EditorApplication.timeSinceStartup+.8;
  }catch(Exception ex){Fail(ex);}}
  static void WaitForEdit(){if(EditorApplication.isPlayingOrWillChangePlaymode)return;EditorApplication.update-=WaitForEdit;FinishScenes();}
  public static void FinishCaptured(){output=Environment.GetEnvironmentVariable("PREFAB_OUTPUT");FinishScenes();}
  public static void RepairAndConnect(){
   output=Environment.GetEnvironmentVariable("PREFAB_OUTPUT");
   try{
    var layerContents=PrefabUtility.LoadPrefabContents(Root+"/Core/GameLayer.prefab");
    foreach(Transform child in layerContents.transform){if(child.name=="BoardLayout")child.name="WorldSpaceBoard";if(child.name=="BattleWorld")child.name="M2BattleWorld";PrefabUtility.RecordPrefabInstancePropertyModifications(child.gameObject);}
    if(!PrefabUtility.SaveAsPrefabAsset(layerContents,Root+"/Core/GameLayer.prefab"))throw new Exception("GameLayer save failed");PrefabUtility.UnloadPrefabContents(layerContents);
    string path=Root+"/UI/EnergyHudCanvas.prefab";var contents=PrefabUtility.LoadPrefabContents(path);
    var motes=contents.GetComponentsInChildren<Transform>(true).First(t=>t.name=="EnergyMotes");
    GameObjectUtility.RemoveMonoBehavioursWithMissingScript(motes.gameObject);motes.gameObject.EnsureComponent<EnergyMoteGraphic>();
    if(!PrefabUtility.SaveAsPrefabAsset(contents,path))throw new Exception("Energy HUD prefab save failed");PrefabUtility.UnloadPrefabContents(contents);
    var scene=EditorSceneManager.OpenScene("Assets/MergeTo10/Scenes/NavigationIntegration.unity");var owner=Object.FindFirstObjectByType<M2BattleDemo>().gameObject;
    foreach(var t in owner.GetComponentsInChildren<Transform>(true))if(GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(t.gameObject)>0)throw new Exception("Missing script on "+t.name);
    var hub=owner.GetComponentInChildren<PrefabSceneLibrary>().Interfaces.First(e=>e.Id=="MainHubCanvas").Template;hub.SetActive(true);
    if(PrefabUtility.IsPartOfPrefabInstance(owner))PrefabUtility.ApplyPrefabInstance(owner,InteractionMode.AutomatedAction);
    else if(!PrefabUtility.SaveAsPrefabAssetAndConnect(owner,Root+"/Core/GameCore.prefab",InteractionMode.AutomatedAction))throw new Exception("Core prefab save failed");
    EditorSceneManager.SaveScene(scene);hub.SetActive(false);PrefabUtility.RecordPrefabInstancePropertyModifications(hub);
    EditorSceneManager.SaveScene(scene,"Assets/MergeTo10/Scenes/GameCoreAuthoring.unity",true);hub.SetActive(true);EditorSceneManager.SaveScene(scene);
    AssetDatabase.SaveAssets();File.WriteAllText(Path.Combine(output,"assemble-result.txt"),"PASS "+Directory.GetFiles(Root,"*.prefab",SearchOption.AllDirectories).Length+" prefabs; no missing scripts; main scene connected to GameCore; separate core authoring scene.");EditorApplication.Exit(0);
   }catch(Exception ex){Fail(ex);}
  }
  public static void CreateFixturePrefabs(){
   output=Environment.GetEnvironmentVariable("PREFAB_OUTPUT");Directory.CreateDirectory(output);
   try{
    foreach(string name in new[]{"M1BoardParity","M2BattleParity","M2WaveBattle","ChapterIntegration"}){
     var scene=EditorSceneManager.OpenScene("Assets/MergeTo10/Scenes/"+name+".unity");var owner=Object.FindFirstObjectByType<M1BoardDemo>().gameObject;
     if(PrefabUtility.IsPartOfPrefabInstance(owner))continue;
     var layer=Instance(AssetDatabase.LoadAssetAtPath<GameObject>(Root+"/Core/GameLayer.prefab"),owner.transform);
     Instance(AssetDatabase.LoadAssetAtPath<GameObject>(Root+"/Core/BoardCamera.prefab"),owner.transform);
     if(!owner.GetComponent<M2BattleDemo>()){
      PrefabUtility.UnpackPrefabInstance(layer,PrefabUnpackMode.OutermostRoot,InteractionMode.AutomatedAction);
      var battle=WorldPrefabFactory.Child(layer.transform,"M2BattleWorld");if(battle)Object.DestroyImmediate(battle.gameObject);
     }
     if(!PrefabUtility.SaveAsPrefabAssetAndConnect(owner,Root+"/Core/"+name+".prefab",InteractionMode.AutomatedAction))throw new Exception("Cannot save "+name);
     EditorSceneManager.SaveScene(scene);
    }
    AssetDatabase.SaveAssets();File.WriteAllText(Path.Combine(output,"fixture-prefabs-result.txt"),"PASS all four existing board/battle/chapter fixture scenes now contain connected editable prefabs, preserving existing controller settings.");EditorApplication.Exit(0);
   }catch(Exception ex){Fail(ex);}
  }
  static string Hash(string value){using(var sha=SHA256.Create())return BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(value))).Replace("-","").Substring(0,20).ToLowerInvariant();}
  static Sprite Persist(Sprite source){
   if(!source||AssetDatabase.Contains(source))return source;
   var texture=source.texture;
   if(!AssetDatabase.Contains(texture)){
    string path=Root+"/Shared/texture_"+Hash(texture.name+"_"+texture.width+"_"+texture.height)+".asset";
    var existing=AssetDatabase.LoadAssetAtPath<Texture2D>(path);if(existing)texture=existing;else{texture=Object.Instantiate(texture);AssetDatabase.CreateAsset(texture,path);}
   }
   string id=Hash(AssetDatabase.GetAssetPath(texture)+source.rect+source.border+source.pivot+source.pixelsPerUnit);
   string spritePath=Root+"/Shared/sprite_"+id+".asset";var sprite=AssetDatabase.LoadAssetAtPath<Sprite>(spritePath);
   if(!sprite){sprite=Sprite.Create(texture,source.rect,source.pivot/source.rect.size,source.pixelsPerUnit,0,SpriteMeshType.FullRect,source.border);sprite.name=source.texture.name;AssetDatabase.CreateAsset(sprite,spritePath);}return sprite;
  }
  static Material Persist(Material source){
   if(!source||AssetDatabase.Contains(source))return source;
   string path=Root+"/Shared/material_"+Hash(source.shader.name+EditorJsonUtility.ToJson(source))+".mat";
   var material=AssetDatabase.LoadAssetAtPath<Material>(path);if(!material){material=new Material(source);AssetDatabase.CreateAsset(material,path);}return material;
  }
  static void PersistVisuals(GameObject root){
   foreach(var owner in root.GetComponentsInChildren<CommerceOwnedSprite>(true)){owner.Value=null;owner.OwnMaterial=null;owner.OwnTexture=false;Object.DestroyImmediate(owner);}
   foreach(var graphic in root.GetComponentsInChildren<Graphic>(true)){if(graphic is Image image)image.sprite=Persist(image.sprite);graphic.material=Persist(graphic.material);}
   foreach(var renderer in root.GetComponentsInChildren<SpriteRenderer>(true)){renderer.sprite=Persist(renderer.sprite);renderer.sharedMaterial=Persist(renderer.sharedMaterial);}
   foreach(var script in root.GetComponentsInChildren<MonoBehaviour>(true)){
    if(script&&MonoScript.FromMonoBehaviour(script)?.GetClass()!=script.GetType())Object.DestroyImmediate(script);
   }
  }
  static GameObject Save(GameObject root,string path){PersistVisuals(root);var asset=PrefabUtility.SaveAsPrefabAsset(root,Root+"/"+path+".prefab");Object.DestroyImmediate(root);return asset;}
  static void SaveUi(string canvasName,string id=null){
   id=id??canvasName;
   var source=Object.FindObjectsByType<Canvas>(FindObjectsInactive.Include,FindObjectsSortMode.None).First(c=>c.name==canvasName);
   var clone=Object.Instantiate(source.gameObject);clone.name=canvasName;clone.SetActive(true);
   PersistVisuals(clone);
   var design=clone.transform.Find("DesignRoot");
   var animation=new GameObject("AnimationRoot",typeof(RectTransform)).GetComponent<RectTransform>();animation.SetParent(clone.transform,false);animation.anchorMin=Vector2.zero;animation.anchorMax=Vector2.one;animation.offsetMin=animation.offsetMax=Vector2.zero;
   animation.SetSiblingIndex(design.GetSiblingIndex());design.SetParent(animation,false);
   clone.EnsureComponent<UiPrefabInstance>().AnimationRoot=animation;
   foreach(var node in clone.GetComponentsInChildren<PrefabUiNode>(true))node.RecordBaseline();
   foreach(var group in clone.GetComponentsInChildren<CanvasGroup>(true))group.alpha=1;
   PrefabUtility.SaveAsPrefabAsset(clone,Root+"/UI/"+id+".prefab");Object.DestroyImmediate(clone);interfaces.Add(id);
  }
  static void CopyTransform(Transform from,Transform to){to.localPosition=from.localPosition;to.localRotation=from.localRotation;to.localScale=from.localScale;}
  static GameObject Instance(GameObject asset,Transform parent){return (GameObject)PrefabUtility.InstantiatePrefab(asset,parent);}
  static void SaveWorld(){
   var board=combat.GetComponent<M1BoardDemo>();var stage=board.Stage;
   var cells=stage.GetComponentsInChildren<CellView>();
   var cellClone=Object.Instantiate(cells[0].gameObject);cellClone.name="Cell";cellClone.transform.SetPositionAndRotation(Vector3.zero,Quaternion.identity);cellClone.transform.localScale=Vector3.one;
   var animation=new GameObject("AnimationRoot").transform;animation.SetParent(cellClone.transform,false);
   foreach(var renderer in cellClone.GetComponentsInChildren<SpriteRenderer>())renderer.transform.SetParent(animation,false);
   var cellAsset=Save(cellClone,"Board/Cell");
   var worldBoard=new GameObject("WorldSpaceBoard");CopyTransform(cells[0].transform.parent,worldBoard.transform);
   var preview=new GameObject("EditorPreview");preview.tag="EditorOnly";preview.transform.SetParent(worldBoard.transform,false);
   foreach(var cell in cells){var instance=Instance(cellAsset,preview.transform);instance.name=cell.name;CopyTransform(cell.transform,instance.transform);var a=instance.GetComponentsInChildren<SpriteRenderer>();var b=cell.GetComponentsInChildren<SpriteRenderer>();for(int i=0;i<a.Length;i++){a[i].sprite=Persist(b[i].sprite);a[i].color=b[i].color;CopyTransform(b[i].transform,a[i].transform);}}
   var boardAsset=Save(worldBoard,"Board/BoardLayout");
   var battleSource=WorldPrefabFactory.Child(stage,"M2BattleWorld");var battle=new GameObject("M2BattleWorld");CopyTransform(battleSource,battle.transform);
   foreach(string name in new[]{"Road","Gate"}){var source=WorldPrefabFactory.Child(battleSource,name);var clone=Object.Instantiate(source.gameObject);clone.name=name;CopyTransform(source,clone.transform);var asset=Save(clone,"Combat/"+name);Instance(asset,battle.transform);}
   var crystal=WorldPrefabFactory.Child(battleSource,"Crystal");var crystalClone=Object.Instantiate(crystal.gameObject);crystalClone.name="Crystal";CopyTransform(crystal,crystalClone.transform);var crystalAsset=Save(crystalClone,"Combat/Crystal");
   var crystalPreview=new GameObject("EditorPreview");crystalPreview.tag="EditorOnly";crystalPreview.transform.SetParent(battle.transform,false);Instance(crystalAsset,crystalPreview.transform);
   var battleAsset=Save(battle,"Combat/BattleWorld");
   var layer=new GameObject("GameLayer");CopyTransform(stage,layer.transform);
   foreach(string name in new[]{"Background","BoardBackdrop"}){var source=WorldPrefabFactory.Child(stage,name);var clone=Object.Instantiate(source.gameObject,layer.transform);clone.name=name;CopyTransform(source,clone.transform);}
   Instance(boardAsset,layer.transform).name="WorldSpaceBoard";Instance(battleAsset,layer.transform).name="M2BattleWorld";Save(layer,"Core/GameLayer");
   var camera=Object.FindObjectsByType<Camera>(FindObjectsSortMode.None).First(c=>c.name=="BoardCamera");var cameraClone=Object.Instantiate(camera.gameObject);cameraClone.name="BoardCamera";Save(cameraClone,"Core/BoardCamera");
   var monster=new GameObject("Monster",typeof(SpriteRenderer));var tex=Resources.Load<Texture2D>("M2Art/slime_stage_01_walk_sheet");var mr=monster.GetComponent<SpriteRenderer>();mr.sprite=Sprite.Create(tex,new Rect(4,tex.height-324,320,320),Vector2.one*.5f,100);mr.sortingOrder=-100;mr.sharedMaterial=new Material(Resources.Load<Shader>("M1Art/ParitySprite"));monster.transform.localScale=Vector3.one*.4275f;Save(monster,"Combat/Monster");
   var projectile=new GameObject("Projectile",typeof(SpriteRenderer));var pt=Resources.Load<Texture2D>("M2Art/projectile_crystal");var pr=projectile.GetComponent<SpriteRenderer>();pr.sprite=Sprite.Create(pt,new Rect(0,0,pt.width,pt.height),Vector2.one*.5f,100);pr.sortingOrder=210;pr.sharedMaterial=new Material(Resources.Load<Shader>("M1Art/ParitySprite"));Save(projectile,"Combat/Projectile");
  }
  static void FinishScenes(){try{
   if(EditorApplication.isPlaying){EditorApplication.delayCall+=FinishScenes;return;}
   BakeLoadingPanels();
   var scene=EditorSceneManager.OpenScene("Assets/MergeTo10/Scenes/NavigationIntegration.unity");
   var owner=Object.FindFirstObjectByType<M2BattleDemo>().gameObject;owner.name="GameCore";
   Instance(AssetDatabase.LoadAssetAtPath<GameObject>(Root+"/Core/GameLayer.prefab"),owner.transform);
   Instance(AssetDatabase.LoadAssetAtPath<GameObject>(Root+"/Core/BoardCamera.prefab"),owner.transform);
   var library=new GameObject("InterfacePrefabs").AddComponent<PrefabSceneLibrary>();library.transform.SetParent(owner.transform,false);
   var entries=new List<PrefabSceneLibrary.Entry>();
   foreach(string path in Directory.GetFiles(Root+"/UI","*.prefab").OrderBy(p=>p)){string id=Path.GetFileNameWithoutExtension(path);var asset=AssetDatabase.LoadAssetAtPath<GameObject>(path);var instance=Instance(asset,library.transform);instance.name=id;instance.SetActive(false);entries.Add(new PrefabSceneLibrary.Entry{Id=id,Template=instance});}
   library.Interfaces=entries.ToArray();
   PrefabUtility.SaveAsPrefabAssetAndConnect(owner,Root+"/Core/GameCore.prefab",InteractionMode.AutomatedAction);
   EditorSceneManager.SaveScene(scene);
   // Dedicated battle composition scene for editing without UI covering the board.
   EditorSceneManager.SaveScene(scene,"Assets/MergeTo10/Scenes/GameCoreAuthoring.unity",true);
   AssetDatabase.DeleteAsset("Assets/MergeTo10/Scenes/PrefabBakeFixture.unity");AssetDatabase.SaveAssets();
   int count=Directory.GetFiles(Root,"*.prefab",SearchOption.AllDirectories).Length;
   File.WriteAllText(Path.Combine(output,"bake-result.txt"),"PASS "+count+" prefabs; actual NavigationIntegration uses nested GameCore prefab; all serialized sprites/materials persisted. Runtime regression still required.");
   SessionState.SetBool(Pending,false);EditorApplication.Exit(0);
  }catch(Exception ex){Fail(ex);}}
  static void BakeLoadingPanels(){
   var surface=new GameUiSurface("LoadingPanelBake",2000,0);
   string[] ids={"LoadingClearDialog","LoadingErrorDialog","LoadingRecoveryDialog"};
   string[] titles={"清空本地数据","本地数据暂时不可用","已恢复本地记录"};
   string[] messages={"将清空本机的章节进度、卡片等级、货币与新手记录。是否确认清空？","未能读取本地记录，现有文件已保留。请重试，或确认清空后重新开始。","已从有效的备用记录恢复进度，部分最近操作可能未保存。原文件已保留。"};
   for(int i=0;i<3;i++){
    var overlay=GameUiSurface.Rect(surface.Root,"LoadingDialog",0,0,941,1672);overlay.gameObject.AddComponent<Image>().color=new Color(0,0,0,.6f);
    var panel=GameUiSurface.Rect(overlay,"Panel",160.5f,676,620,320);panel.gameObject.AddComponent<Image>().color=new Color(.1f,.19f,.29f);
    foreach(var label in new[]{surface.Label(panel,titles[i],32,Color.white,20,16,580,50),surface.Label(panel,messages[i],25,Color.white,32,78,556,144)}){var outline=label.gameObject.AddComponent<Outline>();outline.effectColor=new Color(.055f,.11f,.075f);outline.effectDistance=new Vector2(2,-2);}
    if(i==0){LoadingButton(surface,panel,"ClearCancelButton","取消",38,246,240,54);LoadingButton(surface,panel,"ClearConfirmButton","确认清空",342,246,240,54);}
    else if(i==1){LoadingButton(surface,panel,"LoadRetryButton","重试",38,246,240,54);LoadingButton(surface,panel,"LoadResetButton","清空本地数据",342,246,240,54);}
    else LoadingButton(surface,panel,"RecoveryContinueButton","继续",190,246,240,54);
    var clone=Object.Instantiate(overlay.gameObject);clone.name="LoadingDialog";clone.AddComponent<UiPrefabInstance>();PersistVisuals(clone);
    foreach(var node in clone.GetComponentsInChildren<PrefabUiNode>(true))node.RecordBaseline();
    Save(clone,"UI/"+ids[i]);Object.DestroyImmediate(overlay.gameObject);
   }
   Object.DestroyImmediate(surface.CanvasObject);
   var notice=new GameUiSurface("SaveErrorCanvas",2200,0);notice.Shade.raycastTarget=false;
   var noticePanel=GameUiSurface.Rect(notice.Root,"SaveErrorPanel",70,90,801,100);noticePanel.gameObject.AddComponent<Image>().color=new Color(.12f,.2f,.3f,.97f);
   notice.Label(noticePanel,"本地保存失败，请检查空间后重试",25,Color.white,16,4,570,90);LoadingButton(notice,noticePanel,"SaveRetryButton","重试",600,22,175,56);
   SaveUi("SaveErrorCanvas");Object.DestroyImmediate(notice.CanvasObject);
  }
  static void LoadingButton(GameUiSurface surface,Transform parent,string name,string copy,float x,float y,float w,float h){var r=GameUiSurface.Rect(parent,name,x,y,w,h);var image=r.gameObject.AddComponent<Image>();image.color=new Color(.1f,.35f,.56f);r.gameObject.AddComponent<Button>().targetGraphic=image;surface.Label(r,copy,26,Color.white,4,0,w-8,h);}
  static void Fail(Exception error){SessionState.SetBool(Pending,false);EditorApplication.update-=Tick;Directory.CreateDirectory(output);File.WriteAllText(Path.Combine(output,"bake-result.txt"),"FAIL "+error);EditorApplication.Exit(1);}
 }
}
