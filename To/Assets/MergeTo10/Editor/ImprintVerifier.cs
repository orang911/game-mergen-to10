using System;
using System.Linq;
using MergeTo10.Core;
namespace MergeTo10.Editor
{
 public static class ImprintVerifier {
  static void Check(bool value,string label){if(!value)throw new Exception("Imprint: "+label);}
  public static void Verify(){
   var run=new RunProgress();run.RecordMerge(3);run.RecordMerge(5);run.RecordCard("ascension_hammer",1);run.RecordCard("unity_dial",2);run.RecordCard("ascension_hammer",3);
   var restored=run.Copy();restored.Validate();Check(restored.Merges==2&&restored.MaxMerge==5&&restored.Cards[0].Id=="ascension_hammer"&&restored.Cards[0].Level==3&&restored.Cards[0].Selections==2&&restored.Cards[1].Id=="unity_dial","run counters, selection order and repeats persist");
   var board=new BoardModel();var values=Enumerable.Repeat(1,25).ToArray();values[12]=4;board.Load(values,4);var root=board.At(2,2);
   ImprintRules.Apply(board,root,"ascension_hammer",4,3,new Random(1));Check(root.Level==6&&board.Highest==6&&board.Score==0,"hammer extra levels without extra merge score");
   values[0]=8;board.Load(values,8);root=board.At(2,2);ImprintRules.Apply(board,root,"unity_dial",1,2,new Random(1));
   Check(board.At(0,0).Level==8&&root.Level==4&&board.At(1,0).Level==2,"dial retains maxima and uses recorded source level");
   board.Load(values,8);root=board.At(2,2);root.Level=9;
   ImprintRules.Apply(board,root,"twin_mold",5,3,new Random(1));Check(board.At(2,1).Level==9&&board.At(3,2).Level==9,"twin ties preserve neighbor order");
   board.Load(values,8);root=board.At(2,2);var ids=board.Cells.Select(c=>c.Id).OrderBy(v=>v).ToArray();var levels=board.Values().OrderBy(v=>v).ToArray();
   ImprintRules.Apply(board,root,"fate_shuffler",1,3,new Random(3));
   Check(board.HasMove()&&ids.SequenceEqual(board.Cells.Select(c=>c.Id).OrderBy(v=>v))&&levels.SequenceEqual(board.Values().OrderBy(v=>v)),"shuffle preserves identity and values with match");
   root.Level=6;var cannon=ImprintRules.Apply(board,root,"castle_cannon",5,3,new Random(1));
   Check(cannon.Targets==1&&Math.Abs(cannon.Damage-50.4)<1e-8,"cannon source damage");
   var dragon=ImprintRules.Apply(board,root,"dragon_catapult",5,3,new Random(1));
   Check(dragon.Targets==4&&Math.Abs(dragon.Damage-19.8)<1e-8&&dragon.BurnDuration==3&&dragon.BurnRatio==.22,"dragon source targets and burn");
  }
 }
}
