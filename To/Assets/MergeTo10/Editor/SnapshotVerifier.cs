using System;
using System.IO;
using MergeTo10.Core;
using UnityEngine;
namespace MergeTo10.Editor
{
 public static class SnapshotVerifier {
  static void Check(bool result,string label){if(!result)throw new Exception("Snapshot: "+label);}
  public static void Verify(){
   var board=new BoardModel();var cells=new int[25];for(int i=0;i<25;i++)cells[i]=1;
   board.Load(cells);board.Apply(board.Prepare(board.At(0,0),board.Group(board.At(0,0),false),0));
   var snapshot=board.Capture();var copy=new BoardModel();copy.Restore(snapshot);
   Check(copy.Score==board.Score&&copy.Highest==board.Highest&&JsonUtility.ToJson(copy.Capture())==JsonUtility.ToJson(snapshot),"board score and layout");
   snapshot.Values[0]=30;Check(copy.At(0,0).Level==2,"board independent copy");
   var monster=new BattleMonster(1000);monster.Apply(new MergeAttack(1,2,3));monster.Apply(new MergeAttack(5,6,3));
   var path=new BattlePath();monster.Tick(.37,path);
   var restored=BattleMonster.Restore(monster.Capture());
   Check(JsonUtility.ToJson(monster.Capture())==JsonUtility.ToJson(restored.Capture()),"monster status roundtrip");
   for(int i=0;i<200;i++){monster.Tick(.016,path);restored.Tick(.016,path);Check(Math.Abs(monster.Hp-restored.Hp)<1e-8&&Math.Abs(monster.Progress-restored.Progress)<1e-8,"restored status trajectory");}
   var bad=monster.Capture();bad.Hp=double.NaN;bool rejected=false;try{BattleMonster.Restore(bad);}catch(ArgumentException){rejected=true;}Check(rejected,"reject nonfinite hp");
   // Dedicated validation directory, never the user's save location. Retained as evidence.
   var output=Environment.GetEnvironmentVariable("M2_EDITOR_OUTPUT");
   string location=Path.Combine(output,"snapshot-tests",Guid.NewGuid().ToString("N"),"profile.json");
   var store=new ProfileStore(location);Check(store.Load(out _)==null,"missing is new profile");
   store.Save("{\"score\":1}");store.Save("{\"score\":2}");
   Check(store.Load(out var recovered)=="{\"score\":2}"&&!recovered,"latest atomic save");
   File.WriteAllText(location,"corrupt-test-fixture");
   Check(store.Load(out recovered)=="{\"score\":1}"&&recovered,"backup fallback");
   store.Save("{\"score\":3}");File.WriteAllText(location,"corrupt-test-fixture");
   Check(store.Load(out recovered)=="{\"score\":1}"&&recovered,"repair preserves valid backup");
  }
 }
}
