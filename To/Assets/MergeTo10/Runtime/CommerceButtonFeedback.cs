using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 public sealed class CommerceButtonFeedback : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IPointerExitHandler {
  public float PressScale=.97f;
  Graphic[] graphics; Color[] colors; bool pressed;
  public void OnPointerDown(PointerEventData e) {
   if(e.button!=PointerEventData.InputButton.Left || !GetComponent<Button>().IsInteractable())return;
   graphics=GetComponentsInChildren<Graphic>();colors=new Color[graphics.Length];
   for(int i=0;i<graphics.Length;i++){colors[i]=graphics[i].color;graphics[i].color=colors[i]*new Color(.88f,.88f,.88f,1);}
   pressed=true;transform.localScale=Vector3.one*PressScale;
  }
  public void OnPointerUp(PointerEventData e){Restore();}
  public void OnPointerExit(PointerEventData e){Restore();}
  void OnDisable(){Restore();}
  void Restore(){if(!pressed)return;pressed=false;transform.localScale=Vector3.one;for(int i=0;i<graphics.Length;i++)if(graphics[i])graphics[i].color=colors[i];}
 }
}
