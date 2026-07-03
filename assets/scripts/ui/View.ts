import UIManager from "./UIManager";

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
export default class View extends cc.Component {

    @property({ displayName: "是否永久界面", tooltip: "勾选，关闭时会保存窗口对象，下次打开不用再创建，否在从内存删除，释放资源" })
    public persistent: boolean = true;

    @property({ displayName: "是否使用弹窗效果", tooltip: "勾选，有弹出效果，不钩，瞬间出现" })
    public popUp: boolean = true;

    /* @property({ type: cc.Enum(GamePlatformBanner), tooltip: "设置横幅广告id索引，广告会在窗口打开时自动显示，窗口关闭，广告也关闭" })
    public adIndex: GamePlatformBanner = GamePlatformBanner.none; */

    protected onCloseBtnClick(event: cc.Event.EventTouch) {
        //SoundManager.instance.playAudioClip(SoundClipType.click);
        //GamePlatform.sdk.vibrateShort();
        this.closeSelf(!this.persistent);
    }

    protected closeSelf(isDele: boolean = false) {
        if (!UIManager.instance.closeView(this.node.name, isDele)) {
            this.close();
        }
    }

    /*start () {

    }*/

    // update (dt) {}

    /**
     * UI苏醒
     */
    public awake() {
        //GamePlatform.showBottomBanner(this.adIndex)
    }

    /**
     * UI沉睡
     */
    public sleep() {
        //GamePlatform.sdk.removeBanner();
    }

    public open() {
        this.node.active = true;

        if (this.popUp) {
            this.node.scale = 0.8;

            this.unscheduleAllCallbacks();
            this.node.stopAllActions();

            this.scheduleOnce(() => {
                this.node.runAction(cc.sequence(cc.scaleTo(0.45, 1).easing(cc.easeBackOut()), cc.callFunc(() => {

                }, this)));

            }, 0.01);
        }

        this.awake();
    }

    public close() {
        this.node.active = false;
        this.sleep();

    }

    public destroySelf() {
        this.node.destroy();
    }
}
