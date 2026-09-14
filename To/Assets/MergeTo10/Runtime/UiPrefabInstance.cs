using UnityEngine;

namespace MergeTo10.Runtime {
 [DisallowMultipleComponent]
 public sealed class UiPrefabInstance : MonoBehaviour {
  [Tooltip("Independent animation layer. Add an Animator here; use Unscaled Time for paused UI.")]
  public RectTransform AnimationRoot;
  PrefabUiNode[] nodes;
  public void BeginBinding(){nodes=GetComponentsInChildren<PrefabUiNode>(true);foreach(var node in nodes){node.Claimed=false;node.CaptureAuthoring();}}
  public void CompleteBinding(){
   if(nodes==null)return;
   foreach(var node in nodes){
    if(node.Claimed)node.RestoreAuthoring();
    else node.gameObject.SetActive(false); // Optional badges/rows absent in this data state.
   }
   nodes=null;
  }
 }
 public static class PrefabComponents {
  public static T EnsureComponent<T>(this GameObject go) where T:Component {
   var component=go.GetComponent<T>();return component?component:go.AddComponent<T>();
  }
 }
}
