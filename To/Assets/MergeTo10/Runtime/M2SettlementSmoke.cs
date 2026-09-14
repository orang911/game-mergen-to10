using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using MergeTo10.Core;
using UnityEngine;
namespace MergeTo10.Runtime
{
 // Test double only: not a substitute for migrated monsters/projectiles.
 public sealed class M2SettlementSmoke:MonoBehaviour,IBoardCombatSink
 {
  M1BoardDemo board;bool frozen,waiting,release;int began,ended,cancelled,checks;
  readonly List<MergeAttack> recorded=new List<MergeAttack>();
  string output;
  void Start()
  {
   output=Environment.GetCommandLineArgs().First(a=>a.StartsWith("--capture-dir=")).Substring("--capture-dir=".Length);
   Directory.CreateDirectory(output);board=GetComponent<M1BoardDemo>();StartCoroutine(Guard());
  }
  IEnumerator Guard()
  {
   var test=Run();
   while(true)
   {
    bool next;
    try{next=test.MoveNext();}
    catch(Exception e){File.WriteAllText(Path.Combine(output,"m2-settlement-result.txt"),"FAIL "+e);Debug.LogException(e);Application.Quit(2);yield break;}
    if(!next)break;
    yield return test.Current;
   }
   File.WriteAllText(Path.Combine(output,"m2-settlement-result.txt"),"PASS assertions="+checks+" begin="+began+" end="+ended+" cancel="+cancelled+"; test combat sink only, not combat visuals.");
   Application.Quit(0);
  }
  void Check(bool ok,string message){checks++;if(!ok)throw new Exception(message);}
  IEnumerator Run()
  {
   while(board.Busy)yield return null;
   board.CombatSink=this;
   var isolated=Enumerable.Repeat(36,25).ToArray();isolated[0]=1;
   board.ResetBoard(false,isolated);
   Check(!board.TryMerge(0,0)&&!board.TryMerge(1,0)&&began==0,"invalid click must not begin freeze");
   board.ResetBoard(false);
   Check(board.TryMerge(2,1)&&frozen&&board.Busy,"valid merge freezes synchronously");
   double limit=Time.realtimeSinceStartupAsDouble+25;
   while(!waiting&&Time.realtimeSinceStartupAsDouble<limit)yield return null;
   Check(waiting,"batch must reach awaited combat sink");
   Check(board.Busy&&frozen&&ended==0,"board stays locked through combat wait");
   Check(recorded.Count>0&&recorded.Count<=5,"bounded raw chain");
   Check(board.LastAttackBatch.RawEvents.SequenceEqual(recorded),"immutable contribution identity");
   foreach(var attack in recorded)Check(attack.ResultLevel==attack.SourceLevel+1,"later chains must not mutate earlier levels");
   Check(!board.TryMerge(2,1),"cannot merge while attack completion waits");
   double delay=Time.realtimeSinceStartupAsDouble+.25;
   while(Time.realtimeSinceStartupAsDouble<delay)yield return null;
   Check(board.Busy&&frozen,"frame passage alone cannot release combat wait");
   release=true;limit=Time.realtimeSinceStartupAsDouble+5;
   while(board.Busy&&Time.realtimeSinceStartupAsDouble<limit)yield return null;
   Check(!board.Busy&&!frozen&&ended==1,"normal finish releases once");
   board.ResetBoard(false);Check(board.TryMerge(2,1),"second merge");
   yield return null;board.ResetBoard(false);
   Check(!frozen&&cancelled==1&&!board.Busy,"reset cancels active settlement");
   Check(board.TryMerge(2,1),"new settlement after cancellation");
   limit=Time.realtimeSinceStartupAsDouble+25;
   while(!waiting&&Time.realtimeSinceStartupAsDouble<limit)yield return null;
   Check(waiting,"third batch wait");
   board.ResetBoard(false);
   Check(!frozen&&!board.Busy&&cancelled==2&&ended==1,"reset during combat wait has no late finish");
   delay=Time.realtimeSinceStartupAsDouble+.3;
   while(Time.realtimeSinceStartupAsDouble<delay)yield return null;
   Check(ended==1&&board.LastAttackBatch==null,"cancelled coroutine cannot mutate reset state");
   board.CombatSink=null;
  }
  public void BeginSettlement(){Check(!frozen,"double freeze");began++;frozen=true;waiting=false;release=false;recorded.Clear();}
  public void RecordMerge(MergeAttack attack){Check(frozen,"record must remain frozen");recorded.Add(attack);}
  public IEnumerator CompleteBatch(MergeAttackBatch batch){waiting=true;while(!release)yield return null;}
  public void EndSettlement(){Check(frozen,"end without freeze");ended++;frozen=false;waiting=false;}
  public void CancelSettlement(){cancelled++;frozen=false;waiting=false;release=true;}
 }
}

