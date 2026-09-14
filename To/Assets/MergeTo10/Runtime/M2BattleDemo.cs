using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using MergeTo10.Core;
using UnityEngine;

namespace MergeTo10.Runtime
{
 // Explicit fixture scene, not a replacement for chapter/wave/crystal progression.
 [RequireComponent(typeof(M1BoardDemo))]
 public sealed class M2BattleDemo:MonoBehaviour,IBoardCombatSink
 {
  [Header("Test fixture only (not chapter balance)")]
  [Range(1,20)] public int MonsterCount=8;
  public float MonsterHp=120;
  [Range(0,0.95f)] public float FirstProgress=.42f;
  public bool TraceHits=true;
  [Header("Baseline 20-wave mode (chapter rewards not migrated)")]
  public bool WaveMode=false;
  [Header("Chapter integration fixture (formal UI pending)")]
  public bool CampaignMode=false;
  public bool ShowDebugPanel=true;
  public bool NavigationSuspended {get;set;}
  [Range(1,31)] public int CampaignStartIndex=1;
  public CampaignFlow Campaign {get;private set;}
  public CrystalProgress ChapterCrystal {get;private set;}
  public SkillEnergy Energy {get;}=new SkillEnergy();
  public event Action<int,Vector2,int,bool> EnergyFxRequested;
  public void GainEnergy(int amount,Vector2 origin,int motes,bool bright){
   if(!CampaignMode)return;int gained=Energy.Add(amount);if(gained<=0)return;
   if(EnergyFxRequested!=null)EnergyFxRequested(gained,origin,motes,bright);else Energy.FinishFx();
  }
  public bool BossRewardCommitted {get;private set;}
  public event Action PersistRequested;
  public RunProgress Run {get;private set;}=new RunProgress();
  public bool EnergyChoicesEnabled {get;set;}
  public bool AllowsEnergyChoice=>Campaign!=null&&(Campaign.Current.continuation||Campaign.Current.allow_random_energy_imprint);
  public bool WaitingForEnergyChoice=>EnergyChoicesEnabled&&AllowsEnergyChoice&&Energy.State.energy>=100&&!Energy.HasPending;
  public bool CommitImprintChoice(string id,int quality){
   if(!EnergyChoicesEnabled||!AllowsEnergyChoice||Gate!=ChapterGate.None||board.Busy||Frozen||!Energy.ChoiceReady)return false;
   if(!Energy.Choose(id,quality))return false;
   int index=Array.IndexOf(MetaProgress.Cards,id);Meta.State.Levels[index]=Math.Max(Meta.State.Levels[index],Mathf.Clamp(quality,1,5));Meta.State.SeenCards[index]=true;Run.RecordCard(id,quality);
   PersistRequested?.Invoke();return true;
  }
  public MetaProgress Meta {get;}=new MetaProgress();
  public RunSettlement Settlement {get;private set;}
  bool settlementCommitted;
  bool restoringSession;
  [Serializable] public sealed class SessionSnapshot {
   public int Version=1;public CampaignSnapshot Current,Checkpoint,Defeat;public string Meta;
   public ChapterGate Gate;public RunSettlement Settlement;public bool RewardsCommitted;
   public string[] CrystalOffers;
  }
  public SessionSnapshot CaptureSession()=>new SessionSnapshot{Current=CaptureCampaign(),Checkpoint=checkpoint,Defeat=defeatSnapshot,Meta=Meta.Export(),Gate=Gate,Settlement=Settlement,RewardsCommitted=settlementCommitted,CrystalOffers=crystalChoices.ToArray()};
  // JsonUtility expands null inline serializable classes to empty objects. Legacy v1
  // saves therefore contain an empty Defeat object even before any defeat happened.
  static bool EmptyOptionalCampaign(CampaignSnapshot value)=>value==null||(string.IsNullOrEmpty(value.Wave)&&string.IsNullOrEmpty(value.Crystal)&&(value.Board==null||value.Board.Values==null||value.Board.Values.Length==0)&&(value.Actors==null||value.Actors.Length==0)&&value.Elapsed==0&&value.Kills==0&&value.Leaks==0&&value.Durability==0);
  public static void ValidateSession(SessionSnapshot session){
   if(session==null||session.Version!=1||session.Current==null||string.IsNullOrEmpty(session.Meta)||!Enum.IsDefined(typeof(ChapterGate),session.Gate)||session.Gate==ChapterGate.Reviving)throw new ArgumentException("Invalid complete session snapshot");
   new MetaProgress().Restore(session.Meta);
   ValidateCampaign(session.Current);
   if(!EmptyOptionalCampaign(session.Checkpoint))ValidateCampaign(session.Checkpoint);
   if(!EmptyOptionalCampaign(session.Defeat))ValidateCampaign(session.Defeat);
   if(session.CrystalOffers!=null&&(session.CrystalOffers.Length>3||session.CrystalOffers.Distinct().Count()!=session.CrystalOffers.Length||session.CrystalOffers.Any(id=>Array.IndexOf(MetaProgress.Cards,id)<6)))throw new ArgumentException("Invalid crystal offers");
  }
  public void RestoreSession(SessionSnapshot session){
   ValidateSession(session);
   restoringSession=true;
   try{RestoreCampaign(session.Current,EmptyOptionalCampaign(session.Checkpoint)?null:session.Checkpoint);Meta.Restore(session.Meta);defeatSnapshot=EmptyOptionalCampaign(session.Defeat)?null:session.Defeat;
    Settlement=session.RewardsCommitted?session.Settlement:null;settlementCommitted=session.RewardsCommitted;
    crystalChoices.Clear();if(session.CrystalOffers!=null)crystalChoices.AddRange(session.CrystalOffers);
   }finally{restoringSession=false;}
   SetGate(session.Gate==ChapterGate.CrystalReward&&BossRewardCommitted?ChapterGate.None:session.Gate);
  }
  public int RunKills {get;private set;}
  public int RunLeaks {get;private set;}
  void CommitSettlement(bool won){
   if(settlementCommitted)return;
   var state=board.CaptureBoard();
   Settlement=RunSettlement.Calculate(won,state.Score,RunKills,RunLeaks,Campaign.State.Cleared,Math.Max(state.Highest,state.Values.Max()),Durability,CombatSeconds,Meta.State.DoubleCoin);Settlement.Run=Run.Copy();
   settlementCommitted=true;Meta.Grant(new MetaReward(Settlement.Coins,Settlement.Crystals));Meta.RecordSettlement(Settlement.BaseCoins);
  }
  readonly List<string> crystalChoices=new List<string>();
  public IReadOnlyList<string> CrystalChoices=>crystalChoices;
  public void MarkCrystalOffersSeen(){
   if(Gate!=ChapterGate.CrystalReward)return;bool changed=false;
   foreach(string id in crystalChoices){int index=Array.IndexOf(MetaProgress.Cards,id);if(!Meta.State.SeenCards[index]){Meta.State.SeenCards[index]=true;changed=true;}}
   if(changed)PersistRequested?.Invoke();
  }
  public bool ChooseCrystalReward(string card,int quality)
  {
   if(Campaign==null||Gate!=ChapterGate.CrystalReward||BossRewardCommitted||!crystalChoices.Contains(card))return false;
   if(!ChapterCrystal.Apply(card,quality))return false;
   BossRewardCommitted=true;int index=Array.IndexOf(MetaProgress.Cards,card);Meta.State.Levels[index]=Math.Max(Meta.State.Levels[index],Mathf.Clamp(quality,1,5));Meta.State.SeenCards[index]=true;Run.RecordCard(card,quality);
   PersistRequested?.Invoke();return true;
  }
  public event Action<int> CampaignWaveCleared;
  public enum ChapterGate {None,NodeComplete,CrystalReward,ChapterComplete,RunComplete,Defeat,Reviving}
  public ChapterGate Gate {get;private set;}
  public event Action<ChapterGate> GateChanged;
  CampaignSnapshot checkpoint,defeatSnapshot;
  public void CheckpointForHubExit(){checkpoint=CaptureCampaign();checkpointNode=Campaign.Current.node_id;PersistRequested?.Invoke();}
  string checkpointNode;
  void SetGate(ChapterGate value){
   Gate=value;
   if(!restoringSession&&Campaign!=null&&(value==ChapterGate.Defeat||value==ChapterGate.RunComplete))CommitSettlement(value==ChapterGate.RunComplete);
   if(value==ChapterGate.CrystalReward&&!BossRewardCommitted&&crystalChoices.Count==0){
    var pool=MetaProgress.Cards.Skip(6).ToList();while(crystalChoices.Count<3){int index=random.Next(pool.Count);crystalChoices.Add(pool[index]);pool.RemoveAt(index);}
   }
   GateChanged?.Invoke(value);
  }
  void RestoreGate(){
   if(Campaign==null){SetGate(ChapterGate.None);return;}
   SetGate(Campaign.State.Completed?ChapterGate.RunComplete:!Campaign.State.AwaitingReward?ChapterGate.None:Campaign.Current.chapter_final?ChapterGate.ChapterComplete:
    !string.IsNullOrEmpty(Campaign.Current.chapter_reward)?(BossRewardCommitted?ChapterGate.None:ChapterGate.NodeComplete):Campaign.Current.segment_end?ChapterGate.NodeComplete:ChapterGate.None);
  }
  public bool RetryChapter()
  {
   if(Gate!=ChapterGate.Defeat||checkpoint==null)return false;
   var saved=checkpoint;RestoreCampaign(saved,saved);return true;
  }
  public bool ReviveChapter()
  {
   if(Gate!=ChapterGate.Defeat||defeatSnapshot==null)return false;
   var saved=defeatSnapshot;var node=checkpoint;string nodeId=checkpointNode;
   RestoreCampaign(saved,node);checkpointNode=nodeId;Durability=20;SetGate(ChapterGate.Reviving);StartCoroutine(FinishRevive());return true;
  }
  IEnumerator FinishRevive(){yield return board.ReviveBoard();SetGate(ChapterGate.None);}
  [Range(1,20)] public int StartWave=1;
  public WaveFlow Waves {get;private set;}
  public int CrystalHits {get;private set;}
  public ElementHitLayer Impacts {get;private set;}
  public ResonanceDiagram Diagram {get;private set;}
  public DamageFeedbackLayer DamageNumbers {get;private set;}
  public CombatHitAudio HitAudio {get;private set;}
  public bool CrystalBusy=>crystalInFlight;
  public BattleMonster[] InspectMonsters()=>actors.Select(a=>a.Model).ToArray();
  public int DeathVisualCount=>actors.Count(a=>a.DeathAge>=0&&!a.Model.Reached);
  double crystalTimer=.9;
  bool crystalInFlight;
  int crystalSerial;
  Actor crystalTarget;
  SpriteRenderer crystal,crystalBolt;
  // Showcase lower-center beam anchor normalized inside the 236px drawn canvas.
  static readonly Vector2 CrystalOrigin=new Vector2(247.2f,452.8f)+new Vector2(90,204.48f)-new Vector2(256,477)*.530f+
   new Vector2(119f/236,117f/236)*(512*.530f);
  public bool Frozen {get;private set;}
  public bool Paused=>paused;
  public void SetPaused(bool value){paused=value;Time.timeScale=value?0:previousScale;if(HitAudio)HitAudio.Pause(value);if(board)board.InputBlocked=value||Gate!=ChapterGate.None;}
  public bool Ready {get;private set;}
  public int LaunchCount {get;private set;}
  public int HitCount {get;private set;}
  public int AliveCount=>actors.Count(a=>a.Model.Alive);
  public int Durability {get;private set;}=20;
  double restoredSeconds;
  public double CombatSeconds=>restoredSeconds+clock.SimulationTime;
  [Serializable] public sealed class SavedActor {public BattleMonster.Snapshot Monster;public int Tier,LeakDamage;public float Size;public string Boss;}
  [Serializable] public sealed class CampaignSnapshot {public string Wave,Crystal;public SkillEnergyState Energy;public RunProgress Run;public bool BossRewardCommitted;public BoardSnapshot Board;public SavedActor[] Actors;public int Durability,Kills,Leaks;public double Elapsed,CrystalTimer;}
  public CampaignSnapshot CaptureCampaign()
  {
   if(Campaign==null||!Ready||board.Busy||Frozen)throw new InvalidOperationException("Campaign snapshot requires an idle board");
   ChapterCrystal.State.Timer=crystalTimer;
   return new CampaignSnapshot{Wave=Campaign.Export(),Crystal=ChapterCrystal.Export(),Energy=JsonUtility.FromJson<SkillEnergyState>(JsonUtility.ToJson(Energy.State)),Run=Run.Copy(),BossRewardCommitted=BossRewardCommitted,Board=board.CaptureBoard(),Durability=Durability,Kills=RunKills,Leaks=RunLeaks,Elapsed=CombatSeconds,CrystalTimer=crystalTimer,
    Actors=actors.Where(a=>a.Model.Alive).Select(a=>new SavedActor{Monster=a.Model.Capture(),Tier=a.Tier,Size=a.Size,LeakDamage=a.LeakDamage,
     Boss=bossSprites.ContainsKey(a.Model)?a.Body.gameObject.name:""}).ToArray()};
  }
  public void RestoreCampaign(CampaignSnapshot snapshot,CampaignSnapshot nodeCheckpoint=null)
  {
   ValidateCampaign(snapshot);if(nodeCheckpoint!=null)ValidateCampaign(nodeCheckpoint);
   var checkRun=(snapshot.Run??new RunProgress()).Copy();
   var checkCrystal=new CrystalProgress(CardRules.Load());if(!string.IsNullOrEmpty(snapshot.Crystal))checkCrystal.Restore(snapshot.Crystal);
   ApplyCampaign(snapshot,nodeCheckpoint,checkRun,checkCrystal);
  }
  static void ValidateCampaign(CampaignSnapshot snapshot){
   if(snapshot==null||snapshot.Board==null||snapshot.Actors==null)throw new ArgumentException("Invalid chapter snapshot");
   // Validate nested state before changing any live object.
   var flow=new CampaignFlow(CampaignData.Load());flow.Restore(snapshot.Wave);
   var checkBoard=new BoardModel();checkBoard.Restore(snapshot.Board);
   var checkEnergy=new SkillEnergy();checkEnergy.Restore(snapshot.Energy??new SkillEnergyState());
   var checkRun=(snapshot.Run??new RunProgress()).Copy();checkRun.Validate();
   var checkCrystal=new CrystalProgress(CardRules.Load());if(!string.IsNullOrEmpty(snapshot.Crystal))checkCrystal.Restore(snapshot.Crystal);
   if(double.IsNaN(snapshot.Elapsed)||double.IsInfinity(snapshot.Elapsed)||snapshot.Elapsed<0||double.IsNaN(snapshot.CrystalTimer)||double.IsInfinity(snapshot.CrystalTimer))throw new ArgumentException("Invalid chapter timing");
   foreach(var item in snapshot.Actors){
    if(item==null||item.Tier<1||item.Tier>3||item.Size<=0||float.IsNaN(item.Size)||float.IsInfinity(item.Size)||item.LeakDamage<0)throw new ArgumentException("Invalid chapter actor");
    BattleMonster.Restore(item.Monster);
   }
   if(snapshot.Durability<0||snapshot.Durability>20||snapshot.Kills<0||snapshot.Leaks<0)throw new ArgumentException("Invalid chapter counters");
  }
  void ApplyCampaign(CampaignSnapshot snapshot,CampaignSnapshot nodeCheckpoint,RunProgress checkRun,CrystalProgress checkCrystal){
   CampaignMode=true;ResetFixture();
   board.RestoreBoard(snapshot.Board);Campaign.Restore(snapshot.Wave);
   Durability=Mathf.Clamp(snapshot.Durability,0,20);restoredSeconds=Math.Max(0,snapshot.Elapsed);crystalTimer=Math.Max(0,snapshot.CrystalTimer);
   ChapterCrystal=checkCrystal;BossRewardCommitted=snapshot.BossRewardCommitted;
   Energy.Restore(snapshot.Energy??new SkillEnergyState());
   Run=checkRun;
   RunKills=Math.Max(0,snapshot.Kills);RunLeaks=Math.Max(0,snapshot.Leaks);
   foreach(var saved in snapshot.Actors){
    SpawnCampaignMonster(new CampaignSpawn{monster_type="small",visual_tier=saved.Tier,overrides=new MonsterOverrides{appearance_id=saved.Boss}});
    var actor=actors[actors.Count-1];bool boss=bossSprites.TryGetValue(actor.Model,out var sprite);bossSprites.Remove(actor.Model);
    actor.Model=BattleMonster.Restore(saved.Monster);actor.Tier=saved.Tier;actor.Size=saved.Size;actor.LeakDamage=saved.LeakDamage;actor.SpawnAge=.22f;
    if(boss)bossSprites[actor.Model]=sprite;
    actor.Model.DamageFeedback+=(damage,direct)=>{actor.Flash=.14f;if(direct)actor.HitAge=0;DamageNumbers.Play(damage,path.At(actor.Model.Progress)+new Vector2(0,5));};
    PresentActor(actor,0);
   }
   checkpoint=JsonUtility.FromJson<CampaignSnapshot>(JsonUtility.ToJson(nodeCheckpoint??snapshot));checkpointNode=Campaign.Current.node_id;if(!restoringSession)RestoreGate();
  }
  public event Action<string,double> Launched;
  public event Action<string,double> Resolved;
  sealed class Actor {public BattleMonster Model;public SpriteRenderer Body,Bar;public MonsterStatusView Status;public float Flash,WalkAge,HitAge=1,Size=60,SpawnAge=.22f,DeathAge=-1,StunAge,PreviousStun,RecoilAge=1;public Vector2 RecoilDirection;public int Tier=1,LeakDamage=1;public bool Leaked;public readonly MaterialPropertyBlock Block=new MaterialPropertyBlock();public readonly MonsterRecovery Recovery=new MonsterRecovery();}
  readonly List<Actor> actors=new List<Actor>();
  readonly HashSet<BattleMonster> recordedKills=new HashSet<BattleMonster>();
  readonly Dictionary<BattleMonster,Sprite> bossSprites=new Dictionary<BattleMonster,Sprite>();
  readonly Dictionary<string,Sprite> art=new Dictionary<string,Sprite>();
  readonly Dictionary<string,SpriteRenderer> slots=new Dictionary<string,SpriteRenderer>();
  readonly List<MergeAttack> preview=new List<MergeAttack>();
  readonly List<GameObject> projectiles=new List<GameObject>();
  readonly BattlePath path=new BattlePath();
  readonly CombatClock clock=new CombatClock();
  readonly System.Random random=new System.Random(1901);
  M1BoardDemo board;Transform layer;Material material,lightningMaterial;Sprite white;Texture2D whiteTexture;
  int generation,pending;bool paused,demonstrating;float previousScale=1;
  static readonly Dictionary<string,Vector2> Slot=new Dictionary<string,Vector2>{
   {"fire",new Vector2(.50f,-.04f)},{"poison",new Vector2(.24f,.16f)},{"lightning",new Vector2(.76f,.16f)},
   {"ice",new Vector2(.30f,.46f)},{"critical",new Vector2(.70f,.46f)}};
  IEnumerator Start()
  {
   board=GetComponent<M1BoardDemo>();board.ShowDebugPanel=false;
   while(board.Stage==null||board.Busy)yield return null;
   previousScale=Time.timeScale;
   layer=WorldPrefabFactory.Child(board.Stage,"M2BattleWorld");if(!layer)layer=WorldPrefabFactory.Create("Combat/BattleWorld","M2BattleWorld",board.Stage).transform;
   var editorPreview=layer.Find("EditorPreview");if(editorPreview){editorPreview.gameObject.SetActive(false);Destroy(editorPreview.gameObject);}
   Impacts=layer.gameObject.AddComponent<ElementHitLayer>();Impacts.Setup();
   DamageNumbers=layer.gameObject.AddComponent<DamageFeedbackLayer>();DamageNumbers.Setup();
   HitAudio=layer.gameObject.AddComponent<CombatHitAudio>();HitAudio.Setup();
   var diagramObject=new GameObject("ResonanceDiagram");diagramObject.transform.SetParent(layer,false);
   Diagram=diagramObject.AddComponent<ResonanceDiagram>();Diagram.Setup();
   material=new Material(Resources.Load<Shader>("M1Art/ParitySprite"));
   lightningMaterial=new Material(Resources.Load<Shader>("M1Art/MonsterLightning"));
   foreach(string key in new[]{"monster_path","monster_gate","slime","slime2","slime3","crystal","projectile_crystal","icon_fire","icon_poison","icon_ice","icon_critical","icon_lightning","projectile_fire","projectile_poison","projectile_ice","projectile_critical","projectile_lightning"})
   {
    var tex=Resources.Load<Texture2D>("M2Art/"+key);
    if(!tex)throw new InvalidOperationException("Missing M2Art/"+key);
    art[key]=Sprite.Create(tex,new Rect(0,0,tex.width,tex.height),Vector2.one*.5f,100,0,SpriteMeshType.FullRect);
   }
   foreach(var family in new[]{"goblin","zombie"}){
    var tex=Resources.Load<Texture2D>("Campaign/"+family+"_stage_03");
    if(tex)art[family]=Sprite.Create(tex,new Rect(0,0,tex.width,tex.height),Vector2.one*.5f,100,0,SpriteMeshType.FullRect);
   }
   whiteTexture=new Texture2D(1,1);whiteTexture.SetPixel(0,0,Color.white);whiteTexture.Apply();
   LoadFrames("slime_stage_01_walk_sheet","walk",18,6);
   LoadFrames("slime_stage_01_hit_sheet","hit",8,4);
   LoadFrames("monster_death_sheet","death",19,5);
   white=Sprite.Create(whiteTexture,new Rect(0,0,1,1),Vector2.one*.5f,100);
   Make("Road","monster_path",new Vector2(44.11f,344.67f)+new Vector2(1363,1772)*(941f/1536)*.5f,new Vector2(1363,1772)*(941f/1536),-950);
   Make("Gate","monster_gate",new Vector2(97.41f,201.93f)+new Vector2(305,431)*(941f/1536)*.5f,new Vector2(305,431)*(941f/1536),-850);
   board.CombatSink=this;Ready=true;ResetFixture();
   board.PlayImprintStrike=PlaySkillStrike;
   board.BatchCompleted+=_=>PersistRequested?.Invoke();
  }
  SpriteRenderer Make(string name,string key,Vector2 position,Vector2 size,int order)
  {
   var existing=(name=="Road"||name=="Gate")?WorldPrefabFactory.Child(layer,name):null;var go=existing?existing.gameObject:WorldPrefabFactory.Create("Combat/"+((name=="Crystal")?"Crystal":(name.StartsWith("Monster")||name=="WaveMonster")?"Monster":(name.Contains("Bolt")||name.StartsWith("FlightReview")||name=="LightningLink")?"Projectile":name),name,layer);var r=go.EnsureComponent<SpriteRenderer>();
   r.sharedMaterial=material;r.sprite=key==null?white:art[key];r.sortingOrder=order;if(!existing)M1Art.SetSize(r,size);
   if(!existing)r.transform.localPosition=LayoutMapper.World(position);return r;
  }
  void LoadFrames(string name,string prefix,int count,int columns)
  {
   var texture=Resources.Load<Texture2D>("M2Art/"+name);
   if(!texture)throw new InvalidOperationException("Missing atlas "+name);
   for(int i=0;i<count;i++)
    art[prefix+i]=Sprite.Create(texture,new Rect((i%columns)*328+4,texture.height-(i/columns)*328-4-320,320,320),Vector2.one*.5f,100,0,SpriteMeshType.FullRect);
  }
  public void ResetFixture()
  {
   if(!Ready)return;
   SetGate(ChapterGate.None);
   Run=new RunProgress();
   Energy.Restore(new SkillEnergyState());board.Energy=CampaignMode?Energy:null;board.GainEnergy=GainEnergy;
   CancelSettlement();board.ResetBoard(false);paused=false;Time.timeScale=previousScale;board.InputBlocked=false;
   foreach(var a in actors){a.Body.gameObject.SetActive(false);a.Bar.gameObject.SetActive(false);if(a.Status){a.Status.gameObject.SetActive(false);Destroy(a.Status.gameObject);}Destroy(a.Body.gameObject);Destroy(a.Bar.gameObject);}actors.Clear();
   Durability=20;LaunchCount=HitCount=0;RunKills=RunLeaks=0;Settlement=null;settlementCommitted=false;recordedKills.Clear();restoredSeconds=0;clock.Reset();clock.Advance(Time.realtimeSinceStartupAsDouble,0,false,false);
   CrystalHits=0;crystalTimer=.9;Waves=null;Campaign=null;ChapterCrystal=null;BossRewardCommitted=false;crystalChoices.Clear();bossSprites.Clear();Gate=ChapterGate.None;checkpoint=defeatSnapshot=null;checkpointNode=null;
   if(crystal)Destroy(crystal.gameObject);
   if(WaveMode||CampaignMode)
   {
    crystal=Make("Crystal","crystal",new Vector2(247.2f,452.8f)+new Vector2(90,204.48f)+new Vector2(0,256-477)*.530f,Vector2.one*(512*.530f),-90);
    if(CampaignMode){
     ChapterCrystal=new CrystalProgress(CardRules.Load());
     Campaign=new CampaignFlow(CampaignData.Load());Campaign.Spawned+=SpawnCampaignMonster;
     Campaign.Cleared+=index=>{
      SetGate(Campaign.State.Completed?ChapterGate.RunComplete:Campaign.Current.chapter_final?ChapterGate.ChapterComplete:
       Campaign.Current.segment_end?ChapterGate.NodeComplete:!string.IsNullOrEmpty(Campaign.Current.chapter_reward)?ChapterGate.CrystalReward:ChapterGate.None);
      CampaignWaveCleared?.Invoke(index);
     };
     Campaign.Start(Mathf.Clamp(CampaignStartIndex,1,31),new System.Random(1902));
     checkpoint=CaptureCampaign();checkpointNode=Campaign.Current.node_id;
    }else{Waves=new WaveFlow();Waves.Spawned+=SpawnWaveMonster;Waves.Start(Mathf.Clamp(StartWave,1,20)-1,new System.Random(1902));}
    return;
   }
   for(int i=0;i<MonsterCount;i++)
   {
    var model=new BattleMonster(Math.Max(1,MonsterHp)){Progress=Math.Max(0,FirstProgress-i*.025)};
    var a=new Actor{Model=model,Body=Make("Monster_"+i,"walk0",path.At(model.Progress),Vector2.one*(60*2.28f),-100),
     Bar=Make("Hp_"+i,null,path.At(model.Progress)+new Vector2(0,38),new Vector2(54,5),-99)};
    model.DamageFeedback+=(damage,direct)=>{a.Flash=.14f;if(direct)a.HitAge=0;DamageNumbers.Play(damage,path.At(model.Progress)+new Vector2(0,5));};actors.Add(a);
   }
  }
  void SpawnWaveMonster(WaveFlow.Spawn spawn)
  {
   double[] hp={5,12,25},speed={80,68,55};float[] size={60,80,100};
   var model=new BattleMonster(hp[spawn.Type]*spawn.HpMultiplier){Speed=speed[spawn.Type]*4/3};
   float zoom=spawn.Tier==1?2.28f:spawn.Tier==2?1.76f:1.70f;
   var a=new Actor{Model=model,Tier=spawn.Tier,Size=size[spawn.Type],LeakDamage=spawn.Type+1,SpawnAge=0,
    Body=Make("WaveMonster",spawn.Tier==1?"walk0":"slime"+spawn.Tier,path.At(0),Vector2.one*(size[spawn.Type]*zoom),-100),
    Bar=Make("WaveHp",null,path.At(0),new Vector2(54,5),-99)};
   model.DamageFeedback+=(damage,direct)=>{a.Flash=.14f;if(direct)a.HitAge=0;DamageNumbers.Play(damage,path.At(model.Progress)+new Vector2(0,5));};actors.Add(a);
   PresentActor(a,0);
  }
  void SpawnCampaignMonster(CampaignSpawn spawn)
  {
   int type=spawn.monster_type=="large"?2:spawn.monster_type=="medium"?1:0;
   SpawnWaveMonster(new WaveFlow.Spawn{Type=type,Tier=Mathf.Clamp(spawn.visual_tier,1,3),HpMultiplier=spawn.hp_multiplier});
   var actor=actors[actors.Count-1];var config=spawn.overrides;
   if(config==null)return;
   if(config.hp>0)actor.Model.Hp=actor.Model.MaxHp=config.hp;
   if(config.speed>0)actor.Model.Speed=config.speed*4.0/3;
   if(config.durability_damage>0)actor.LeakDamage=config.durability_damage;
   if(config.scale>0)actor.Size=80*config.scale;
   string family=config.appearance_id=="mini_boss"?"goblin":config.appearance_id=="chapter_boss"?"zombie":null;
   if(family!=null){if(!art.TryGetValue(family,out var sprite))throw new InvalidOperationException("Missing chapter boss art: "+family);bossSprites[actor.Model]=sprite;}
   actor.Body.gameObject.name=string.IsNullOrEmpty(config.appearance_id)?"ChapterMonster":config.appearance_id;
   PresentActor(actor,0);
  }
  public bool ContinueCampaign()
  {
   if(Campaign==null||!Campaign.State.AwaitingReward||Frozen||paused||Durability<=0||board.Busy)return false;
   if(!string.IsNullOrEmpty(Campaign.Current.chapter_reward)&&!BossRewardCommitted){
    if(Gate==ChapterGate.NodeComplete){SetGate(ChapterGate.CrystalReward);return true;}
    return false;
   }
   bool acknowledged=Gate!=ChapterGate.None;SetGate(ChapterGate.None);if(WaitingForEnergyChoice)return acknowledged;
   Campaign.Continue(new System.Random(1902+Campaign.State.Index));
   if(Campaign.Current.continuation||checkpointNode!=Campaign.Current.node_id){checkpoint=CaptureCampaign();checkpointNode=Campaign.Current.node_id;}
   PersistRequested?.Invoke();
   return true;
  }
  void PresentActor(Actor a,float delta)
  {
   if(!a.Status){var go=new GameObject("MonsterStatus");go.transform.SetParent(layer,false);a.Status=go.AddComponent<MonsterStatusView>();a.Status.Setup();}
   a.Status.Refresh(a.Model,path.At(a.Model.Progress),a.Size);
   a.SpawnAge+=delta;
   float scale=MonsterPresentation.SpawnScale(a.SpawnAge);
   float zoom=bossSprites.ContainsKey(a.Model)?1:a.Tier==1?2.28f:a.Tier==2?1.76f:1.70f;
   var p=path.At(a.Model.Progress);
   // Source spawn pivot is at the body's bottom center, not sprite-canvas center.
   a.Body.transform.localPosition=LayoutMapper.World(p+new Vector2(0,a.Size*.5f*(1-scale)));
   M1Art.SetSize(a.Body,Vector2.one*(a.Size*zoom*scale));
   a.Bar.transform.localPosition=LayoutMapper.World(p+new Vector2(0,a.Size*.5f+8*scale));
   a.RecoilAge+=delta;
   if(a.Model.Stun>a.PreviousStun+.025f)a.StunAge=0;
   a.PreviousStun=(float)a.Model.Stun;
   var offset=Vector2.zero;
   if(a.Model.Alive&&a.Model.Stun>0){
    a.StunAge+=delta;float t=a.StunAge;
    offset=new Vector2(Mathf.Sin(t*91)*4.8f+Mathf.Cos(t*137)*1.4f,-9+Mathf.Sin(t*117)*3.2f);
    a.Body.sharedMaterial=lightningMaterial;a.Block.SetFloat("_White",((int)(t/.065f)%2)==0?1:0);a.Body.SetPropertyBlock(a.Block);
   }else{a.Body.sharedMaterial=material;a.Body.SetPropertyBlock(null);}
   if(a.Model.Alive&&a.RecoilAge<.185f){
    float t=a.RecoilAge,strength;
    if(t<=.055f)strength=1-Mathf.Pow(1-t/.055f,3);
    else{float x=Mathf.Clamp01((t-.055f)/.13f);strength=1-x*x*(3-2*x);}
    offset+=a.RecoilDirection*(9*strength);
   }
   a.Recovery.Tick(delta,a.Model.Alive,a.Model.Stun>0,a.StunAge,offset,a.RecoilAge<.185f);
   var pivot=LayoutMapper.World(p);var rotation=Quaternion.Euler(0,0,-a.Recovery.Angle*Mathf.Rad2Deg);
   foreach(var view in new[]{a.Body.transform,a.Bar.transform,a.Status.transform}){
    view.localPosition=pivot+rotation*(view.localPosition-pivot)+LayoutMapper.World(a.Recovery.Offset);
    view.localRotation=rotation;
   }
   M1Art.SetSize(a.Bar,new Vector2(54*(float)(a.Model.Hp/a.Model.MaxHp)*scale,5*scale));
   if(!a.Model.Alive)
   {
    a.DeathAge=a.DeathAge<0?0:a.DeathAge+delta;
    a.Bar.enabled=false;a.Body.color=Color.white;
    if(!a.Model.Reached)a.Body.sprite=art["death"+MonsterPresentation.DeathFrame(a.DeathAge,a.Model.Annihilated)];
    a.Body.enabled=a.DeathAge<(a.Model.Reached?.22f:MonsterPresentation.DeathDuration(a.Model.Annihilated));
   }
  }
  public void ContinueWave()
  {
   if(Waves==null||Frozen||paused||Durability<=0||board.Busy)return;
   Waves.Continue(new System.Random(1902+Waves.Index));
  }
  void CancelCrystal()
  {
   crystalSerial++;crystalInFlight=false;crystalTarget=null;
   if(crystalBolt){crystalBolt.gameObject.SetActive(false);Destroy(crystalBolt.gameObject);}crystalBolt=null;
   if(crystal)crystal.color=Color.white;
  }
  void TickCrystal(float delta)
  {
   if(ChapterCrystal!=null&&!ChapterCrystal.State.Awakened)return;
   crystalTimer-=delta;if(crystalTimer>0)return;crystalTimer=ChapterCrystal==null?1.8:ChapterCrystal.Interval;
   if(crystalInFlight)return;
   if(crystalTarget==null||!crystalTarget.Model.Alive)crystalTarget=actors.Where(a=>a.Model.Alive).OrderByDescending(a=>a.Model.Progress).FirstOrDefault();
   if(crystalTarget==null)return;crystalInFlight=true;StartCoroutine(CrystalShot(crystalTarget,crystalSerial));
  }
  IEnumerator CrystalShot(Actor target,int token)
  {
   double damage=ChapterCrystal==null?1:ChapterCrystal.Damage;
   crystal.color=new Color(.65f,1,1);
   yield return new WaitForSeconds(.35f);
   if(token!=crystalSerial)yield break;
   if(!target.Model.Alive){CancelCrystal();yield break;}
   crystal.color=Color.white;
   crystalBolt=Make("CrystalBolt","projectile_crystal",CrystalOrigin,Vector2.one*30,210);
   float age=0;
   while(age<.18f&&token==crystalSerial)
   {
    if(!target.Model.Alive){CancelCrystal();yield break;}
    crystalBolt.transform.localPosition=LayoutMapper.World(Vector2.Lerp(CrystalOrigin,path.At(target.Model.Progress),age/.18f));
    yield return null;age+=Time.deltaTime;
   }
   if(token!=crystalSerial)yield break;
   if(crystalBolt)Destroy(crystalBolt.gameObject);crystalBolt=null;
   if(!Frozen&&Durability>0&&target.Model.Alive){
    target.Model.Damage(damage);CrystalHits++;Impacts.Play("crystal",path.At(target.Model.Progress)+new Vector2(0,5),1);
    if(ChapterCrystal!=null&&target.Model.Alive){
     ApplyCrystalElements(target,damage);
     var followers=actors.Where(a=>a.Model.Alive).OrderByDescending(a=>a.Model.Progress).Skip(1).Where(a=>a!=target).Take(ChapterCrystal.State.PierceTargets).ToArray();
     foreach(var follower in followers)StartCoroutine(SecondaryCrystalShot(follower,damage*ChapterCrystal.State.PierceRatio,token));
    }
   }
   crystalInFlight=false;if(!target.Model.Alive)CancelCrystal();
  }
  void ApplyCrystalElements(Actor actor,double damage){
   ChapterCrystal.ApplyInstalled(actor.Model,damage);string[] keys={"fire","ice","poison","lightning"};
   for(int i=0;i<4;i++)if(ChapterCrystal.State.Elements[i]>0)Impacts.Play(keys[i],path.At(actor.Model.Progress)+new Vector2(0,5),ChapterCrystal.State.Elements[i]);
  }
  IEnumerator SecondaryCrystalShot(Actor actor,double damage,int serial){
   yield return new WaitForSeconds(.14f);
   while(Frozen&&serial==crystalSerial)yield return null;
   if(serial!=crystalSerial||!actor.Model.Alive||Durability<=0||ChapterCrystal==null)yield break;
   actor.Model.Damage(damage);if(actor.Model.Alive)ApplyCrystalElements(actor,damage);
   Impacts.Play("crystal",path.At(actor.Model.Progress)+new Vector2(0,5),ChapterCrystal.State.Level);
  }
  void Update()
  {
   if(!Ready)return;
   if(NavigationSuspended){board.InputBlocked=true;return;}
   projectiles.RemoveAll(p=>!p);
   clock.Advance(Time.realtimeSinceStartupAsDouble,Time.deltaTime,paused,Frozen||Durability<=0||Gate!=ChapterGate.None);
   if(!paused&&!Frozen&&Durability>0&&Gate==ChapterGate.None)
    for(int i=actors.Count-1;i>=0;i--)
    {
     var a=actors[i];a.Model.Tick(Time.deltaTime,path);
     if(a.Model.Reached&&!a.Leaked){a.Leaked=true;RunLeaks++;Durability=Math.Max(0,Durability-a.LeakDamage);}
    }
   foreach(var a in actors)
   {
    if(Campaign!=null&&!a.Model.Alive&&!a.Model.Reached&&recordedKills.Add(a.Model)){RunKills++;Meta.RecordKill();GainEnergy(5,path.At(a.Model.Progress),1,true);}
    a.WalkAge+=Time.deltaTime;a.HitAge+=Time.deltaTime;
    a.Body.sprite=a.Tier>1?art["slime"+a.Tier]:a.HitAge<8f/24?art["hit"+Mathf.Min(7,(int)(a.HitAge*24))]:art["walk"+((int)(a.WalkAge*24)%18)];
    if(bossSprites.TryGetValue(a.Model,out var bossSprite))a.Body.sprite=bossSprite;
    a.Body.enabled=a.Model.Alive;a.Bar.enabled=a.Model.Alive;
    var p=path.At(a.Model.Progress);a.Body.transform.localPosition=LayoutMapper.World(p);
    a.Bar.transform.localPosition=LayoutMapper.World(p+new Vector2(0,a.Size*.5f+8));
    M1Art.SetSize(a.Bar,new Vector2(54*(float)(a.Model.Hp/a.Model.MaxHp),5));
    a.Bar.color=Color.green;a.Flash=Mathf.Max(0,a.Flash-Time.deltaTime);
    a.Body.color=a.Flash>0?new Color(1,.32f,.32f):a.Model.Ice>0?new Color(.42f,.73f,1):Color.white;
    PresentActor(a,Time.deltaTime);
   }
   board.InputBlocked=paused||demonstrating||Durability<=0||Gate!=ChapterGate.None||(Waves!=null&&Waves.Completed)||(Campaign!=null&&(Campaign.State.Completed||Campaign.State.AwaitingReward));
   if(Campaign!=null&&!paused&&!Frozen&&Durability>0&&Gate==ChapterGate.None){
    if(Campaign.State.AwaitingReward&&!board.Busy)ContinueCampaign();
    Campaign.Tick(Time.deltaTime,false,AliveCount==0);
    if(Campaign.State.Running)TickCrystal(Time.deltaTime);
   }
   if(Waves!=null&&!paused&&!Frozen&&Durability>0)
   {
    Waves.Tick(Time.deltaTime,false,AliveCount==0);
    if(!Waves.Completed)TickCrystal(Time.deltaTime);
   }
   if(Durability<=0&&crystalInFlight)CancelCrystal();
   if(Campaign!=null&&Gate==ChapterGate.None&&!board.Busy&&!Frozen&&(Durability<=0||!board.HasMatch)){
    defeatSnapshot=CaptureCampaign();CancelCrystal();SetGate(ChapterGate.Defeat);
   }
   for(int i=actors.Count-1;i>=0;i--)if(!actors[i].Model.Alive&&actors[i].DeathAge>=(actors[i].Model.Reached?.22f:MonsterPresentation.DeathDuration(actors[i].Model.Annihilated)))
   {bossSprites.Remove(actors[i].Model);if(actors[i].Status)Destroy(actors[i].Status.gameObject);Destroy(actors[i].Body.gameObject);Destroy(actors[i].Bar.gameObject);actors.RemoveAt(i);}
  }
  public void BeginSettlement(){if(crystalInFlight)crystalTimer=0;CancelCrystal();Frozen=true;preview.Clear();ClearSlots();}
  public void RecordMerge(MergeAttack attack)
  {
   if(CampaignMode){Meta.RecordMerge();Run.RecordMerge(attack.MergeCount);}
   preview.Add(attack);
   if(!slots.ContainsKey(attack.ElementKey))
    slots[attack.ElementKey]=Make("Slot_"+attack.ElementKey,"icon_"+attack.ElementKey,
       LayoutMapper.BoardToDesign(Slot[attack.ElementKey]*633),Vector2.one*(633*.14f*.95f),200);
   Diagram.Bind(attack.ElementKey,slots[attack.ElementKey]);
   Diagram.Refresh(preview.GroupBy(a=>a.ElementKey).ToDictionary(g=>g.Key,g=>g.Count()),Slot);
  }
  public IEnumerator PlaySkillStrike(ImprintStrike strike,Vector2 origin)
  {
   int token=generation;var targets=actors.Where(a=>a.Model.Alive).OrderByDescending(a=>a.Model.Progress).Take(strike.Targets).ToArray();
   var launched=new bool[targets.Length];var hit=new bool[targets.Length];double started=clock.AttackTime;int remaining=targets.Length;
   while(token==generation&&remaining>0){
    for(int i=0;i<targets.Length;i++){
     double offset=i==0?0:i==targets.Length-1?(targets.Length-2)*.07+.20:i*.07;
     var actor=targets[i];
     if(!launched[i]&&clock.AttackTime-started>=offset){
      launched[i]=true;
      if(actor.Model.Alive){var bolt=Make("ImprintBolt_"+strike.Element,"projectile_"+strike.Element,origin,Vector2.one*36,210);projectiles.Add(bolt.gameObject);
       bolt.gameObject.AddComponent<ElementFlightVisual>().Setup(strike.Element,LayoutMapper.World(origin),()=>actor.Model.Alive?(Vector3?)LayoutMapper.World(path.At(actor.Model.Progress)+new Vector2(0,5)):null);}
     }
     if(!hit[i]&&clock.AttackTime-started>=offset+.14){
      hit[i]=true;remaining--;
      if(!actor.Model.Alive)continue;
      if(strike.Element=="critical"&&!actor.Model.Immune&&random.NextDouble()<.05){DamageNumbers.PlayAnnihilation(path.At(actor.Model.Progress)+new Vector2(0,5));actor.Model.Annihilate();}
      else{double damage=strike.Damage*(strike.Element=="critical"&&random.NextDouble()<.25?2:1);actor.Model.Damage(damage);
       if(actor.Model.Alive&&strike.BurnDuration>0)actor.Model.AddStatusLayer(false,new BattleMonster.Layer{Remaining=strike.BurnDuration,Power=strike.Damage*strike.BurnRatio});}
      Impacts.Play(strike.Element,path.At(actor.Model.Progress)+new Vector2(0,5),1);
     }
    }
    if(remaining>0)yield return null;
   }
  }
  IEnumerator WaitAttack(double duration)
  {double start=clock.AttackTime;while(clock.AttackTime-start<duration)yield return null;}
  public void FenceEditorPause(){if(Ready)clock.Advance(Time.realtimeSinceStartupAsDouble,0,true,Frozen);}
  public IEnumerator CompleteBatch(MergeAttackBatch batch)
  {
   int token=generation;
   yield return WaitAttack(Math.Max(0,batch.Events.Count-1)*.08+.14);
   if(token!=generation)yield break;
   Diagram.BeginBurst();
   foreach(var attack in batch.Events)
   {
    if(token!=generation||AliveCount==0)break;
    pending++;StartCoroutine(Shot(attack,batch.ComboMultiplier,token));
    yield return WaitAttack(.15);
   }
   while(token==generation&&pending>0)yield return null;
   if(token!=generation)yield break;
   foreach(var slot in slots.Values)slot.transform.SetParent(Diagram.transform,true);
   slots.Clear();Diagram.Finish();projectiles.Add(Diagram.gameObject);
   var next=new GameObject("ResonanceDiagram");next.transform.SetParent(layer,false);
   Diagram=next.AddComponent<ResonanceDiagram>();Diagram.Setup();
  }
  IEnumerator Shot(MergeAttack attack,double multiplier,int token)
  {
   Diagram.Pulse(attack.ElementKey);
   var chosen=actors.Where(a=>a.Model.Alive).OrderByDescending(a=>a.Model.Progress)
    .Take(attack.Element==AttackElement.Ice?attack.TargetCount:1).ToArray();
   var bolts=new List<SpriteRenderer>();
   // Read the visible slot transform at launch, not the original merged block position.
   Vector3 origin=slots[attack.ElementKey].transform.localPosition;
   foreach(var a in chosen)
   {
    var bolt=Make("Bolt_"+attack.ElementKey,"projectile_"+attack.ElementKey,Vector2.zero,new Vector2(36,36),210);
    bolt.transform.localPosition=origin;bolts.Add(bolt);projectiles.Add(bolt.gameObject);
    bolt.gameObject.AddComponent<ElementFlightVisual>().Setup(attack.ElementKey,origin,()=>{
     var target=attack.Element==AttackElement.Lightning?a:Retarget(a);return target==null?(Vector3?)null:LayoutMapper.World(path.At(target.Model.Progress)+new Vector2(0,5));
    });
   }
   LaunchCount++;Launched?.Invoke(attack.ElementKey,clock.AttackTime);
   double start=clock.AttackTime;
   while(token==generation&&clock.AttackTime-start<.14)
   {
    yield return null;
   }
   // Visuals retain their authored frame-time tail/beam lifetime after wall-time damage.
   if(token!=generation)yield break;
   var targets=chosen.Select(Retarget).Where(a=>a!=null).Distinct().ToList();
   if(targets.Count>0)
   {
    foreach(var a in actors.Where(a=>a.Model.Alive))if(!targets.Contains(a))targets.Add(a);
    ApplyHit(attack,multiplier,targets);
    int soundCount=attack.Element==AttackElement.Ice?Math.Max(1,attack.TargetCount):Math.Max(1,attack.AttackCount);
    for(int index=0;index<soundCount;index++)HitAudio.Play(index,soundCount,!targets[0].Model.Alive&&index==soundCount-1);
    HitCount++;Resolved?.Invoke(attack.ElementKey,clock.AttackTime);
    if(TraceHits)Debug.Log("[M2 HIT] "+attack.ElementKey+" time="+clock.AttackTime.ToString("F3")+" alive="+AliveCount);
   }
   pending--;
  }
  Actor Retarget(Actor original)=>original.Model.Alive?original:actors.Where(a=>a.Model.Alive).OrderByDescending(a=>a.Model.Progress).FirstOrDefault();
  void ApplyHit(MergeAttack attack,double multiplier,List<Actor> targets)
  {
   var damage=new Dictionary<Actor,double>();var statuses=new List<Actor>();var primary=targets[0];
   void Add(Actor target,double amount){damage[target]=amount;statuses.Add(target);}
   if(attack.Element==AttackElement.Ice)
   {
    for(int i=0;i<Math.Min(targets.Count,attack.TargetCount);i++)Add(targets[i],attack.IceDamageForTarget(i)*multiplier);
   }
   else
   {
    double amount=attack.ResolvePrimaryDamage(()=>random.NextDouble())*multiplier;
    bool annihilate=false;
    if(attack.Element==AttackElement.Critical&&!primary.Model.Immune)
     foreach(var part in attack.Contributions)annihilate=(random.NextDouble()<part.Effects["annihilation_chance"])||annihilate;
    if(annihilate){DamageNumbers.PlayAnnihilation(path.At(primary.Model.Progress)+new Vector2(0,5));primary.Model.Annihilate();}
    Add(primary,annihilate?0:amount);
    if(attack.Element==AttackElement.Fire)
    {
     double splash=attack.Contributions.Sum(p=>p.Damage*p.AttackCount*p.Effects["splash_damage_ratio"])*multiplier;
     foreach(var a in targets.Skip(1))if(Vector2.Distance(path.At(a.Model.Progress),path.At(primary.Model.Progress))<=attack.Effects["splash_radius"])Add(a,splash);
    }
    if(attack.Element==AttackElement.Lightning)
    {
     double hop=attack.Damage*multiplier;
     for(int i=1;i<Math.Min(targets.Count,attack.Effects["chain_count"]+1);i++){
      var source=targets[i-1];var next=targets[i];
      var link=Make("LightningLink","projectile_lightning",Vector2.zero,Vector2.one*120,210);projectiles.Add(link.gameObject);
      link.gameObject.AddComponent<ElementFlightVisual>().Setup("lightning",LayoutMapper.World(path.At(source.Model.Progress)+new Vector2(0,5)),
       ()=>LayoutMapper.World(path.At(next.Model.Progress)+new Vector2(0,5)),
       ()=>LayoutMapper.World(path.At(source.Model.Progress)+new Vector2(0,5)));
      hop*=attack.Effects["chain_damage_ratio"];Add(next,hop);
     }
    }
   }
   foreach(var pair in damage)pair.Key.Model.Damage(pair.Value);
   foreach(var a in statuses)if(a.Model.Alive&&(attack.Element==AttackElement.Fire||attack.Element==AttackElement.Critical)){
    a.RecoilAge=0;a.RecoilDirection=(path.At(a.Model.Progress)-LayoutMapper.BoardToDesign(Slot[attack.ElementKey]*633)).normalized;
    if(a.RecoilDirection.sqrMagnitude<.001f)a.RecoilDirection=Vector2.down;
   }
   // Godot control center is 5px below the road anchor; elemental hit adds -10px.
   foreach(var a in statuses)Impacts.Play(attack.ElementKey,path.At(a.Model.Progress)+new Vector2(0,-5),attack.Tier);
   foreach(var a in statuses)if(a.Model.Alive)
    foreach(var part in attack.Contributions)
     for(int i=0;i<(part.Element==AttackElement.Poison||part.Element==AttackElement.Fire?part.AttackCount:1);i++)a.Model.Apply(part);
  }
  void ClearSlots(){if(Diagram)Diagram.Clear();foreach(var r in slots.Values)if(r){r.gameObject.SetActive(false);Destroy(r.gameObject);}slots.Clear();}
  public void EndSettlement(){Frozen=false;}
  public void CancelSettlement()
  {
   generation++;StopAllCoroutines();pending=0;Frozen=false;demonstrating=false;preview.Clear();ClearSlots();
   if(Impacts)Impacts.Clear();
   if(DamageNumbers)DamageNumbers.Clear();
   if(HitAudio)HitAudio.Clear();
   CancelCrystal();
   foreach(var p in projectiles)if(p){p.SetActive(false);Destroy(p);}projectiles.Clear();
  }
  public void PreviewFiveElements()
  {
   if(!Ready||board.Busy||demonstrating||paused||Durability<=0||(Waves!=null&&Waves.Completed))return;
   demonstrating=true;board.InputBlocked=true;BeginSettlement();
   foreach(int source in new[]{1,2,3,4,5})RecordMerge(new MergeAttack(source,source+1,3));
   StartCoroutine(Demonstrate(new MergeAttackBatch(preview)));
  }
  public void PreviewFlightReview()
  {
   int i=0;
   foreach(var key in new[]{"poison","ice","critical","fire","lightning"}){
    var start=LayoutMapper.World(new Vector2(120,300+i*80));var end=LayoutMapper.World(new Vector2(820,300+i*80));i++;
    var bolt=Make("FlightReview_"+key,"projectile_"+key,Vector2.zero,Vector2.one*70,210);projectiles.Add(bolt.gameObject);
    bolt.gameObject.AddComponent<ElementFlightVisual>().Setup(key,start,()=>end);
   }
  }
  IEnumerator Demonstrate(MergeAttackBatch batch){yield return CompleteBatch(batch);EndSettlement();demonstrating=false;board.InputBlocked=false;}
  void OnGUI()
  {
   if(!ShowDebugPanel)return;
   if(!Ready)return;
   if(Campaign!=null){
    GUI.Box(new Rect(8,155,360,92),"CHAPTER INTEGRATION / FORMAL UI PENDING");
    GUI.Label(new Rect(18,178,330,24),"Wave "+(Campaign.State.Index+1)+"/32  "+Campaign.Current.id);
    if(Campaign.State.AwaitingReward&&GUI.Button(new Rect(18,209,330,24),Gate==ChapterGate.CrystalReward&&!BossRewardCommitted?"Reward UI pending / progression locked":"Debug continue"))ContinueCampaign();
   }
   GUI.Box(new Rect(8,8,360,140),WaveMode?"M2 BASELINE WAVES / REWARDS PENDING":"M2 COMBAT FIXTURE / NOT FULL GAME");
   GUI.Label(new Rect(18,32,340,24),"HP "+Durability+"/20  Alive "+AliveCount+"  Frozen "+Frozen+"  Time "+CombatSeconds.ToString("F1"));
   if(GUI.Button(new Rect(18,58,105,24),"Reset fixture"))ResetFixture();
   if(GUI.Button(new Rect(130,58,105,24),paused?"Resume":"Pause")){paused=!paused;Time.timeScale=paused?0:previousScale;HitAudio.Pause(paused);board.InputBlocked=paused||demonstrating;}
   if(GUI.Button(new Rect(242,58,112,24),"Five elements"))PreviewFiveElements();
   GUI.Label(new Rect(18,87,340,24),Waves==null?"Fixture: no waves/crystal auto.":"Wave "+(Waves.Index+1)+"/20  Queue "+Waves.Remaining+"  Crystal hits "+CrystalHits);
   if(Waves!=null&&Waves.AwaitingReward&&GUI.Button(new Rect(18,113,240,24),"Continue wave (reward UI pending)"))ContinueWave();
   if(Waves!=null&&Waves.Completed)GUI.Label(new Rect(18,113,240,24),"All 20 baseline waves cleared.");
  }
  void OnDisable()
  {
   if(!Ready)return;
   CancelSettlement();if(board){board.ResetBoard(false);board.CombatSink=null;board.InputBlocked=true;}Time.timeScale=previousScale;
  }
  void OnEnable(){if(Ready&&board){board.CombatSink=this;ResetFixture();}}
  void OnDestroy()
  {
   Time.timeScale=previousScale;
   if(layer)Destroy(layer.gameObject);foreach(var sprite in art.Values)if(sprite)Destroy(sprite);
   if(material)Destroy(material);if(white)Destroy(white);if(whiteTexture)Destroy(whiteTexture);
   if(lightningMaterial)Destroy(lightningMaterial);
  }
 }
}
