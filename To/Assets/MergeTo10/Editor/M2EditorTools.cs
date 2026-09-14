using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using MergeTo10.Core;
using MergeTo10.Runtime;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
namespace MergeTo10.Editor
{
 public static class M2EditorTools
 {
  public const string ScenePath="Assets/MergeTo10/Scenes/M2BattleParity.unity";
  public const string WaveScenePath="Assets/MergeTo10/Scenes/M2WaveBattle.unity";
  [MenuItem("Merge To 10/Open Navigation Integration")]
  public static void OpenNavigation(){
   if(EditorApplication.isPlaying||!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())return;
   const string path="Assets/MergeTo10/Scenes/NavigationIntegration.unity";
   if(File.Exists(path)){EditorSceneManager.OpenScene(path);return;}
   var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
   var go=new GameObject("NavigationIntegration");go.AddComponent<M1BoardDemo>();go.AddComponent<M2BattleDemo>().CampaignMode=true;
   go.AddComponent<ChapterNodeView>();go.AddComponent<CrystalChoiceView>();go.AddComponent<EnergyHudView>();go.AddComponent<ImprintChoiceView>();go.AddComponent<CampaignPersistence>();
   go.AddComponent<MainHubView>();go.AddComponent<BattleHudView>();go.AddComponent<BattlePauseView>();go.AddComponent<NavigationIntegration>();
   EditorSceneManager.SaveScene(scene,path);
  }
  [MenuItem("Merge To 10/Open Chapter Integration")]
  public static void OpenChapter()
  {
   if(EditorApplication.isPlaying||!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())return;
   const string path="Assets/MergeTo10/Scenes/ChapterIntegration.unity";
   if(File.Exists(path)){EditorSceneManager.OpenScene(path);var existing=UnityEngine.Object.FindFirstObjectByType<M2BattleDemo>();if(existing){bool changed=false;foreach(var type in new[]{typeof(ChapterNodeView),typeof(CrystalChoiceView),typeof(EnergyHudView),typeof(ImprintChoiceView),typeof(CampaignPersistence)})if(!existing.GetComponent(type)){existing.gameObject.AddComponent(type);changed=true;}if(changed)EditorSceneManager.SaveScene(existing.gameObject.scene);}return;}
   var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
   var go=new GameObject("ChapterIntegration");go.AddComponent<M1BoardDemo>();go.AddComponent<M2BattleDemo>().CampaignMode=true;
   go.AddComponent<ChapterNodeView>();
   go.AddComponent<CrystalChoiceView>();
   go.AddComponent<EnergyHudView>();
   go.AddComponent<ImprintChoiceView>();
   go.AddComponent<CampaignPersistence>();
   EditorSceneManager.SaveScene(scene,path);
  }
  [MenuItem("Merge To 10/Open M2 Wave Battle")]
  public static void OpenWaves()
  {
   if(EditorApplication.isPlaying||!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())return;
   if(File.Exists(WaveScenePath))EditorSceneManager.OpenScene(WaveScenePath);else CreateWaveScene();
  }
  static void CreateWaveScene()
  {
   var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
   var go=new GameObject("M2WaveBattle");go.AddComponent<M1BoardDemo>();go.AddComponent<M2BattleDemo>().WaveMode=true;
   EditorSceneManager.SaveScene(scene,WaveScenePath);
  }
  [MenuItem("Merge To 10/Open M2 Combat Test")]
  public static void Open()
  {
   if(EditorApplication.isPlaying)return;
   if(!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())return;
   if(File.Exists(ScenePath))EditorSceneManager.OpenScene(ScenePath);else CreateScene();
  }
  static void CreateScene()
  {
   var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
   var go=new GameObject("M2CombatFixture");go.AddComponent<M1BoardDemo>();go.AddComponent<M2BattleDemo>();
   EditorSceneManager.SaveScene(scene,ScenePath);
  }
  static double started,phaseStarted,frozenTime;
  static int phase,assertions;static string output;static M2BattleDemo combat;static M1BoardDemo board;
  static readonly List<double> launches=new List<double>(),hits=new List<double>();
  static string runtimeError;
  static void ObserveLog(string message,string stack,LogType type)
  {if((type==LogType.Exception||type==LogType.Error)&&stack.Contains("MergeTo10"))runtimeError=message;}
  [InitializeOnLoadMethod]
  static void ResumeAfterReload()
  {
   EditorApplication.pauseStateChanged-=FencePause;
   EditorApplication.pauseStateChanged+=FencePause;
   if(!SessionState.GetBool("M2ValidationPending",false))return;
   output=Environment.GetEnvironmentVariable("M2_EDITOR_OUTPUT");
   started=EditorApplication.timeSinceStartup;phase=0;
   assertions=SessionState.GetInt("M2ValidationChecks",0);
   Application.logMessageReceived-=ObserveLog;Application.logMessageReceived+=ObserveLog;
   EditorApplication.update-=Tick;EditorApplication.update+=Tick;
  }
  static void FencePause(PauseState state)
  {
   if(!EditorApplication.isPlaying)return;
   foreach(var demo in UnityEngine.Object.FindObjectsByType<M2BattleDemo>(FindObjectsSortMode.None))demo.FenceEditorPause();
  }
  static void Check(bool valid,string label){assertions++;if(!valid)throw new Exception(label);}
  public static void Validate()
  {
   try
   {
    output=Environment.GetEnvironmentVariable("M2_EDITOR_OUTPUT");
    if(string.IsNullOrEmpty(output))throw new Exception("M2_EDITOR_OUTPUT required");
    Directory.CreateDirectory(output);
    CampaignVerifier.Verify();
    File.WriteAllText(Path.Combine(output,"campaign-core.txt"),"PASS 32-wave campaign traversal, tutorial gate, spawn/freeze/restore/boss delays, energy choice gates, meta tasks/sign-in/purchases/fragments, board and monster snapshots, atomic profile backup recovery, crystal upgrades and 12 original card textures. Core-level evidence only: not a full-game UI acceptance result.");
    string oracle=Environment.GetEnvironmentVariable("M2_ORACLE");
    File.WriteAllText(Path.Combine(output,"core.txt"),M2CoreVerifier.Verify(oracle));
    string waveOracle=Path.Combine(Path.GetDirectoryName(oracle),"../M2WavesV02/wave_oracle.json");
    WaveVerifier.Verify(waveOracle);
    Check(Mathf.Abs(MonsterPresentation.SpawnScale(0)-.12f)<.00001f,"spawn start scale");
    Check(Mathf.Abs(MonsterPresentation.SpawnScale(.22f)-1)<.00001f,"spawn finish scale");
    Check(Mathf.Abs(MonsterPresentation.DeathDuration(false)-19f/24)<.00001f,"normal death duration");
    Check(MonsterPresentation.DeathFrame(.1f,true)==6,"annihilation frame rate");
    File.WriteAllText(Path.Combine(output,"wave-core.txt"),"PASS 20 wave configs, all spawn stats, three frozen frame traces, reward and final-wave boundaries.");
    var path=new BattlePath();var m=new BattleMonster(100);
    var feedbackMonster=new BattleMonster(1000);int feedbackCount=0;double feedbackSum=0;
    feedbackMonster.DamageFeedback+=(amount,direct)=>{feedbackCount++;feedbackSum+=amount;};
    feedbackMonster.Apply(new MergeAttack(5,6,2));
    feedbackMonster.Tick(.25,path);feedbackMonster.Tick(.25,path);feedbackMonster.Tick(.25,path);
    Check(feedbackCount==0,"burn does not spam per-frame feedback");
    feedbackMonster.Tick(.25,path);
    Check(feedbackCount==1&&Math.Abs(feedbackSum-(1000-feedbackMonster.Hp))<1e-8,"burn feedback aggregates actual damage");
    Check(DamageFeedbackLayer.FormatDamage(.1)=="-1"&&DamageFeedbackLayer.FormatDamage(2.5)=="-3","damage display rounding");
    Check(DamageFeedbackLayer.Alpha(.12f)==1&&DamageFeedbackLayer.Alpha(.54f)==0,"damage fade timing");
    Check(Mathf.Abs(DamageFeedbackLayer.FlashScale(0)-.48f)<.00001f&&Mathf.Abs(DamageFeedbackLayer.FlashScale(.16f)-1.5f)<.00001f,"annihilation flash scale");
    var recovery=new MonsterRecovery();recovery.Tick(.01f,true,true,.10f,new Vector2(4,-9),false);
    var offsetBefore=recovery.Offset;float angleBefore=recovery.Angle;
    recovery.Tick(0,true,false,0,Vector2.zero,false);
    Check(recovery.Offset==offsetBefore&&recovery.Angle==angleBefore,"paused recovery unchanged");
    recovery.Tick(1f/60,true,false,0,Vector2.zero,false);
    Check(Vector2.Distance(recovery.Offset,offsetBefore*.7f)<.00001f&&Mathf.Abs(recovery.Angle-angleBefore*(1-22f/60))<.00001f,"original recovery interpolation");
    recovery.Tick(.01f,false,false,0,Vector2.zero,false);Check(recovery.Offset==Vector2.zero&&recovery.Angle==0,"death resets offsets");
    Check(CombatHitAudio.VolumeDb(0,3,false)==-16&&CombatHitAudio.VolumeDb(1,3,false)==-23&&CombatHitAudio.VolumeDb(2,3,false)==-13,"original hit audio volumes");
    Check(Mathf.Abs(CombatHitAudio.Pitch(9)-1.12f)<.0001f,"hit pitch cap");
    Check(path.Points.Length==19&&path.Length>3000,"original path samples");
    m.Apply(new MergeAttack(1,2,2));m.Tick(.5,path);Check(m.Hp==100,"poison not continuous");
    m.Tick(.5,path);Check(Math.Abs(m.Hp-99.4)<1e-8,"one second poison tick");
    m=new BattleMonster(100);m.Apply(new MergeAttack(2,3,2));m.Tick(.5,path);
    Check(Math.Abs(m.Progress-(80*4.0/3*.4/path.Length*.5))<1e-8,"ice speed");
    m=new BattleMonster(100);m.Damage(1);m.Tick(.2,path);Check(m.Progress==0,"hit stop entire crossing frame");
    m.Tick(.1,path);Check(m.Progress>0,"hit stop recovers");
    m=new BattleMonster(100);for(int i=0;i<5;i++)m.Apply(new MergeAttack(1,2,2));
    Check(m.Poison.Count==4,"poison cap");
    CreateWaveScene();CreateScene();AssetDatabase.SaveAssets();
    started=EditorApplication.timeSinceStartup;phase=0;launches.Clear();hits.Clear();
    SessionState.SetBool("M2ValidationPending",true);SessionState.SetInt("M2ValidationChecks",assertions);
    EditorApplication.update+=Tick;EditorApplication.isPlaying=true;
   }
   catch(Exception e){Finish(e);}
  }
  static void Tick()
  {
   try
   {
    double now=EditorApplication.timeSinceStartup;
   if(now-started>75)throw new Exception("Play Mode watchdog: phase "+phase);
    if(runtimeError!=null)throw new Exception("Runtime error: "+runtimeError);
    if(!EditorApplication.isPlaying)return;
    if(combat==null){combat=UnityEngine.Object.FindFirstObjectByType<M2BattleDemo>();board=UnityEngine.Object.FindFirstObjectByType<M1BoardDemo>();}
    if(combat==null||!combat.Ready)return;
    if(phase==0)
    {
     combat.Launched+=(key,t)=>launches.Add(t);combat.Resolved+=(key,t)=>hits.Add(t);
     combat.BeginSettlement();
     combat.RecordMerge(new MergeAttack(1,2,2));combat.RecordMerge(new MergeAttack(1,2,3));
     Check(combat.Diagram.CountFor("poison")==2&&!combat.Diagram.RingVisible,"duplicate contributions count without resonance");
     combat.RecordMerge(new MergeAttack(2,3,2));Check(!combat.Diagram.RingVisible,"two elements no ring");
     combat.RecordMerge(new MergeAttack(3,4,2));Check(combat.Diagram.RingVisible,"three unique elements ring");
     Check(combat.Diagram.AlphaFor("poison")==0,"new icon starts transparent");
     Check(Mathf.Abs(ResonanceDiagram.PulseScale(.06f)-1.18f)<.0001f,"pulse peak");
     Check(Mathf.Abs(ResonanceDiagram.PulseScale(.16f)-1)<.0001f,"pulse settles");
     Check(ElementFlightVisual.LightningFrame(.21f)==0&&ElementFlightVisual.LightningFrame(.39f)==2,"lightning six-step loop");
     Check(Mathf.Abs(ElementFlightVisual.HistoryLength(700,1,68)-509.5f)<.001f,"trail 100ms history");
     Check(ResonanceDiagram.RevealAlpha(.16f,2)==0,"third icon stagger");
     combat.Diagram.AdvancePresentation(.5f);
     Check(combat.Diagram.AlphaFor("poison")==1&&combat.Diagram.AlphaFor("lightning")==1,"icons revealed");
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"resonance.png"),true);
     combat.ResetFixture();Check(!combat.Diagram.RingVisible&&combat.Diagram.CountFor("poison")==0,"reset diagram");
     combat.PreviewFiveElements();frozenTime=combat.CombatSeconds;phase=1;
    }
    else if(phase==1)
    {
     if(combat.Frozen){Check(combat.CombatSeconds==frozenTime,"simulation advances while frozen");return;}
     Check(launches.Count==5&&hits.Count==5,"five launch and hit groups");
     Check(combat.Impacts.TotalPlayed>=5,"real elemental hits emitted visuals");
     Check(combat.HitAudio.PlayedCount>=5,"resolved elemental hits emit audio");
     for(int i=0;i<5;i++){Check(hits[i]-launches[i]>=.14-1e-7,"damage before flight");if(i>0)Check(launches[i]-launches[i-1]>=.15-1e-7,"group spacing");}
     Capture();combat.ResetFixture();Check(board.TryMerge(2,1)&&combat.Frozen,"normal merge freezes");phase=2;phaseStarted=now;
    }
    else if(phase==2)
    {
     if(board.Busy)return;
     Check(!combat.Frozen&&board.LastAttackBatch!=null,"normal board completes combat");
     combat.ResetFixture();combat.PreviewFiveElements();phase=3;phaseStarted=now;
    }
    else if(phase==3&&now-phaseStarted>.1)
    {
     combat.ResetFixture();Check(!combat.Frozen&&!board.Busy&&combat.LaunchCount==0,"reset cancels pending preview");
     phase=4;phaseStarted=now;
    }
    else if(phase==4&&now-phaseStarted>1)
    {
     Check(combat.LaunchCount==0,"old preview launches after reset");
     combat.WaveMode=true;combat.ResetFixture();phase=5;phaseStarted=now;
    }
    else if(phase==5)
    {
     if(combat.CrystalHits<1||!combat.CrystalBusy)return;
     Check(combat.Waves!=null&&combat.AliveCount>0,"wave spawned monsters and crystal hit");
     Capture();Check(board.TryMerge(2,1),"wave merge accepted");
     Check(!combat.CrystalBusy,"merge cancels in-flight crystal charge");
     SessionState.SetInt("M2QueueAtFreeze",combat.Waves.Remaining);
     SessionState.SetInt("M2CrystalAtFreeze",combat.CrystalHits);
     phase=6;
    }
    else if(phase==6)
    {
     if(combat.Frozen)
     {
      Check(combat.Waves.Remaining==SessionState.GetInt("M2QueueAtFreeze",-1),"spawning while frozen");
      Check(combat.CrystalHits==SessionState.GetInt("M2CrystalAtFreeze",-1),"crystal hit while frozen");return;
     }
     if(board.Busy)return;phase=7;
    }
    else if(phase==7)
    {
     foreach(var monster in combat.InspectMonsters())monster.Damage(monster.Hp);
     if(!combat.Waves.AwaitingReward)return;
     Check(combat.Waves.Index==0&&combat.Waves.Remaining==0,"reward waiting boundary");
     phaseStarted=now;phase=8;
    }
    else if(phase==8&&now-phaseStarted>.3)
    {
     Check(combat.Waves.Index==0,"no early next wave");
     combat.ContinueWave();Check(combat.Waves.Index==1&&combat.Waves.Spawning,"explicit continue next wave");
     combat.ResetFixture();Check(combat.Waves.Index==0&&combat.CrystalHits==0,"reset full wave session");
     combat.WaveMode=false;combat.ResetFixture();combat.BeginSettlement();
     var models=combat.InspectMonsters();models[0].Damage(models[0].Hp);models[1].Annihilate();
     combat.DamageNumbers.PlayAnnihilation(new Vector2(470,600));
     Check(combat.AliveCount==6,"dead actors immediately excluded");
     phaseStarted=Time.timeAsDouble;phase=9;
    }
    else if(phase==9&&Time.timeAsDouble-phaseStarted>.08)
    {
     Check(combat.DeathVisualCount==2,"both death animations visible while settlement frozen");
     Check(combat.DamageNumbers.ActiveFlashes==1,"annihilation flash visible");
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"annihilation.png"),true);phase=10;
    }
    else if(phase==10&&Time.timeAsDouble-phaseStarted>.45)
    {
     Check(combat.DeathVisualCount==1,"annihilation clears earlier than normal death");phase=11;
    }
    else if(phase==11&&Time.timeAsDouble-phaseStarted>1)
    {
     Check(combat.DeathVisualCount==0&&combat.AliveCount==6,"death visuals finish while simulation frozen");
     Check(combat.DamageNumbers.ActiveFlashes==0&&combat.DamageNumbers.ActiveCount==0,"annihilation visuals finish while frozen");
     combat.EndSettlement();combat.ResetFixture();combat.BeginSettlement();
     foreach(var monster in combat.InspectMonsters())monster.Damage(monster.Hp);
     phase=12;
    }
    else if(phase==12)
    {
     combat.ResetFixture();Check(combat.DeathVisualCount==0&&combat.AliveCount==8,"reset clears death visuals");
     combat.BeginSettlement();
     for(int i=0;i<ElementHitLayer.Keys.Length;i++)combat.Impacts.Play(ElementHitLayer.Keys[i],new Vector2(160+i*120,500),1);
     Check(combat.Impacts.ActiveCount==6,"all six impact types created");
     combat.PreviewFlightReview();
     combat.DamageNumbers.Play(32,new Vector2(470,680));
     var statusTarget=combat.InspectMonsters()[0];
     statusTarget.Apply(new MergeAttack(1,2,2));statusTarget.Apply(new MergeAttack(1,2,2));
     statusTarget.Apply(new MergeAttack(5,6,2));statusTarget.Apply(new MergeAttack(2,3,2));
     phaseStarted=Time.timeAsDouble;phase=13;
    }
    else if(phase==13&&Time.timeAsDouble-phaseStarted>.12)
    {
     Check(combat.Impacts.ActiveCount==6,"impacts remain visible before end");
     bool sawStatuses=false;
     foreach(var view in UnityEngine.Object.FindObjectsByType<MonsterStatusView>(FindObjectsSortMode.None))if(view.VisibleIndicators==3)sawStatuses=true;
     Check(sawStatuses,"ice burn poison indicators present");
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"flight-review.png"),true);phase=14;
    }
    else if(phase==14&&Time.timeAsDouble-phaseStarted>1.5)
    {
     Check(combat.Impacts.ActiveCount==0,"impacts finish during settlement freeze");
     Check(combat.DamageNumbers.ActiveCount==0,"damage numbers finish while frozen");
     Check(UnityEngine.Object.FindObjectsByType<ElementFlightVisual>(FindObjectsSortMode.None).Length==0,"flight tails and particles finish");
     combat.Impacts.Play("fire",new Vector2(470,500),1);combat.ResetFixture();
     Check(combat.Impacts.ActiveCount==0,"reset clears impacts");
     combat.BeginSettlement();combat.PreviewFlightReview();Time.timeScale=0;
     phaseStarted=now;phase=15;
    }
    else if(phase==15&&now-phaseStarted>.20)
    {
     var flights=UnityEngine.Object.FindObjectsByType<ElementFlightVisual>(FindObjectsSortMode.None);
     Check(flights.Length==5,"paused flight fixture persists");
     foreach(var flight in flights)Check(flight.PresentationAge==0,"pause holds visual clock");
     combat.ResetFixture();phase=16;phaseStarted=now;
    }
    else if(phase==16&&now-phaseStarted>.10)
    {
     Check(UnityEngine.Object.FindObjectsByType<ElementFlightVisual>(FindObjectsSortMode.None).Length==0,"reset removes flight visuals");
     Check(combat.DamageNumbers.ActiveCount==0,"reset clears damage text");
     foreach(var r in UnityEngine.Object.FindObjectsByType<SpriteRenderer>(FindObjectsSortMode.None))
      Check(!r.name.StartsWith("Ribbon_")&&!r.name.StartsWith("TrailParticle_"),"reset removes ribbon/particle siblings");
     combat.CampaignMode=true;combat.CampaignStartIndex=10;combat.ResetFixture();phase=17;phaseStarted=now;
    }
    else if(phase==17&&combat.AliveCount>0)
    {
     Check(combat.Campaign!=null&&combat.Waves==null,"chapter separate from legacy wave mode");
     Check(combat.InspectMonsters()[0].MaxHp==120,"actual mini boss hp");
     combat.BeginSettlement();SessionState.SetString("ChapterFrozenState",combat.Campaign.Export());phase=18;phaseStarted=now;
    }
    else if(phase==18&&now-phaseStarted>.15)
    {
     Check(combat.Campaign.Export()==SessionState.GetString("ChapterFrozenState",""),"actual chapter freeze retains spawn clock");
     Check(!combat.ContinueCampaign(),"cannot bypass running wave");combat.EndSettlement();phase=19;phaseStarted=now;
    }
    else if(phase==19)
    {
     foreach(var monster in combat.InspectMonsters())if(monster.Alive)monster.Damage(100000);
     if(!combat.Campaign.State.AwaitingReward)return;
     Check(combat.Gate==M2BattleDemo.ChapterGate.NodeComplete&&combat.ContinueCampaign(),"boss node transition precedes reward");
     Check(!combat.ContinueCampaign(),"cannot bypass chapter reward");
     Check(combat.CrystalChoices.Count==3,"three crystal choices");
     Check(combat.ChooseCrystalReward(combat.CrystalChoices[0],1),"chapter crystal reward granted");
     Check(!combat.ChooseCrystalReward(combat.CrystalChoices[0],1),"chapter reward double claim rejected");
     Check(combat.ContinueCampaign()&&combat.Campaign.State.Index==11,"actual chapter reward gate advances once");
     Check(!combat.ContinueCampaign(),"double continue rejected");phase=20;phaseStarted=now;
    }
    else if(phase==20&&combat.AliveCount>0)
    {
     bool found=false;foreach(var monster in combat.InspectMonsters())if(monster.Alive&&monster.MaxHp==300)found=true;
     Check(found,"actual final boss hp");
     var saved=combat.CaptureCampaign();int savedCount=saved.Actors.Length;
     combat.RestoreCampaign(saved);
     Check(combat.AliveCount==savedCount&&combat.Campaign.State.Index==11,"chapter live snapshot restore");
     Check(board.CaptureBoard().Score==saved.Board.Score,"restored board score");
     Check(combat.BossRewardCommitted,"reward commitment restored");
     var nodeCheckpoint=JsonUtility.FromJson<M2BattleDemo.CampaignSnapshot>(JsonUtility.ToJson(saved));
     saved.Durability=0;combat.RestoreCampaign(saved,nodeCheckpoint);phase=21;phaseStarted=now;
    }
    else if(phase==21&&combat.Gate==M2BattleDemo.ChapterGate.Defeat)
    {
     Check(combat.Settlement!=null&&!combat.Settlement.Won&&combat.Meta.State.Coins>=combat.Settlement.Coins,"defeat rewards committed");
     Check(combat.ReviveChapter()&&combat.Durability==20,"revive restores castle");
     Check(!combat.ReviveChapter(),"revive double click blocked");phase=22;phaseStarted=now;
    }
    else if(phase==22&&combat.Gate==M2BattleDemo.ChapterGate.None&&!board.Busy)
    {
     Check(combat.Campaign.State.Index==11,"revive preserves current wave");
     var blocked=new int[25];for(int i=0;i<25;i++)blocked[i]=i+1;
     board.ResetBoard(false,blocked,25);phase=23;phaseStarted=now;
    }
    else if(phase==23&&combat.Gate==M2BattleDemo.ChapterGate.Defeat)
    {
     Check(combat.RetryChapter()&&combat.Durability==20,"retry restores node checkpoint durability");
     Check(combat.Campaign.State.Index==11&&board.HasMatch,"retry restores node board and wave");
     Check(!combat.RetryChapter(),"retry double click rejected");
     combat.gameObject.AddComponent<ChapterNodeView>();combat.CampaignStartIndex=2;combat.ResetFixture();phase=24;phaseStarted=now;
    }
    else if(phase==24)
    {
     foreach(var monster in combat.InspectMonsters())if(monster.Alive)monster.Damage(100000);
     if(combat.Gate!=M2BattleDemo.ChapterGate.NodeComplete)return;
     Check(combat.GetComponent<ChapterNodeView>().Visible,"formal node modal visible");phase=25;phaseStarted=now;
    }
    else if(phase==25&&now-phaseStarted>.3)
    {
     var canvas=GameObject.Find("ChapterNodeCanvas").GetComponent<Canvas>();
     canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=UnityEngine.Object.FindFirstObjectByType<Camera>();canvas.planeDistance=1;
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"chapter-node.png"),true);
     canvas.renderMode=RenderMode.ScreenSpaceOverlay;
     var modal=combat.GetComponent<ChapterNodeView>();modal.Submit();
     Check(!modal.Visible&&combat.Campaign.State.Index==3,"formal node continue resumes next node");
     modal.Submit();Check(combat.Campaign.State.Index==3,"closed modal cannot submit twice");
     combat.CampaignMode=false;combat.ResetFixture();
     Check(combat.Campaign==null,"reset exits chapter mode cleanly");
     board.Energy=combat.Energy;Check(combat.Energy.Choose("ascension_hammer",5),"prepare live imprint");
     Check(board.TryMerge(2,1),"live imprint merge starts");phase=26;phaseStarted=now;
    }
    else if(phase==26&&!board.Busy&&now-phaseStarted>.1)
    {
     Check(!combat.Energy.HasPending,"pending imprint consumed once after batch");
     Check(board.CaptureBoard().Highest>=4,"live hammer raises result level");
     combat.gameObject.AddComponent<CrystalChoiceView>();combat.CampaignMode=true;combat.CampaignStartIndex=10;combat.ResetFixture();phase=27;phaseStarted=now;
    }
    else if(phase==27)
    {
     foreach(var monster in combat.InspectMonsters())if(monster.Alive)monster.Damage(100000);
     if(combat.Gate==M2BattleDemo.ChapterGate.NodeComplete)combat.GetComponent<ChapterNodeView>().Submit();
     var choice=combat.GetComponent<CrystalChoiceView>();if(!choice.Interactable)return;
     Check(combat.Paused&&choice.Visible,"formal reward modal pauses battle");choice.Confirm();Check(!combat.BossRewardCommitted,"confirm requires a selection");
     var canvas=GameObject.Find("CrystalChoiceCanvas").GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=UnityEngine.Object.FindFirstObjectByType<Camera>();canvas.planeDistance=1;
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"crystal-choice.png"),true);canvas.renderMode=RenderMode.ScreenSpaceOverlay;
     choice.Select(0);choice.Confirm();choice.Confirm();phase=28;phaseStarted=now;
    }
    else if(phase==28&&!combat.GetComponent<CrystalChoiceView>().Visible)
    {
     Check(combat.BossRewardCommitted&&combat.Campaign.State.Index==11&&!combat.Paused,"formal reward completes and resumes next wave");
     var session=combat.CaptureSession();string json=JsonUtility.ToJson(session);
     var profile=new ProfileStore(Path.Combine(output,"complete-session.json"));profile.Save(json);
     combat.ResetFixture();combat.RestoreSession(JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(profile.Load(out _)));
     Check(combat.Campaign.State.Index==11&&combat.BossRewardCommitted,"complete profile retains reward and current wave");
     Check(combat.Meta.Export()==session.Meta,"complete profile retains meta progress");
     combat.gameObject.AddComponent<EnergyHudView>();combat.gameObject.AddComponent<ImprintChoiceView>();
     combat.CampaignStartIndex=3;combat.ResetFixture();phase=29;phaseStarted=now;
    }
    else if(phase==29&&combat.GetComponent<EnergyHudView>().Ready)
    {
     combat.Energy.Restore(new SkillEnergyState{energy=94});
     combat.GainEnergy(6,new Vector2(400,900),3,false);
     Check(!combat.Energy.ChoiceReady,"energy offer waits for motes");
     phase=30;phaseStarted=now;
    }
    else if(phase==30)
    {
     var choice=combat.GetComponent<ImprintChoiceView>();if(!choice.Interactable)return;
     Check(combat.Paused&&combat.GetComponent<EnergyHudView>().VisualEnergy==100,"imprint offer waits for visual full energy");
     Check(choice.Choices.Distinct().Count()==3,"three different imprints offered");
     choice.Confirm();Check(!combat.Energy.HasPending,"imprint selection required");
     var canvas=GameObject.Find("ImprintChoiceCanvas").GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=UnityEngine.Object.FindFirstObjectByType<Camera>();canvas.planeDistance=1;
     var hud=GameObject.Find("EnergyHudCanvas").GetComponent<Canvas>();hud.renderMode=RenderMode.ScreenSpaceCamera;hud.worldCamera=canvas.worldCamera;hud.planeDistance=1.1f;
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"imprint-choice.png"),true);canvas.renderMode=RenderMode.ScreenSpaceOverlay;hud.renderMode=RenderMode.ScreenSpaceOverlay;
     choice.Select(2);choice.Confirm();choice.Confirm();phase=31;phaseStarted=now;
    }
    else if(phase==31&&!combat.GetComponent<ImprintChoiceView>().Visible)
    {
     Check(combat.Energy.HasPending&&combat.Energy.State.energy==0&&!combat.Paused,"third imprint selectable without an ad and committed once");
     Check(combat.Run.Cards.Count==1&&combat.Run.Cards[0].Selections==1,"double confirm records one run card");
     var session=combat.CaptureSession();string id=combat.Energy.State.pending;combat.RestoreSession(session);
     Check(combat.Energy.State.pending==id,"pending imprint persists with ownership");
     var disk=combat.gameObject.AddComponent<CampaignPersistence>();disk.PathOverride=Path.Combine(output,"live-profile.json");phase=32;phaseStarted=now;
    }
    else if(phase==32)
    {
     var disk=combat.GetComponent<CampaignPersistence>();if(!disk.Ready)return;
     Check(disk.SaveStable()&&File.Exists(disk.PathOverride),"attached persistence writes a stable live profile");
     var store=new ProfileStore(disk.PathOverride);var saved=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(store.Load(out _));
     Check(saved.Current.Energy.pending==combat.Energy.State.pending,"disk snapshot contains pending imprint");
     Check(saved.Current.Run.Cards.Count==1,"disk snapshot contains run deck");
     combat.RestoreSession(saved);Check(combat.Meta.State.Day.Length==10,"daily meta progress initialized");
     Check(board.TryMerge(2,1),"prepared HUD imprint starts next valid merge");phase=33;phaseStarted=now;
    }
    else if(phase==33&&!board.Busy)
    {
     Check(!combat.Energy.HasPending,"HUD flight and prepared skill complete once");
     combat.gameObject.AddComponent<BattleHudView>();combat.gameObject.AddComponent<BattlePauseView>();phase=34;phaseStarted=now;
    }
    else if(phase==34&&combat.GetComponent<BattleHudView>().Ready&&now-phaseStarted>.1)
    {
     var hud=combat.GetComponent<BattleHudView>();
     Check(hud.CoinText==combat.Meta.State.Coins.ToString(),"HUD wallet uses live meta");
     Check(hud.CountText==(combat.AliveCount+combat.Campaign.State.Queue.Count)+"/"+combat.Campaign.State.Total,"HUD shows remaining monsters");
     var canvas=GameObject.Find("BattleHudCanvas").GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=UnityEngine.Object.FindFirstObjectByType<Camera>();canvas.planeDistance=1;
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"battle-hud.png"),true);canvas.renderMode=RenderMode.ScreenSpaceOverlay;
     hud.RequestPause();Check(combat.Paused&&combat.GetComponent<BattlePauseView>().Visible,"HUD pause opens source shell");
     frozenTime=combat.CombatSeconds;phase=35;phaseStarted=now;
    }
    else if(phase==35&&now-phaseStarted>.3)
    {
     Check(combat.CombatSeconds==frozenTime,"HUD pause freezes simulation");
     combat.GetComponent<BattlePauseView>().Resume();Check(!combat.Paused,"pause backdrop resumes battle");
     combat.gameObject.AddComponent<MainHubView>();combat.gameObject.AddComponent<NavigationIntegration>();phase=36;phaseStarted=now;
    }
    else if(phase==36&&combat.GetComponent<MainHubView>().IntroFinished)
    {
     Check(combat.NavigationSuspended&&combat.Paused,"lobby parks live battle");
     Check(combat.GetComponent<MainHubView>().CoinText==combat.Meta.State.Coins.ToString(),"lobby displays real wallet");
     var canvas=GameObject.Find("MainHubCanvas").GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=UnityEngine.Object.FindFirstObjectByType<Camera>();canvas.planeDistance=1;
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"main-hub.png"),true);canvas.renderMode=RenderMode.ScreenSpaceOverlay;
     frozenTime=combat.CombatSeconds;phase=37;phaseStarted=now;
    }
    else if(phase==37&&now-phaseStarted>.3)
    {
     Check(combat.CombatSeconds==frozenTime,"lobby does not simulate combat");
     var waveIndex=combat.Campaign.State.Index;combat.GetComponent<NavigationIntegration>().EnterBattle();
     Check(!combat.NavigationSuspended&&!combat.GetComponent<NavigationIntegration>().InHub&&combat.Campaign.State.Index==waveIndex,"lobby resumes parked chapter");
     combat.GetComponent<BattleHudView>().RequestPause();combat.GetComponent<BattlePauseView>().ExitRequested();
     Check(combat.Paused&&combat.GetComponent<ExitConfirmationView>().Visible,"exit requires confirmation");
     combat.GetComponent<ExitConfirmationView>().Cancel();Check(combat.Paused&&combat.GetComponent<BattlePauseView>().Visible,"cancel exit returns to paused battle");
     combat.GetComponent<BattlePauseView>().ExitRequested();combat.GetComponent<ExitConfirmationView>().Confirm();
     Check(combat.GetComponent<NavigationIntegration>().InHub,"confirmed exit returns to lobby");
     combat.GetComponent<DailyProgressView>().Show();phase=38;phaseStarted=now;
    }
    else if(phase==38&&now-phaseStarted>.1)
    {
     var daily=combat.GetComponent<DailyProgressView>();Check(daily.Visible,"daily entry opens original combined page");
     if(combat.Meta.CanClaimTask(3)){int before=combat.Meta.State.Crystals;Check(daily.ClaimTask(3)&&combat.Meta.State.Crystals==before+20&&!daily.ClaimTask(3),"daily reward once only");}
     if(combat.Meta.SignAvailable)Check(daily.ClaimSignin()&&!daily.ClaimSignin(),"signin grants once per day");
     var hubCanvas=GameObject.Find("MainHubCanvas").GetComponent<Canvas>();hubCanvas.renderMode=RenderMode.ScreenSpaceCamera;hubCanvas.worldCamera=UnityEngine.Object.FindFirstObjectByType<Camera>();hubCanvas.planeDistance=1.2f;
     var canvas=GameObject.Find("DailyProgressCanvas").GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=UnityEngine.Object.FindFirstObjectByType<Camera>();canvas.planeDistance=1;
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"daily.png"),true);canvas.renderMode=RenderMode.ScreenSpaceOverlay;
     daily.Hide();combat.GetComponent<NavigationSettingsView>().Show(null);
     phase=39;phaseStarted=now;
    }
    else if(phase==39&&now-phaseStarted>.1)
    {
     var canvas=GameObject.Find("NavigationSettingsCanvas").GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=UnityEngine.Object.FindFirstObjectByType<Camera>();canvas.planeDistance=1;
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"settings.png"),true);canvas.renderMode=RenderMode.ScreenSpaceOverlay;
     var settings=combat.GetComponent<NavigationSettingsView>();Check(settings.SetSetting("sound",false)&&combat.HitAudio.Muted&&!board.SoundEnabled,"settings mutes merge and impact sounds");
     var disk=combat.GetComponent<CampaignPersistence>();Check(disk.SaveStable(),"settings persist in lobby");
     var saved=JsonUtility.FromJson<M2BattleDemo.SessionSnapshot>(new ProfileStore(disk.PathOverride).Load(out _));var meta=new MetaProgress();meta.Restore(saved.Meta);Check(!meta.State.Sound,"saved settings retain sound preference");
     settings.SetSetting("sound",true);
     combat.GetComponent<NavigationSettingsView>().Hide(true);Check(combat.NavigationSuspended&&combat.Paused,"closing hub settings does not resume background battle");
     combat.GetComponent<MainHubView>().EntryRequested("CrystalUpgradeButton");phase=40;phaseStarted=now;
    }
    else if(phase==40&&now-phaseStarted>.1)
    {
     var crystal=combat.GetComponent<CrystalUpgradeView>();Check(crystal.Visible,"lobby crystal entry opens migrated page");
     Check(GameObject.Find("CrystalUpgradeCanvas").GetComponent<Canvas>().sortingOrder>GameObject.Find("MainHubCanvas").GetComponent<Canvas>().sortingOrder,"crystal upgrade renders above lobby and receives input first");
     var canvas=GameObject.Find("CrystalUpgradeCanvas").GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=UnityEngine.Object.FindFirstObjectByType<Camera>();canvas.planeDistance=1;
     Capture();File.Copy(Path.Combine(output,"editor-combat.png"),Path.Combine(output,"crystal-upgrade.png"),true);canvas.renderMode=RenderMode.ScreenSpaceOverlay;
     crystal.Hide();Check(!crystal.Visible&&combat.NavigationSuspended&&combat.Paused,"crystal return preserves lobby pause");Finish(null);
    }
   }
   catch(Exception e){Finish(e);}
  }
  static void Capture()
  {
   var camera=UnityEngine.Object.FindFirstObjectByType<Camera>();
   float oldAspect=camera.aspect,oldSize=camera.orthographicSize;
   camera.aspect=470f/836;camera.orthographicSize=8.36f;
   Canvas.ForceUpdateCanvases();
   var target=RenderTexture.GetTemporary(470,836,24);
   var old=RenderTexture.active;
   var texture=new Texture2D(470,836,TextureFormat.RGB24,false);
   try
   {
    RenderPipeline.SubmitRenderRequest(camera,new RenderPipeline.StandardRequest{destination=target});
    RenderTexture.active=target;texture.ReadPixels(new Rect(0,0,470,836),0,0);texture.Apply();
    File.WriteAllBytes(Path.Combine(output,"editor-combat.png"),texture.EncodeToPNG());
   }
   finally{camera.aspect=oldAspect;camera.orthographicSize=oldSize;RenderTexture.active=old;RenderTexture.ReleaseTemporary(target);UnityEngine.Object.DestroyImmediate(texture);}
  }
  static void Finish(Exception error)
  {
   SessionState.SetBool("M2ValidationPending",false);
   Application.logMessageReceived-=ObserveLog;
   EditorApplication.update-=Tick;
   if(!string.IsNullOrEmpty(output))File.WriteAllText(Path.Combine(output,"editor-result.txt"),error==null?
    "PASS assertions="+assertions+"; combat, waves, crystal, spawn/death timing, frozen death visuals and reset. No Windows build.":error.ToString());
   if(error!=null)Debug.LogException(error);
   EditorApplication.Exit(error==null?0:1);
  }
 }
}
