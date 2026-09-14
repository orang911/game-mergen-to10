using System;
using UnityEngine;
namespace MergeTo10.Core
{
 [Serializable] public sealed class SkillEnergyState {public int energy,quality;public string pending="";}
 public sealed class SkillEnergy {
  public static readonly string[] Ids={"ascension_hammer","unity_dial","fate_shuffler","twin_mold","castle_cannon","dragon_catapult"};
  public SkillEnergyState State{get;private set;}=new SkillEnergyState();
  bool pendingFx,requested;
  public bool HasPending=>!string.IsNullOrEmpty(State.pending);
  public bool ChoiceReady=>State.energy>=100&&!HasPending&&!pendingFx;
  public event Action<int> EnergyGained;public event Action ChoiceRequested;
  public int Add(int amount){
   if(amount<=0||State.energy>=100)return 0;
   int gained=Math.Min(amount,100-State.energy);State.energy+=gained;pendingFx=true;
   EnergyGained?.Invoke(gained);
   if(State.energy>=100&&!HasPending)requested=true;
   return gained;
  }
  public void FinishFx(){pendingFx=false;TryRequest();}
  public void RequestIfFull(){if(State.energy<100||HasPending)return;requested=true;TryRequest();}
  void TryRequest(){if(requested&&!pendingFx){requested=false;ChoiceRequested?.Invoke();}}
  public bool Choose(string id,int quality=1){
   if(HasPending||Array.IndexOf(Ids,id)<0)return false;
   State.pending=id;State.quality=Mathf.Clamp(quality,1,5);State.energy=0;requested=false;return true;
  }
  public SkillEnergyState Consume(){
   if(!HasPending)return null;
   var result=new SkillEnergyState{pending=State.pending,quality=State.quality};
   State.pending="";State.quality=0;if(State.energy>=100){requested=true;TryRequest();}return result;
  }
  public void Restore(SkillEnergyState state){
   if(state==null)throw new ArgumentNullException(nameof(state));
   if(!string.IsNullOrEmpty(state.pending)&&Array.IndexOf(Ids,state.pending)<0)throw new ArgumentException("Invalid pending imprint");
   State=JsonUtility.FromJson<SkillEnergyState>(JsonUtility.ToJson(state));
   State.energy=Mathf.Clamp(State.energy,0,100);pendingFx=requested=false;
  }
 }
}
