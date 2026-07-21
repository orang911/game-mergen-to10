// Learn TypeScript:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/typescript.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/typescript.html
// Learn Attribute:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/reference/attributes.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/life-cycle-callbacks.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/life-cycle-callbacks.html

const {ccclass, property} = cc._decorator;

@ccclass
export default class Vector3 {

    /**
     * 点乘
     * @param dir1 
     * @param dir2 
     */
    public static dot(dir1:cc.Vec3,dir2:cc.Vec3):number
    {
        var tempDir1:cc.Vec3 = dir1;
        var tempDir2:cc.Vec3 = dir2;

        return tempDir1.x * tempDir2.x + tempDir1.y * tempDir2.y + tempDir1.z * tempDir2.z;
        
        //return dir1.mag() * dir2.mag() * Math.cos(); //（0° ≤ θ ≤ 180°）
    }

    /**
     * 叉乘
     * @param dir1 
     * @param dir2 
     */
    public static cross(dir1:cc.Vec3,dir2:cc.Vec3):cc.Vec3
    {

        var i:cc.Vec3 = new cc.Vec3(1,0,0);
        var j:cc.Vec3 = new cc.Vec3(0,1,0);
        var k:cc.Vec3 = new cc.Vec3(0,0,1);

        var tempDir1:cc.Vec3 = new cc.Vec3(dir1.x,dir1.y,0);
        var tempDir2:cc.Vec3 = new cc.Vec3(dir2.x,dir2.y,0);

        var iv:cc.Vec3 = i.mul(tempDir1.y * tempDir2.z - tempDir2.y * tempDir1.z);
        var jv:cc.Vec3 = j.mul(tempDir2.x * tempDir1.z - tempDir1.x * tempDir2.z);
        var kv:cc.Vec3 = k.mul(tempDir1.x * tempDir2.y - tempDir2.x * tempDir1.y);

        return  iv.add(jv).add(kv);

        //return dir1.mag() * dir2.mag() * Math.sin(); //（0° ≤ θ ≤ 180°）
    }

    /**
     * 获得两个方向向量的角度
     * @param dir1 
     * @param dir2 
     */
    public static angle(dir1:cc.Vec3,dir2:cc.Vec3):number
    {
        var dotValue = this.dot(dir1,dir2);
        return Math.acos(dotValue)/Math.PI * 180 * Math.sign(dotValue);
    }
    
    /**
     * 获得方向a到方向b的角度（带有方向的角度）
     * @param a 
     * @param b 
     */
    private dirAngle( a:cc.Vec3, b:cc.Vec3):number
    {
        var c:cc.Vec3 = Vector3.cross(a, b);
        var angle:number = Vector3.angle(a, b);
        // a 到 b 的夹角
        var sign = Math.sign(Vector3.dot(c.normalize(), Vector3.cross(b.normalize(), a.normalize())));

        return angle * sign;
    }
}
