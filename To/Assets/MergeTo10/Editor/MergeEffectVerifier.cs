using System;
using System.IO;
using MergeTo10.Runtime;
using UnityEditor;
using UnityEngine;

namespace MergeTo10.Editor
{
 public static class MergeEffectVerifier
 {
  [InitializeOnLoadMethod] static void Pending()
  {
   if(!File.Exists("Temp/merge_effect_verify.request"))return;
   File.Delete("Temp/merge_effect_verify.request");
   EditorApplication.delayCall+=Verify;
  }
  [MenuItem("MergeTo10/Verify Merge Effect")]
  public static void Verify()
  {
   GameObject instance=null;
   try
   {
    var settings=Resources.Load<MergeEffectSettings>("merge_effect");
    if(!settings||!settings.Prefab||AssetDatabase.GetAssetPath(settings.Prefab)!="Assets/EffectsPrefabs/Particle1.prefab")
     throw new Exception("Merge effect must reference Particle1.prefab");
    instance=UnityEngine.Object.Instantiate(settings.Prefab);
    instance.hideFlags=HideFlags.HideAndDontSave;
    var systems=instance.GetComponentsInChildren<ParticleSystem>(true);
    if(systems.Length!=2)throw new Exception("Expected both authored particle layers");
    foreach(var renderer in instance.GetComponentsInChildren<ParticleSystemRenderer>(true))
     foreach(var material in renderer.sharedMaterials)
      if(!material||!material.shader||!material.shader.isSupported)throw new Exception("Missing or unsupported particle material");
    foreach(var particles in systems)
    {
     particles.Stop(false,ParticleSystemStopBehavior.StopEmittingAndClear);
     var main=particles.main;main.loop=false;main.stopAction=ParticleSystemStopAction.None;
     particles.Simulate(.1f,false,true);
     if(particles.particleCount==0)throw new Exception("Particle layer does not emit");
     for(int i=0;i<150;i++)particles.Simulate(.02f,false,false);
     if(particles.particleCount!=0)throw new Exception("Particle layer does not finish: "+particles.name+" count="+particles.particleCount+" time="+particles.time);
    }
    File.WriteAllText("Temp/merge_effect_verify.result","PASS: Resources reference, two particle layers, supported materials, emission and finite lifetime.");
    Debug.Log("Merge effect verification PASS");
   }
   catch(Exception error){File.WriteAllText("Temp/merge_effect_verify.result","FAIL: "+error);Debug.LogException(error);}
   finally{if(instance)UnityEngine.Object.DestroyImmediate(instance);}
  }
 }
}
