import Mathf from "./Mathf";

// Learn TypeScript:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/typescript.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/typescript.html
// Learn Attribute:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/reference/attributes.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/life-cycle-callbacks.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/life-cycle-callbacks.html


export default class Random {

    public static Range(num1: number, num2: number) {
        if (num2 > num1) {
            return Math.random() * (num2 - num1) + num1;
        }
        return Math.random() * (num1 - num2) + num2;
    }


    public static RangeInteger(num1: number, num2: number) {
        return Math.floor(this.Range(num1, num2));
    }

    /**
     * 获得一个随机的坐标
     */
    public static RangeVec2(pos1: cc.Vec2, pos2: cc.Vec2) {
        let returnPos = cc.Vec2.ZERO;
        returnPos.x = Mathf.lerp(pos1.x, pos2.x, Math.random());
        returnPos.y = Mathf.lerp(pos1.y, pos2.y, Math.random());
        return returnPos;
    }
}
