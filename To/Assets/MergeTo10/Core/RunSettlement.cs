using System;
namespace MergeTo10.Core
{
 [Serializable] public sealed class RunSettlement {
  public bool Won;public int Score,Kills,Leaks,Waves,Highest,Castle,BaseCoins,Coins,Crystals;public double Elapsed;
  public RunProgress Run;
  public static RunSettlement Calculate(bool won,int score,int kills,int leaks,int waves,int highest,int castle,double elapsed,bool doubleCoins){
   int basis=Math.Max(10,(int)Math.Floor(score/20.0)+kills*2+waves*10+(won?100:0));
   return new RunSettlement{Won=won,Score=score,Kills=kills,Leaks=leaks,Waves=waves,Highest=highest,Castle=castle,Elapsed=elapsed,
    BaseCoins=basis,Coins=basis*(doubleCoins?2:1),Crystals=Math.Max(1,waves+(won?16:0))};
  }
 }
}
