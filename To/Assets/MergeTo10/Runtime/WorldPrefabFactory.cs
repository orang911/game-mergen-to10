using UnityEngine;

namespace MergeTo10.Runtime {
 public static class WorldPrefabFactory {
  public static GameObject Create(string id,string name,Transform parent=null){
   var prefab=Resources.Load<GameObject>("Prefabs/"+id);
   var go=prefab?Object.Instantiate(prefab,parent,false):new GameObject(name);
   if(!prefab&&parent)go.transform.SetParent(parent,false);go.name=name;return go;
  }
  public static Transform Child(Transform parent,string name){
   foreach(var t in parent.GetComponentsInChildren<Transform>(true))if(t!=parent&&t.name==name)return t;
   return null;
  }
 }
}
