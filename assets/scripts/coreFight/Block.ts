import GameManager, { GameStatus } from "../core/GameManager";


const { ccclass, property } = cc._decorator;

@ccclass
export default class Block extends cc.Component {

    @property(cc.Sprite)
    private commonSp: cc.Sprite = null;

    @property(cc.Sprite)
    private selectSp: cc.Sprite = null;

    @property(cc.Animation)
    slakeAnimation: cc.Animation = null;

    /**
     * 是否处于选择状态
     */
    get selected(): boolean {
        return this.selectSp.node.active;
    }
    set selected(value: boolean) {
        this.selectSp.node.active = value;
        this.commonSp.node.active = !value;
    }

    /**
     * 方块等级，不同等级颜色不同
     */
    get level(): number {
        return this._level;
    }
    set level(value: number) {
        if (this._level == value) {
            return;
        }
        this._level = value;
        this.checkColor();
    }
    private _level: number = 1;

    /**
     * 方块位置
     */
    get site() {
        return this._site;
    }
    set site(value: cc.Vec2) {
        this._site = value;
        this.node.zIndex = 4 - value.y;
    }
    private _site: cc.Vec2 = cc.v2(0, 0);

    /**
     * 是否已经进行合并动作
     */
    hadMergen: boolean = false;

    index: number = 0;

    onLoad() {
        this.node.on(cc.Node.EventType.TOUCH_END, this.clickFunc, this);
    }

    start() {

    }

    clickFunc(event: cc.Event.EventTouch) {
        if (GameManager.instance.gameStatus != GameStatus.start) return;

        let gameScene = GameManager.instance.gameScene;
        if (this.selected) {
            if (this.hadMergen) return;
            gameScene.mergeSelectBlocks(this);
        } else {
            gameScene.selectNextBlocks(this);
        }
    }

    /**
     * 创建时度移动动作
     */
    ceateMove(delay: number = 0, callFunc?: Function) {
        let pos = GameManager.instance.gameScene.getPosBySite(this.site);
        this.node.position = cc.v2(pos.x, 1334 / 2 + 132 * (this.site.y + 1));
        this.node.runAction(
            cc.sequence(
                cc.delayTime(delay),
                cc.moveTo(0.3, pos),
                cc.callFunc(() => {
                    callFunc && callFunc();
                })
            )
        );
    }

    /**
     * 已有方块下落
     */
    fall(newSite: cc.Vec2, callFunc?: Function) {
        if (this.site.equals(newSite)) {
            return;
        }

        this.site = newSite;

        let pos = GameManager.instance.gameScene.getPosBySite(this.site);
        this.node.runAction(
            cc.sequence(
                cc.moveTo(0.1, pos),
                cc.callFunc(() => {
                    callFunc && callFunc();
                })
            )
        );
    }

    checkColor() {
        this.commonSp.spriteFrame = GameManager.instance.blockCommomIcons[this.level - 1];
        this.selectSp.spriteFrame = GameManager.instance.blockSelectIcons[this.level - 1];
    }

    removeAction(callFcunc?: Function) {
        this.slakeAnimation.node.active = true;
        let time = this.slakeAnimation.play().duration;
        this.slakeAnimation.node.parent = GameManager.instance.gameScene.effectLayer;
        this.slakeAnimation.node.position = this.node.position;
        this.node.runAction(
            cc.sequence(
                cc.fadeOut(time / 3),
                cc.delayTime(time * 2 / 3),
                cc.callFunc(() => {
                    this.slakeAnimation.node.destroy();
                    this.removeSelf();
                    callFcunc && callFcunc();
                }),
            )
        );
    }

    removeSelf() {
        GameManager.instance.gameScene.removeBlock(this);
        this.node.destroy();
    }

    // update (dt) {}
}
