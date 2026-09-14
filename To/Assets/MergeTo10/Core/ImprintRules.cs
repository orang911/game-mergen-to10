using System;
using System.Linq;
namespace MergeTo10.Core
{
 public sealed class ImprintStrike {public string Element;public int Targets;public double Damage,BurnRatio,BurnDuration;}
 public static class ImprintRules {
  // Frozen main_game.gd and game_config.gd: apply once, after the complete attack batch.
  public static ImprintStrike Apply(BoardModel board,Cell root,string id,int quality,int recordedLevel,Random random){
   if(root==null||board.Find(root.Id)!=root) return null;
   int q=Math.Max(1,Math.Min(5,quality))-1;
   switch(id){
    case "ascension_hammer":root.Level=Math.Min(36,root.Level+(q>=3?2:1));break;
    case "unity_dial":
     int highest=board.Cells.Max(c=>c.Level);
     foreach(var c in board.Cells)if(c!=root&&c.Level<highest)c.Level=Math.Max(1,Math.Min(36,recordedLevel));break;
    case "twin_mold":
     var candidates=new[]{board.At(root.X,root.Y-1),board.At(root.X+1,root.Y),board.At(root.X,root.Y+1),board.At(root.X-1,root.Y)}.Where(c=>c!=null&&c!=root&&c.Level<36).ToArray();
     if(candidates.Length==0)candidates=board.Cells.Where(c=>c!=root&&c.Level<36).ToArray();
     foreach(var c in candidates.OrderBy(c=>c.Level).Take(q>=3?2:1))c.Level=root.Level;break;
    case "fate_shuffler":
     var order=board.Cells.OrderBy(c=>c.Y*5+c.X).ToArray();if(order.Length<2)break;
     for(int attempt=0;attempt<20;attempt++){
      for(int i=order.Length-1;i>0;i--){int j=random.Next(i+1);var temp=order[i];order[i]=order[j];order[j]=temp;}
      board.Rearrange(order);if(board.HasMove())break;
     }
     if(!board.HasMove())order[1].Level=order[0].Level;break;
    case "castle_cannon":return new ImprintStrike{Element="critical",Targets=1,Damage=MergeAttack.BaseAttack(root.Level)*new[]{1.60,1.90,2.20,2.50,2.80}[q]};
    case "dragon_catapult":return new ImprintStrike{Element="fire",Targets=new[]{2,2,3,3,4}[q],Damage=MergeAttack.BaseAttack(root.Level)*new[]{.70,.80,.90,1,1.10}[q],BurnRatio=new[]{.10,.13,.16,.19,.22}[q],BurnDuration=new[]{1.8,2.1,2.4,2.7,3.0}[q]};
    default:throw new ArgumentException("Unknown active imprint: "+id);
   }
   board.RecordResultHighest(root);return null;
  }
 }
}
