using System;
using System.Collections;
using System.IO;
using System.Linq;
using UnityEngine;
namespace MergeTo10.Runtime
{
 public sealed class M1Smoke:MonoBehaviour
 {
  Color32[] lastPixels;
  IEnumerator Start()
  {
   string dir=Environment.GetCommandLineArgs().FirstOrDefault(a=>a.StartsWith("--capture-dir="))?.Substring(14);
   if(string.IsNullOrEmpty(dir))yield break;
   Directory.CreateDirectory(dir);
   var demo=GetComponent<M1BoardDemo>();
   yield return new WaitForSeconds(1.6f);
   if(!Capture(Path.Combine(dir,"01-initial.png"))){Fail(dir,"Initial camera image is blank");yield break;}
   var shadowPixels=lastPixels;demo.Shadow.Renderer.enabled=false;
   Capture(Path.Combine(dir,"01-control-without-shadow.png"));demo.Shadow.Renderer.enabled=true;
   int shadowDifference=Difference(shadowPixels,lastPixels);
   File.WriteAllText(Path.Combine(dir,"shadow-pixel-difference.txt"),"Changed pixels: "+shadowDifference+"; silhouettes="+demo.Shadow.BlockCount);
   if(shadowDifference<32||demo.Shadow.BlockCount!=25){Fail(dir,"Unified shadow missing or incomplete");yield break;}
   yield return new WaitForSeconds(.2f);
   if(!demo.TryMerge(2,1)){Fail(dir,"Fixture merge refused");yield break;}
   bool highlight=false,trailVisible=false;float elapsed=0;
   while(demo.Busy&&elapsed<20)
   {
    if(!trailVisible&&demo.Trails.Active.Any(t=>t&&t.Opacity>.20f))
    {
     Capture(Path.Combine(dir,"02-trails.png"));var trailPixels=lastPixels;
     var renderers=demo.Trails.Active.Where(t=>t&&t.gameObject.activeInHierarchy).SelectMany(t=>t.Renderers).ToArray();
     foreach(var renderer in renderers)renderer.enabled=false;
     Capture(Path.Combine(dir,"02-control-without-trails.png"));
     foreach(var renderer in renderers)renderer.enabled=true;
     int difference=Difference(trailPixels,lastPixels);
     if(difference>=32){trailVisible=true;File.WriteAllText(Path.Combine(dir,"trail-pixel-difference.txt"),"Changed pixels: "+difference);}
    }
    var charged=FindObjectsByType<CellView>(FindObjectsSortMode.None).FirstOrDefault(v=>v.HighlightVisible&&v.HighlightRenderer.color.a>.95f);
    if(!highlight&&charged!=null)
    {
     if(!Capture(Path.Combine(dir,"02-chain-highlight.png"))){Fail(dir,"Highlight camera image is blank");yield break;}
     var visiblePixels=lastPixels;charged.HighlightRenderer.enabled=false;
     Capture(Path.Combine(dir,"02-control-without-highlight.png"));charged.HighlightRenderer.enabled=true;
     int different=0;for(int i=0;i<lastPixels.Length;i++)
      if(Math.Abs(visiblePixels[i].r-lastPixels[i].r)+Math.Abs(visiblePixels[i].g-lastPixels[i].g)+Math.Abs(visiblePixels[i].b-lastPixels[i].b)>6)different++;
     File.WriteAllText(Path.Combine(dir,"highlight-pixel-difference.txt"),"Changed pixels at peak: "+different+"; cell="+charged.Cell.X+","+charged.Cell.Y+"; alpha="+charged.HighlightRenderer.color.a);
     if(different<32){Fail(dir,"Highlight state active but no meaningful visible pixel change");yield break;}highlight=true;
    }
    yield return null;elapsed+=Time.unscaledDeltaTime;
   }
   yield return new WaitForSeconds(.4f);
   var cells=FindObjectsByType<CellView>(FindObjectsSortMode.None);
   if(demo.Busy||cells.Length!=25||!highlight||!trailVisible){Fail(dir,"settlement timeout, count, highlight or trail: "+demo.Busy+"/"+cells.Length+"/"+highlight+"/"+trailVisible);yield break;}
   if(cells.Any(v=>Mathf.Abs(v.transform.localScale.x-1)>.001f)){Fail(dir,"Residual pop scale");yield break;}
   if(!Capture(Path.Combine(dir,"03-settled.png"))){Fail(dir,"Settled camera image is blank");yield break;}
   demo.ResetBoard(false);demo.TryMerge(2,1);yield return new WaitForSeconds(.1f);demo.ResetBoard(false);
   yield return new WaitForSeconds(1);
   if(demo.Busy||FindObjectsByType<CellView>(FindObjectsSortMode.None).Length!=25||FindObjectsByType<MergeTrail>(FindObjectsSortMode.None).Length!=0){Fail(dir,"Reset cancellation");yield break;}
   demo.ResetBoard(false,Enumerable.Repeat(1,25).ToArray());
   if(!demo.TryMerge(2,2)){Fail(dir,"25-cell merge refused");yield break;}
   elapsed=0;while(demo.Busy&&elapsed<20){yield return null;elapsed+=Time.unscaledDeltaTime;}
   yield return new WaitForSeconds(.5f);
   if(demo.Busy||FindObjectsByType<CellView>(FindObjectsSortMode.None).Length!=25||FindObjectsByType<MergeTrail>(FindObjectsSortMode.None).Length!=0){Fail(dir,"25-cell merge settlement or trail cleanup");yield break;}
   var isolated=Enumerable.Repeat(36,25).ToArray();isolated[0]=1;demo.ResetBoard(false,isolated);
   if(demo.TryMerge(0,0)||demo.TryMerge(4,4)){Fail(dir,"Isolated or maximum-level block merged");yield break;}
   yield return new WaitForSeconds(.2f);
   var first=FindObjectsByType<CellView>(FindObjectsSortMode.None).First(c=>c.Cell.X==0&&c.Cell.Y==0);
   if(Vector2.Distance(first.Position,MergeTo10.Core.LayoutMapper.CellTopLeft(0,0))>.001f){Fail(dir,"Invalid shake did not restore position");yield break;}
   demo.ResetBoard(false);
   var probeCells=FindObjectsByType<CellView>(FindObjectsSortMode.None);
   var probeSource=probeCells.First(c=>c.Cell.X==2&&c.Cell.Y==2);
   var probe=demo.Trails.Spawn(probeSource,probeSource.Position+Vector2.right*113,0,.18f);
   probe.StopAllCoroutines();probe.Sample(.10f);
   foreach(var cell in probeCells)foreach(var renderer in cell.GetComponentsInChildren<SpriteRenderer>())renderer.enabled=false;
   demo.Shadow.Renderer.enabled=false;
   Capture(Path.Combine(dir,"04-ghost-probe.png"));
   demo.Shadow.Renderer.enabled=true;demo.ResetBoard(false);
   File.WriteAllText(Path.Combine(dir,"runtime-result.txt"),"PASS: startup, merge, automatic chain highlight, unified shadow and trail pixel differences, 25 cells after settle, final scale, mid-merge reset, 25-cell mass merge and trail cleanup, isolated/Z rejection and shake recovery.\nCaptures use an offscreen URP camera. Not full gameplay or human feel certification.");
   yield return new WaitForSeconds(.3f);Application.Quit(0);
  }
  void Fail(string dir,string message){File.WriteAllText(Path.Combine(dir,"runtime-result.txt"),"FAIL: "+message);Debug.LogError(message);Application.Quit(2);}
  int Difference(Color32[] a,Color32[] b)
  {
   int count=0;for(int i=0;i<a.Length;i++)if(Math.Abs(a[i].r-b[i].r)+Math.Abs(a[i].g-b[i].g)+Math.Abs(a[i].b-b[i].b)>6)count++;
   return count;
  }
  bool Capture(string path)
  {
   var camera=FindAnyObjectByType<Camera>();
   var target=new RenderTexture(Screen.width,Screen.height,24,RenderTextureFormat.ARGB32,RenderTextureReadWrite.sRGB);
   target.Create();var previous=RenderTexture.active;
   var image=new Texture2D(Screen.width,Screen.height,TextureFormat.RGB24,false);
   try
   {
    UnityEngine.Rendering.RenderPipeline.SubmitRenderRequest(camera,new UnityEngine.Rendering.RenderPipeline.StandardRequest{destination=target});
    RenderTexture.active=target;image.ReadPixels(new Rect(0,0,target.width,target.height),0,0);image.Apply();
    File.WriteAllBytes(path,image.EncodeToPNG());var pixels=image.GetPixels32();lastPixels=pixels;
    var distinct=new System.Collections.Generic.HashSet<int>();
    for(int i=0;i<pixels.Length;i+=127){var p=pixels[i];distinct.Add((p.r<<16)|(p.g<<8)|p.b);}
    return distinct.Count>64;
   }
   finally{RenderTexture.active=previous;target.Release();Destroy(target);Destroy(image);}
  }
 }
}
