using UnityEngine;
namespace MergeTo10.Core
{
    public static class LayoutMapper
    {
        public static readonly Vector2 Design=new Vector2(941,1672);
        public static readonly Vector2 BoardOrigin=new Vector2(137.55f,690.79f);
        public static readonly Vector2 BoardPivot=new Vector2(316.5f,633);
        public const float ContentScale=.95f;
        public static Vector2 CellTopLeft(int x,int y)=>new Vector2(37.5f+x*113,32.5f+(4-y)*113);
        public static Vector2 BoardToDesign(Vector2 local)=>BoardOrigin+BoardPivot+(local-BoardPivot)*ContentScale;
        public static Vector2 DesignToBoard(Vector2 point)=>(point-BoardOrigin-BoardPivot)/ContentScale+BoardPivot;
        public static float Scale(Vector2 screen)=>Mathf.Min(screen.x/941,screen.y/1672);
        public static Vector2 Offset(Vector2 screen)=>(screen-Design*Scale(screen))*.5f;
        public static Vector2 ScreenToDesign(Vector2 bottomLeft,Vector2 screen)=>(new Vector2(bottomLeft.x,screen.y-bottomLeft.y)-Offset(screen))/Scale(screen);
        public static Vector2 DesignToScreen(Vector2 point,Vector2 screen)
        {var p=Offset(screen)+point*Scale(screen);return new Vector2(p.x,screen.y-p.y);}
        public static Vector3 World(Vector2 design)=>new Vector3(design.x/100,-design.y/100,0);
    }
}
