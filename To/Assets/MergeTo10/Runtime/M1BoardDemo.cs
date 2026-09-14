using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using MergeTo10.Core;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.EventSystems;
namespace MergeTo10.Runtime
{
 public sealed class M1BoardDemo:MonoBehaviour
 {
  readonly BoardModel model=new BoardModel();
  readonly Dictionary<int,CellView> views=new Dictionary<int,CellView>();
  M1Art art; Transform board,stage; Camera cameraView; AudioSource sound; M1MergeFeedback feedback;
  SpriteRenderer background;Vector2 lastScreen;
  MergeTrailLayer trails;BoardShadow boardShadow;
  public MergeTrailLayer Trails=>trails;
  public BoardShadow Shadow=>boardShadow;
  System.Random random; int pressed=-1; bool busy; string state="Ready";
  public bool Busy=>busy;
  public bool InputBlocked {get;set;}
  public bool ShowDebugPanel=true;
  public bool SoundEnabled=true;
  public Transform Stage=>stage;
  public IBoardCombatSink CombatSink {get;set;}
  public SkillEnergy Energy {get;set;}
  public Action<int,Vector2,int,bool> GainEnergy {get;set;}
  public Func<ImprintStrike,Vector2,IEnumerator> PlayImprintStrike {get;set;}
  public Func<Vector2,IEnumerator> PlayPendingImprint {get;set;}
  IBoardCombatSink activeCombat;
  public MergeAttackBatch LastAttackBatch {get;private set;}
  public event Action<IReadOnlyList<MergeStep>> BatchCompleted;
  void Start()
  {
   Application.targetFrameRate=60;
   art=new M1Art();stage=WorldPrefabFactory.Child(transform,"GameLayer");if(!stage)stage=WorldPrefabFactory.Create("Core/GameLayer","GameLayer",transform).transform;
   if(!GetComponent<M2BattleDemo>()){var unusedBattle=WorldPrefabFactory.Child(stage,"M2BattleWorld");if(unusedBattle){unusedBattle.gameObject.SetActive(false);Destroy(unusedBattle.gameObject);}}
   var existingCamera=WorldPrefabFactory.Child(transform,"BoardCamera");var cam=existingCamera?existingCamera.gameObject:WorldPrefabFactory.Create("Core/BoardCamera","BoardCamera",transform);cameraView=cam.EnsureComponent<Camera>();
   cam.EnsureComponent<AudioListener>();
   cameraView.orthographic=true;cameraView.clearFlags=CameraClearFlags.SolidColor;cameraView.backgroundColor=new Color(.2f,.2f,.2f);
   cameraView.transform.position=new Vector3(4.705f,-8.36f,-10);
   background=Place("Background","background",Vector2.zero,LayoutMapper.Design,-1000);
   Place("BoardBackdrop","board_plate",LayoutMapper.BoardOrigin+new Vector2(-1.55f,-2.43f),new Vector2(653.68f,649.39f),-900);
   board=WorldPrefabFactory.Child(stage,"WorldSpaceBoard");bool authoredBoard=board;if(!board){board=new GameObject("WorldSpaceBoard").transform;board.SetParent(stage,false);}var preview=board.Find("EditorPreview");if(preview){preview.gameObject.SetActive(false);Destroy(preview.gameObject);}
   if(!authoredBoard){board.localPosition=LayoutMapper.World(LayoutMapper.BoardToDesign(Vector2.zero));board.localScale=Vector3.one*.95f;}
   trails=board.gameObject.AddComponent<MergeTrailLayer>();trails.Setup();
   var shadowObject=new GameObject("GlobalBlockShadow");shadowObject.transform.SetParent(board,false);
   boardShadow=shadowObject.AddComponent<BoardShadow>();boardShadow.Setup(()=>views.Values);
   feedback=gameObject.AddComponent<M1MergeFeedback>();feedback.Setup(stage,art);
   sound=gameObject.AddComponent<AudioSource>();ResetBoard();Fit();
   if(Environment.GetCommandLineArgs().Contains("--m1-smoke"))gameObject.AddComponent<M1Smoke>();
   if(Environment.GetCommandLineArgs().Contains("--m2-settlement-smoke"))gameObject.AddComponent<M2SettlementSmoke>();
  }
  SpriteRenderer Place(string name,string key,Vector2 position,Vector2 size,int order)
  {bool authored=WorldPrefabFactory.Child(stage,name);var sprite=art.Create(name,stage,key,order,size);if(!authored)sprite.transform.localPosition=LayoutMapper.World(position+size*.5f);Cover(sprite,size);return sprite;}
  static void Cover(SpriteRenderer renderer,Vector2 size)
  {
   float sourceAspect=renderer.sprite.rect.width/renderer.sprite.rect.height,targetAspect=size.x/size.y;
   var crop=sourceAspect>targetAspect?new Vector2(targetAspect/sourceAspect,1):new Vector2(1,sourceAspect/targetAspect);
   var properties=new MaterialPropertyBlock();renderer.GetPropertyBlock(properties);
   properties.SetVector("_UvCrop",new Vector4((1-crop.x)*.5f,(1-crop.y)*.5f,crop.x,crop.y));renderer.SetPropertyBlock(properties);
  }
  void Fit()
  {
   var screen=new Vector2(Screen.width,Screen.height);if(screen==lastScreen)return;lastScreen=screen;
   float fit=LayoutMapper.Scale(screen);cameraView.orthographicSize=Screen.height/(200*fit);
   // Preserve the source's covered background inside its offset GameLayer, including its known gutter.
   var size=screen/fit;M1Art.SetSize(background,size);background.transform.localPosition=LayoutMapper.World(size*.5f);
   Cover(background,size);
  }
  public BoardSnapshot CaptureBoard()=>model.Capture();
  public void RestoreBoard(BoardSnapshot snapshot)=>ResetBoard(false,null,1,snapshot);
  public bool HasMatch=>model.Cells.Any(c=>model.Group(c,false).Count>=2);
  public IEnumerator ReviveBoard()
  {
   if(busy)yield break;
   busy=true;
   int min=model.Cells.Select(c=>c.Level).DefaultIfEmpty(0).Min();
   foreach(var c in model.Cells.Where(c=>c.Level==min).ToArray()){
    model.Remove(c);Destroy(views[c.Id].gameObject);views.Remove(c.Id);
   }
   yield return new WaitForSeconds(.18f);yield return FallAndFill(new List<Cell>());busy=false;
  }
  public void ResetBoard(bool animate=true,int[] fixture=null,int historicalHighest=1,BoardSnapshot snapshot=null)
  {
   CancelCombat();LastAttackBatch=null;
   StopAllCoroutines();feedback?.Clear();trails?.Clear();foreach(var v in views.Values)if(v){v.gameObject.SetActive(false);Destroy(v.gameObject);}views.Clear();
   busy=false;pressed=-1;state="Ready";random=new System.Random(1010);
   model.Load(fixture??new[]{2,2,2,2,2,2,1,1,1,3,3,2,2,2,2,3,2,3,2,3,2,1,3,3,3},historicalHighest);
   if(snapshot!=null)model.Restore(snapshot);
   foreach(var c in model.Cells)Create(c);
   if(animate){busy=true;StartCoroutine(Intro());}
  }
  IEnumerator Intro()
  {
   state="Entering board";
   var cells=model.Cells.ToArray();float age=0,total=(cells.Length-1)*.04f+.28f;
   // All delays share the same origin, like Godot's independently delayed tweens.
   // Sequential WaitForSeconds(.04) accumulates frame rounding across 25 cells.
   while(age<total)
   {
    for(int i=0;i<cells.Length;i++)
    {
     var c=cells[i];var end=LayoutMapper.CellTopLeft(c.X,c.Y);
     var start=new Vector2(end.x,-116*(c.Y+1));float t=Mathf.Clamp01((age-i*.04f)/.28f);
     views[c.Id].SetPosition(Vector2.Lerp(start,end,1-Mathf.Pow(1-t,3)));
    }
    yield return null;age+=Time.deltaTime;
   }
   foreach(var c in cells)views[c.Id].SetPosition(LayoutMapper.CellTopLeft(c.X,c.Y));
   busy=false;state="Ready";
  }
  CellView Create(Cell c)
  {var go=WorldPrefabFactory.Create("Board/Cell","Cell_"+c.Id,board);var view=go.EnsureComponent<CellView>();view.Setup(c,art,c.Y*5+c.X);views.Add(c.Id,view);return view;}
  void Update()
  {
   if(cameraView==null)return;Fit();
   if(Touchscreen.current!=null&&Touchscreen.current.touches.Count(t=>t.press.isPressed)>1){pressed=-1;return;}
   Vector2 point;bool down,up;
   if(Touchscreen.current!=null&&Touchscreen.current.primaryTouch.press.isPressed)
   {var touch=Touchscreen.current.primaryTouch;point=touch.position.ReadValue();down=touch.press.wasPressedThisFrame;up=touch.press.wasReleasedThisFrame;}
   else if(Touchscreen.current!=null&&Touchscreen.current.primaryTouch.press.wasReleasedThisFrame)
   {point=Touchscreen.current.primaryTouch.position.ReadValue();down=false;up=true;}
   else if(Mouse.current!=null)
   {point=Mouse.current.position.ReadValue();down=Mouse.current.leftButton.wasPressedThisFrame;up=Mouse.current.leftButton.wasReleasedThisFrame;}
   else return;
   int pointerId=Touchscreen.current!=null&&(Touchscreen.current.primaryTouch.press.isPressed||Touchscreen.current.primaryTouch.press.wasReleasedThisFrame)?Touchscreen.current.primaryTouch.touchId.ReadValue():-1;
   if(EventSystem.current&&EventSystem.current.IsPointerOverGameObject(pointerId)){pressed=-1;return;}
   if(busy||InputBlocked){pressed=-1;return;}
   int cell=Hit(point);
   if(down)pressed=cell;
   if(up){int selected=pressed;pressed=-1;if(selected>=0&&cell==selected)TryMerge(selected%5,selected/5);}
  }
  int Hit(Vector2 point)
  {
   var p=LayoutMapper.DesignToBoard(LayoutMapper.ScreenToDesign(point,new Vector2(Screen.width,Screen.height)));
   for(int y=4;y>=0;y--)for(int x=4;x>=0;x--)if(new Rect(LayoutMapper.CellTopLeft(x,y),Vector2.one*116).Contains(p))return y*5+x;
   return -1;
  }
  public bool TryMerge(int x,int y)
  {
   if(busy||InputBlocked)return false;var target=model.At(x,y);if(target==null||target.Level>=36)return false;
   var group=model.Group(target,false);if(group.Count<2){views[target.Id].InvalidShake();return false;}
   busy=true;pressed=-1;if(SoundEnabled)sound.PlayOneShot(Resources.Load<AudioClip>("M1Art/merge"));
   activeCombat=CombatSink;activeCombat?.BeginSettlement();
   StartCoroutine(Settle(target,group));return true;
  }
  IEnumerator Settle(Cell root,List<Cell> group)
  {
   var prepared=Energy!=null&&Energy.HasPending?JsonUtility.FromJson<SkillEnergyState>(JsonUtility.ToJson(Energy.State)):null;
   int recordedLevel=root.Level;
   var batch=new List<MergeStep>();var contributions=new List<MergeAttack>();Cell target=root;
   for(int index=0;index<BoardModel.ChainLimit;index++)
   {
    int boardHighest=model.Cells.Select(c=>c.Level).DefaultIfEmpty(1).Max();
    var step=model.Prepare(target,group,index);batch.Add(step);state="Merge "+(index+1)+"/"+BoardModel.ChainLimit;
    var view=views[target.Id];if(index>0)view.BeginHighlight((float)step.Duration);
    int clicked=group.IndexOf(target),max=Math.Max(clicked,group.Count-1-clicked);
    var positions=group.Select(c=>views[c.Id].Position).ToArray();
    for(int i=0;i<group.Count;i++)if(i!=clicked)
    {
     int next=i<clicked?i+1:i-1;
     trails.Spawn(views[group[i].Id],positions[next],(float)((max-Math.Abs(i-clicked))*step.ActionTime),(float)step.ActionTime);
     // The animation belongs to the cell, so destroying it cancels delayed callbacks.
     var absorbed=views[group[i].Id];
     absorbed.StartCoroutine(absorbed.Absorb(positions[next],(float)((max-Math.Abs(i-clicked))*step.ActionTime),(float)step.ActionTime,50+i));
    }
    yield return new WaitForSeconds((float)step.Duration);
    model.Apply(step);
    foreach(var c in group)if(c!=target){Destroy(views[c.Id].gameObject);views.Remove(c.Id);}
    view.Refresh();view.ResultPop();if(index>0)view.CompleteHighlight();feedback.Play(view.Position,group.Count);
    var origin=LayoutMapper.BoardToDesign(view.Position+Vector2.one*58);
    if(target.Level>boardHighest)GainEnergy?.Invoke(6*(group.Count-1),origin,3,false);
    var contribution=new MergeAttack(step.SourceLevel,step.SourceLevel+1,group.Count,origin.x,origin.y,target.Y,index);
    contributions.Add(contribution);activeCombat?.RecordMerge(contribution);
    var settled=new List<Cell>{target};
    yield return FallAndFill(settled);
    group=model.FindAutomatic(settled);if(group.Count<2)break;
    target=group.Contains(root)?root:group[0];
   }
   LastAttackBatch=new MergeAttackBatch(contributions);
   // A single async combat owner keeps input locked until the last impact resolves.
   // With no sink, M1 remains an independent board parity scene.
   if(activeCombat!=null)yield return activeCombat.CompleteBatch(LastAttackBatch);
   var maximum=batch.Select(s=>s.Target).Distinct().Where(c=>c.Level>=36&&model.Find(c.Id)!=null).ToArray();
   if(prepared!=null){
    if(PlayPendingImprint!=null)yield return PlayPendingImprint(model.Find(root.Id)==root?LayoutMapper.BoardToDesign(views[root.Id].Position+Vector2.one*58):new Vector2(470.5f,1000));
    if(model.Find(root.Id)==root){
     var strike=ImprintRules.Apply(model,root,prepared.pending,prepared.quality,recordedLevel,random);
     foreach(var cell in model.Cells){views[cell.Id].Refresh();if(prepared.pending=="fate_shuffler")views[cell.Id].MoveTo(LayoutMapper.CellTopLeft(cell.X,cell.Y),.18f);}
     if(strike!=null&&PlayImprintStrike!=null)yield return PlayImprintStrike(strike,LayoutMapper.BoardToDesign(views[root.Id].Position+Vector2.one*58));
     yield return new WaitForSeconds(.08f);
    }
    Energy?.Consume();
   }
   BatchCompleted?.Invoke(batch);
   if(maximum.Length>0)
   {
    yield return new WaitForSeconds(.16f);
    foreach(var c in maximum){model.Remove(c);Destroy(views[c.Id].gameObject);views.Remove(c.Id);}
    yield return new WaitForSeconds(.18f);yield return FallAndFill(new List<Cell>());
   }
   else yield return new WaitForSeconds(.12f);
   var completedCombat=activeCombat;activeCombat=null;completedCombat?.EndSettlement();
   busy=false;state="Ready - "+batch.Count+" merge steps";
  }
  IEnumerator FallAndFill(List<Cell> settled)
  {
   var moved=model.Compact();
   foreach(var move in moved){views[move.Cell.Id].MoveTo(LayoutMapper.CellTopLeft(move.Cell.X,move.Cell.Y),.12f);settled.Add(move.Cell);}
   if(moved.Count>0)yield return new WaitForSeconds(.20f);
   var born=model.Refill(()=>random.NextDouble());
   foreach(var c in born)
   {var v=Create(c);var end=v.Position;v.SetPosition(new Vector2(end.x,-116*(c.Y+1)));v.MoveTo(end,.20f,true);settled.Add(c);}
   if(born.Count>0)yield return new WaitForSeconds(.24f);
   foreach(var c in model.Cells)views[c.Id].SetPosition(LayoutMapper.CellTopLeft(c.X,c.Y));
  }
  void OnApplicationFocus(bool focus){if(!focus)pressed=-1;}
  void OnGUI()
  {
   if(!ShowDebugPanel)return;
   GUI.Box(new Rect(8,8,330,82),"M1 BOARD TEST / COMBAT NOT MIGRATED");
   GUI.Label(new Rect(18,32,310,22),state+" | Score: "+model.Score);
   if(GUI.Button(new Rect(18,58,135,24),"Reset board"))ResetBoard();
   if(GUI.Button(new Rect(165,58,155,24),"Run merge")&&!busy)TryMerge(2,1);
  }
  void CancelCombat(){var cancelled=activeCombat;activeCombat=null;cancelled?.CancelSettlement();}
  void OnDestroy(){CancelCombat();if(stage)Destroy(stage.gameObject);if(cameraView)Destroy(cameraView.gameObject);art?.Dispose();}
 }
}
