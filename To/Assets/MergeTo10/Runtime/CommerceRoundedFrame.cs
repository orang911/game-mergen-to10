using UnityEngine;
using UnityEngine.UI;
namespace MergeTo10.Runtime {
 // Native equivalent of the source StyleBoxFlat: radius 20, border 4, shadow 4.
 public sealed class CommerceRoundedFrame : MaskableGraphic {
  Texture2D solid;
  public override Texture mainTexture { get { if(!solid){solid=new Texture2D(1,1,TextureFormat.RGBA32,false);solid.SetPixel(0,0,Color.white);solid.Apply();}return solid;} }
  protected override void OnDestroy(){if(solid)Destroy(solid);if(material)Destroy(material);base.OnDestroy();}
  protected override void OnPopulateMesh(VertexHelper vh) {
   vh.Clear(); var r=rectTransform.rect;
   for(int i=4;i>=1;i--) { var shadow=new Rect(r.x-i,r.y-i,r.width+2*i,r.height+2*i); Fill(vh,shadow,20+i,new Color(1,.69f,.05f,.085f)); }
   Fill(vh,r,20,new Color(1,.773f,.157f));
   Fill(vh,new Rect(r.x+4,r.y+4,r.width-8,r.height-8),16,new Color(.267f,.788f,.957f));
  }
  void Fill(VertexHelper vh,Rect r,float radius,Color c) {
   radius=Mathf.Min(radius,Mathf.Min(r.width,r.height)*.5f);int start=vh.currentVertCount;
   vh.AddVert(r.center,c,Vector2.zero);
   for(int corner=0;corner<4;corner++) {
    Vector2 center=new Vector2(corner==0||corner==3?r.xMax-radius:r.xMin+radius,corner<2?r.yMax-radius:r.yMin+radius);
    for(int step=0;step<=12;step++){float a=(corner*90+step*7.5f)*Mathf.Deg2Rad;vh.AddVert(center+new Vector2(Mathf.Cos(a),Mathf.Sin(a))*radius,c,Vector2.zero);}
   }
   for(int i=0;i<52;i++)vh.AddTriangle(start,start+1+(i+1)%52,start+1+i);
  }
 }
}
