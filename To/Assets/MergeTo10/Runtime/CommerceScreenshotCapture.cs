using System;
using System.IO;
using System.Collections;
using UnityEngine;
namespace MergeTo10.Editor {
 public sealed class CommerceScreenshotCapture:MonoBehaviour {
  public void Run(string path,Action done){StartCoroutine(Capture(path,done));}
  IEnumerator Capture(string path,Action done){yield return new WaitForEndOfFrame();var image=ScreenCapture.CaptureScreenshotAsTexture();try{File.WriteAllBytes(path,image.EncodeToPNG());}finally{Destroy(image);done();Destroy(this);}}
 }
}