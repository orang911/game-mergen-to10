using System;
using System.Collections.Generic;
namespace MergeTo10.Core
{
 public sealed class WaveFlow
 {
  public sealed class Spawn {public int Type,Tier;public double HpMultiplier;}
  readonly Queue<Spawn> queue=new Queue<Spawn>();
  public int Index{get;private set;}=-1;
  public int Total{get;private set;}
  public int Remaining=>queue.Count;
  public bool Spawning{get;private set;}
  public bool AwaitingReward{get;private set;}
  public bool Completed{get;private set;}
  public double Timer{get;private set;}
  double memberTimer,interval;int pattern,pending;
  public event Action<Spawn> Spawned;
  public static int[] Counts(int number)
  {
   int stage=(number-1)/5,total=(int)Math.Round(15+45*(number-1)/19.0,MidpointRounding.AwayFromZero);
   int small=5+number+stage,medium=Math.Max(0,(int)Math.Floor((number-2)/2.0)),large=Math.Max(0,(int)Math.Floor((number-4)/4.0));
   int sum=small+medium+large;
   int m=(int)Math.Round((double)total*medium/sum,MidpointRounding.AwayFromZero),l=(int)Math.Round((double)total*large/sum,MidpointRounding.AwayFromZero);
   return new[]{total-m-l,m,l};
  }
  public void Start(int index,Random random)
  {
   if(index<0||index>=20)throw new ArgumentOutOfRangeException(nameof(index));
   Index=index;Completed=false;AwaitingReward=false;Spawning=true;Timer=0;pattern=pending=0;memberTimer=0;
   spawnedThisTick=false;
   interval=Math.Max(.42,1.02-index*.025);queue.Clear();
   var items=new List<Spawn>();int[] counts=Counts(index+1);
   for(int type=0;type<3;type++)for(int i=0;i<counts[type];i++)items.Add(new Spawn{Type=type,Tier=1+index*3/20,HpMultiplier=3*Math.Pow(1.2,index)});
   for(int i=items.Count-1;i>0;i--){int j=random.Next(i+1);var item=items[i];items[i]=items[j];items[j]=item;}
   foreach(var item in items)queue.Enqueue(item);Total=queue.Count;
  }
  public void Tick(double delta,bool frozen,bool clear)
  {
   if(frozen||AwaitingReward||Completed||Index<0)return;
   spawnedThisTick=false;
   if(Spawning)
   {
    if(pending>0){memberTimer-=delta;if(memberTimer<=0)Emit();}
    else
    {
     Timer-=delta;
     if(Timer<=0){pending=Math.Min(pattern+1,queue.Count);pattern=(pattern+1)%4;Emit();}
    }
   }
   // A spawn makes clear=false even if this frame began with an empty monster list.
   if(!Spawning&&clear&&queue.Count==0&&pending==0)TryClear(clear);
  }
  bool spawnedThisTick;
  void Emit()
  {
   if(queue.Count==0){Spawning=false;return;}
   spawnedThisTick=true;Spawned?.Invoke(queue.Dequeue());pending--;
   if(pending>0)memberTimer=.08;
   else if(queue.Count==0)Spawning=false;
   else Timer=interval;
  }
  public void TryClear(bool clear)
  {
   if(spawnedThisTick){spawnedThisTick=false;return;}
   if(!clear||Spawning||AwaitingReward||Completed)return;
   if(Index==19)Completed=true;else AwaitingReward=true;
  }
  public void Continue(Random random){if(AwaitingReward)Start(Index+1,random);}
 }
}
