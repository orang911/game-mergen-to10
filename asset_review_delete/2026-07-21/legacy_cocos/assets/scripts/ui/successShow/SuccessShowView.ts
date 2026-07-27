import View from "../View";

// Learn TypeScript:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/typescript.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/typescript.html
// Learn Attribute:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/reference/attributes.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/life-cycle-callbacks.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/life-cycle-callbacks.html

const { ccclass, property } = cc._decorator;

@ccclass
export default class SuccessShowView extends View {

    @property(cc.Button)
    continuBtn: cc.Button = null;

    @property(cc.Node)
    bgNode: cc.Node = null;

    @property(cc.Node)
    lightNode: cc.Node = null;

    start() {
        this.continuBtn.node.on(cc.Node.EventType.TOUCH_END, () => {
            this.closeSelf();
        })
    }

    open() {
        super.open();

        this.lightNode.opacity = 0;
        this.lightNode.runAction(cc.fadeIn(0.1));
        this.bgNode.scale = 0;
        this.bgNode.runAction(
            cc.scaleTo(0.2, 1).easing(cc.easeBackInOut())
        );
    }

    // update (dt) {}
}
