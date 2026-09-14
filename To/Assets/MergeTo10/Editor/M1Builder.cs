using System;
using System.IO;
using System.Linq;
using MergeTo10.Core;
using MergeTo10.Runtime;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.Build.Reporting;
using UnityEngine;
namespace MergeTo10.Editor
{
 public static class M1Builder
 {
  [Serializable] class Oracle {public Case[] cases;public Position[] cells;}
  [Serializable] class Case {public int highest,target;public int[] values;public double[] weights,scores;public Sample[] samples;}
  [Serializable] class Sample {public double roll;public int level;}
  [Serializable] class Position {public int x,y;public float[] local_position;}
  [Serializable] class FeedbackOracle {public FeedbackSample[] samples;}
  [Serializable] class FeedbackSample {public float age,delay,duration,progress,scale,opacity;}
  static int assertions;
  static void Check(bool condition,string description){assertions++;if(!condition)throw new Exception(description);}
  public static void Run()
  {
   try
   {
    string output=Environment.GetEnvironmentVariable("M1_OUTPUT");
    if(string.IsNullOrEmpty(output))throw new Exception("M1_OUTPUT must point to migration output directory");
    Directory.CreateDirectory(output);
    string combatOracle=Environment.GetEnvironmentVariable("M2_ORACLE");
    if(!string.IsNullOrEmpty(combatOracle))
     File.WriteAllText(Path.Combine(output,"m2-core-verification.txt"),M2CoreVerifier.Verify(combatOracle));
    var oracle=JsonUtility.FromJson<Oracle>(File.ReadAllText(Environment.GetEnvironmentVariable("M1_ORACLE")));
    foreach(var c in oracle.cases)
    {
     var a=BoardRefillPolicy.Analyze(c.highest,c.values,5,c.target);
     Check(a.Weights.Length==c.weights.Length,"weight length");
     for(int i=0;i<a.Weights.Length;i++)
     {Check(Math.Abs(a.Weights[i]-c.weights[i])<1e-10,"weight mismatch highest "+c.highest+" index "+i+" actual "+a.Weights[i]+" expected "+c.weights[i]);
      Check(Math.Abs(a.Scores[i]-c.scores[i])<1e-10,"score mismatch");}
     foreach(var s in c.samples)Check(BoardRefillPolicy.Sample(c.highest,c.values,5,c.target,s.roll)==s.level,"sample mismatch");
    }
    foreach(var p in oracle.cells)Check(Vector2.Distance(LayoutMapper.CellTopLeft(p.x,p.y),new Vector2(p.local_position[0],p.local_position[1]))<.001f,"cell position");
    foreach(var size in new[]{new Vector2(941,1672),new Vector2(720,1600),new Vector2(768,1024)})
     foreach(var p in oracle.cells)
     {var d=LayoutMapper.BoardToDesign(LayoutMapper.CellTopLeft(p.x,p.y)+Vector2.one*58);
      Check(Vector2.Distance(d,LayoutMapper.ScreenToDesign(LayoutMapper.DesignToScreen(d,size),size))<.001f,"input round trip");}
    var m=new BoardModel();var values=Enumerable.Repeat(36,25).ToArray();values[0]=1;values[1]=1;values[5]=1;values[6]=1;
    m.Load(values,1);Check(m.Highest==1,"historical highest must not be inferred");
    Check(m.Group(m.At(0,0),false).Select(c=>c.Y*5+c.X).SequenceEqual(new[]{0,5,6,1}),"manual DFS");
    Check(m.Group(m.At(0,0),true).Select(c=>c.Y*5+c.X).SequenceEqual(new[]{0,5,1,6}),"automatic BFS");
    Check(m.Group(m.At(4,4),false).Count==0,"Z not mergeable");
    var step=m.Prepare(m.At(0,0),m.Group(m.At(0,0),false),0);m.Apply(step);
    Check(m.Score==6&&m.At(0,0).Level==2&&m.Cells.Count()==22,"apply merge");
    var moved=m.Compact();Check(moved.Count>0,"gravity");
    var born=m.Refill(()=>.5);Check(born.Count==3&&m.Cells.Count()==25,"refill");
    Check(born.Select(c=>c.Y*5+c.X).SequenceEqual(born.Select(c=>c.Y*5+c.X).OrderBy(x=>x)),"refill ordering");
    var feedback=JsonUtility.FromJson<FeedbackOracle>(File.ReadAllText(Environment.GetEnvironmentVariable("M1_FEEDBACK_ORACLE")));
    foreach(var sample in feedback.samples)
    {
     var actual=MergeTrail.Profile(sample.age,sample.delay,sample.duration);
     Check(Mathf.Abs(actual.x-sample.progress)<.00001f,"Godot trail position timing");
     Check(Mathf.Abs(actual.y-sample.scale)<.00001f,"Godot trail scale timing");
     Check(Mathf.Abs(actual.z-sample.opacity)<.00001f,"Godot trail opacity timing");
    }
    Directory.CreateDirectory("Assets/MergeTo10/Scenes");
    var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
    new GameObject("M1BoardParity").AddComponent<M1BoardDemo>();
    const string scenePath="Assets/MergeTo10/Scenes/M1BoardParity.unity";
    EditorSceneManager.SaveScene(scene,scenePath);
    PlayerSettings.defaultScreenWidth=470;PlayerSettings.defaultScreenHeight=836;
    PlayerSettings.fullScreenMode=FullScreenMode.Windowed;
    PlayerSettings.runInBackground=true;
    AssetDatabase.SaveAssets();
    var result=BuildPipeline.BuildPlayer(new BuildPlayerOptions{scenes=new[]{scenePath},locationPathName=Path.Combine(output,"Windows","MergeTo10M1.exe"),target=BuildTarget.StandaloneWindows64,options=BuildOptions.Development});
    Check(result.summary.result==BuildResult.Succeeded,"Windows build "+result.summary.result);
    foreach(string shaderName in new[]{"ParitySprite","BoardShadow","MergeGhost"})
    {
     var shader=AssetDatabase.LoadAssetAtPath<Shader>("Assets/MergeTo10/Resources/M1Art/"+shaderName+".shader");
     Check(shader!=null,"Missing shader "+shaderName);
     var errors=ShaderUtil.GetShaderMessages(shader).Where(message=>message.severity.ToString()=="Error").ToArray();
     Check(errors.Length==0,"Shader errors "+shaderName+": "+string.Join("; ",errors.Select(message=>message.message)));
    }
    File.WriteAllText(Path.Combine(output,"verification.txt"),"PASS assertions="+assertions+" oracleCases="+oracle.cases.Length+" samples="+oracle.cases.Sum(c=>c.samples.Length)+"\nCore and build only. Runtime visual parity and full migration NOT certified.");
    Debug.Log("M1_VERIFIED assertions="+assertions);EditorApplication.Exit(0);
   }
   catch(Exception e){Debug.LogException(e);EditorApplication.Exit(1);}
  }
 }
}
