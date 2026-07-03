// Learn TypeScript:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/typescript.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/typescript.html
// Learn Attribute:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/reference/attributes.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/life-cycle-callbacks.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/life-cycle-callbacks.html

export default class Vector2 {

    /**
     * 
     * @param posStart 插值运算
     * @param posEnd 
     * @param t 
     */
    public static lerp(posStart:cc.Vec2,posEnd:cc.Vec2,t:number):cc.Vec2
    {
        return this.bezierOne(t,posStart,posEnd);
    }

    /*public static slerp(dir1:cc.Vec2,dir2:cc.Vec2,t:number):cc.Vec2
    {
        //return this.bezierOne(t,posStart,posEnd);
    }*/

    //一次贝塞尔即为线性插值函数
    public static bezierOne(t:number,posStart:cc.Vec2,posEnd:cc.Vec2):cc.Vec2
    {
        
        if(t > 1)
        {
            t = 1;
        }else if(t < 0)
        {
            t = 0
        }
        
        //return posStart.addSelf(posEnd.subSelf(posStart).mulSelf(t));
        return posStart.mul(1 - t).add(posEnd.mul(t));

    }

    //二次贝塞尔曲线
    public static bezierTwo(t:number,posStart:cc.Vec2,posCon:cc.Vec2,posEnd:cc.Vec2):cc.Vec2
    {
        
        if(t > 1)
        {
            t = 1;
        }else if(t < 0)
        {
            t = 0
        }
        
        var n = (1 - t);
        var tt = t * t;

        var pos = posStart;

        pos.addSelf(posStart.mul(n * n));
        pos.addSelf(posCon.mul(2 * n * t));
        pos.addSelf(posEnd.mul(tt));

        return pos;
    }

    //三次贝塞尔
    public static bezierThree(t:number,posStart:cc.Vec2,posCon1:cc.Vec2,posCon2:cc.Vec2,posEnd:cc.Vec2):cc.Vec2
    {
        if(t > 1)
        {
            t = 1;
        }else if(t < 0)
        {
            t = 0
        }

        var n = (1 - t);
        var nn = n * n;
        var nnn = nn * n;
        var tt = t * t;
        var ttt = tt * t;

        var pos = posStart;
        pos.addSelf(posStart.mul(nnn));
        pos.addSelf(posCon1.mul(3*nn * t));
        pos.addSelf(posCon2.mul(3*n*tt));
        pos.addSelf(posEnd.mul(ttt));

        return pos;
    }

    /**
     * 
     * @param pos1 获得两点间的距离
     * @param pos2 
     */
    public static distance(pos1:cc.Vec2,pos2:cc.Vec2):number
    {
        return pos2.sub(pos1).mag();
    }

    /**
     * 获得某个方向的角度
     * @param dir 
     */
    public static angle(dir:cc.Vec2):number
    {
        return 90 - Math.atan2(dir.y,dir.x) * 180 / Math.PI 
    }

    public static translate(target:cc.Node,dir:cc.Vec2)
    {

        //var radian:number = target.rotation / 180 * Math.PI;

        //var dirX:cc.Vec2 = cc.v2(Math.cos(radian + 90),Math.sin(radian + 90));
        //var dirY:cc.Vec2 = cc.v2(Math.cos(radian),Math.sin(radian));

        //var trans:cc.Vec2 = cc.v2(dirX.mul(dir.x),dirY.mul(dir.y).)

        //var pos =  target.position.add(cc.v2(dir.x * Math.cos(radian),dir.y * Math.sin(radian)));

        //target.position = pos;

        //target.position.transformMat4()
       

    }

    /**
     * 
     * @param target 相对于玩家坐标向前移动
     * @param speed 
     */
    public static translateForward(target:cc.Node,speed:number)
    {
        var radian:number = target.rotation / 180 * Math.PI;
        var dir:cc.Vec2 = cc.v2(Math.cos(radian),Math.sin(radian)).mul(speed);
        var pos =  target.position.add(cc.v2(dir.x * Math.cos(radian),dir.y * Math.sin(radian)));
        target.position = pos;
    }
}
