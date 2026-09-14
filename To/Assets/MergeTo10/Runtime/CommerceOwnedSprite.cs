using UnityEngine;
namespace MergeTo10.Runtime {
 public sealed class CommerceOwnedSprite : MonoBehaviour {
  public Material OwnMaterial; public Sprite Value; public bool OwnTexture;
  void OnDestroy(){if(OwnMaterial)Destroy(OwnMaterial);if(Value){if(OwnTexture)Destroy(Value.texture);Destroy(Value);}}
 }
}
