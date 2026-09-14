using System;
using UnityEngine;

namespace MergeTo10.Runtime {
 [DefaultExecutionOrder(-1000)]
 public sealed class PrefabSceneLibrary : MonoBehaviour {
  [Serializable] public sealed class Entry {public string Id;public GameObject Template;}
  public Entry[] Interfaces=Array.Empty<Entry>();
  static PrefabSceneLibrary current;
  void Awake(){current=this;foreach(var entry in Interfaces)if(entry.Template)entry.Template.SetActive(false);}
  void OnDestroy(){if(current==this)current=null;}
  public static GameObject Find(string id){
   if(current)foreach(var entry in current.Interfaces)if(entry.Id==id&&entry.Template)return entry.Template;
   return Resources.Load<GameObject>("Prefabs/UI/"+id);
  }
 }
}
