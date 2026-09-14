using System;
using System.Linq;
using System.Globalization;
using UnityEngine;
namespace MergeTo10.Core
{
 [Serializable] public sealed class MetaState {
  public bool Music=true,Sound=true,Vibration,ActivityClaimed,DoubleCoin,RemoveAds,FirstPurchase;
  public int Coins,Crystals,Piggy,SignStreak;
  public string Day="",SignDay="";
  public int[] TaskProgress=new int[4],Levels=new int[12],Fragments=new int[12],Purchases=new int[17];
  public bool[] TaskClaimed=new bool[4];
  public bool[] SeenCards=new bool[12];
 }
 public readonly struct MetaReward {
  public readonly int Coins,Crystals;
  public MetaReward(int coins,int crystals=0){Coins=coins;Crystals=crystals;}
 }
 // Rules ported from frozen scripts/meta_progress_service.gd. Real-money calls
 // require an explicitly injected local simulator; this service never charges money.
 public sealed class MetaProgress {
  public static readonly string[] Cards={"ascension_hammer","unity_dial","fate_shuffler","twin_mold","castle_cannon","dragon_catapult","fire_conduit","poison_tank","star_boiler","rapid_clockwork","twin_lens","piercing_cannon"};
  public static readonly string[] Tasks={"settle_once","merge_20","kill_30","login"};
  static readonly int[] Targets={1,20,30,1},Activity={20,20,30,30};
  static readonly MetaReward[] TaskRewards={new MetaReward(0,10),new MetaReward(30),new MetaReward(50),new MetaReward(0,20)};
  static readonly MetaReward[] SignRewards={new MetaReward(0,20),new MetaReward(30),new MetaReward(0,20),new MetaReward(50),new MetaReward(0,20),new MetaReward(30),new MetaReward(100)};
  public MetaState State{get;private set;}=new MetaState();
  public event Action Changed;
  public Func<string,bool> LocalPurchase;
  static bool Date(string value,out DateTime date)=>DateTime.TryParseExact(value,"yyyy-MM-dd",CultureInfo.InvariantCulture,DateTimeStyles.None,out date);
  public bool SyncDay(string day){
   if(!Date(day,out var next))return false;
   if(Date(State.Day,out var previous)&&next<previous)return false;
   if(State.Day!=day){State.Day=day;Array.Clear(State.TaskProgress,0,4);Array.Clear(State.TaskClaimed,0,4);Array.Clear(State.Purchases,0,17);State.ActivityClaimed=false;}
   State.TaskProgress[3]=1;Changed?.Invoke();return true;
  }
  public void RecordMerge()=>Record(1,1);
  public void RecordKill()=>Record(2,1);
  public void RecordSettlement(int baseCoins){State.Piggy=Math.Min(1000,State.Piggy+Math.Max(0,(int)Math.Floor(baseCoins*.2)));Record(0,1);}
  void Record(int index,int amount){State.TaskProgress[index]=Math.Min(Targets[index],State.TaskProgress[index]+amount);Changed?.Invoke();}
  public bool CanClaimTask(int index)=>index>=0&&index<4&&!State.TaskClaimed[index]&&State.TaskProgress[index]>=Targets[index];
  public bool ClaimTask(int index){if(!CanClaimTask(index))return false;State.TaskClaimed[index]=true;Grant(TaskRewards[index]);return true;}
  public int ActivityPoints=>Enumerable.Range(0,4).Where(i=>State.TaskClaimed[i]).Sum(i=>Activity[i]);
  public bool ClaimActivity(){if(State.ActivityClaimed||ActivityPoints<100)return false;State.ActivityClaimed=true;Grant(new MetaReward(100));return true;}
  public bool SignAvailable=>State.Day.Length>0&&State.SignDay!=State.Day;
  public int SignPreview{
   get{if(State.Day.Length>0&&State.SignDay==State.Day)return Math.Max(1,Math.Min(7,State.SignStreak));
    return Date(State.SignDay,out var previous)&&Date(State.Day,out var next)&&(next-previous).Days==1?State.SignStreak%7+1:1;}
  }
  public bool ClaimSign(){if(!SignAvailable)return false;State.SignStreak=SignPreview;State.SignDay=State.Day;Grant(SignRewards[State.SignStreak-1]);return true;}
  public void Grant(MetaReward reward){State.Coins+=Math.Max(0,reward.Coins);State.Crystals+=Math.Max(0,reward.Crystals);Changed?.Invoke();}
  public void GrantFragments(string card,int amount){
   int i=Array.IndexOf(Cards,card);if(i<0)return;
   int count=Math.Max(0,State.Fragments[i]+amount),level=Math.Max(0,Math.Min(5,State.Levels[i]));
   while(count>=10&&level<5){count-=10;level++;}
   if(level==5&&count>0){State.Coins+=count*20;count=0;}
   State.Levels[i]=level;State.Fragments[i]=count;Changed?.Invoke();
  }
  public string Purchase(string id){
   if(id=="double_coin"||id=="remove_ads")id="benefits_bundle";
   int slot=-1,limit=0,cost=0,fragment=-1;bool real=false;MetaReward reward=default;
   switch(id){
    case "benefits_bundle":if(State.DoubleCoin&&State.RemoveAds)return "owned";real=true;break;
    case "first_purchase":if(State.FirstPurchase)return "owned";real=true;break;
    case "piggy_bank":if(State.Piggy<=0)return "empty";real=true;break;
    case "coins_10000":slot=0;limit=3;cost=200;reward=new MetaReward(10000);break;
    case "crystals_500":slot=1;limit=5;real=true;reward=new MetaReward(0,500);break;
    default:
     if(id!=null&&id.StartsWith("frag_imprint_",StringComparison.Ordinal)){
      fragment=Array.IndexOf(Cards,id.Substring(13));if(fragment<0||fragment>=6)return "missing";
      slot=8+fragment;limit=3;cost=250;
     }else if(id!=null&&id.StartsWith("frag_",StringComparison.Ordinal)){
      fragment=Array.IndexOf(Cards,id.Substring(5));if(fragment<6)return "missing";
      slot=2+fragment-6;limit=5;cost=fragment<=8?120:fragment==9?180:250;
     }else return "missing";
     break;
   }
   if(limit>0&&State.Purchases[slot]>=limit)return "limit";
   if(State.Crystals<cost)return "insufficient";
   if(real&&(LocalPurchase==null||!LocalPurchase(id)))return "payment_failed";
   State.Crystals-=cost;if(limit>0)State.Purchases[slot]++;
   // Mutate all ownership/reward fields before one notification/save boundary.
   if(id=="benefits_bundle"){State.DoubleCoin=true;State.RemoveAds=true;}
   if(id=="first_purchase"){State.FirstPurchase=true;reward=new MetaReward(30000,980);GrantFragmentsSilent(0,10);GrantFragmentsSilent(6,10);}
   if(id=="piggy_bank"){reward=new MetaReward(State.Piggy);State.Piggy=0;}
   if(fragment>=0)GrantFragmentsSilent(fragment,5);
   Grant(reward);return "ok";
  }
  void GrantFragmentsSilent(int index,int amount){
   int count=State.Fragments[index]+amount,level=State.Levels[index];
   while(count>=10&&level<5){count-=10;level++;}
   if(level==5&&count>0){State.Coins+=count*20;count=0;}
   State.Levels[index]=level;State.Fragments[index]=count;
  }
  public string Export()=>JsonUtility.ToJson(State);
  public void Restore(string json){
   var value=JsonUtility.FromJson<MetaState>(json);
   if(value==null||value.TaskProgress?.Length!=4||value.TaskClaimed?.Length!=4||value.Levels?.Length!=12||value.Fragments?.Length!=12||value.Purchases?.Length!=17)throw new ArgumentException("Invalid meta snapshot");
   if(value.Coins<0||value.Crystals<0||value.Piggy<0||value.Piggy>1000||value.SignStreak<0||value.SignStreak>7||value.Levels.Any(v=>v<0||v>5)||value.Fragments.Any(v=>v<0)||value.Purchases.Any(v=>v<0))throw new ArgumentException("Invalid meta values");
   value.Day=value.Day??"";value.SignDay=value.SignDay??"";if(value.SeenCards==null||value.SeenCards.Length!=12)value.SeenCards=new bool[12];State=value;Changed?.Invoke();
  }
 }
}
