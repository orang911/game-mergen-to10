import Player from "./Player";
import GameManager from "../core/GameManager";

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
export default class PlayerControl extends cc.Component {

    player: Player = null;

    start() {
        this.player = this.node.getComponent(Player);

        let touchContent = GameManager.instance.touchContent;

        touchContent.on(cc.Node.EventType.TOUCH_START, (event: cc.Event.EventTouch) => {
            
        }, this);
        touchContent.on(cc.Node.EventType.TOUCH_MOVE, (event: cc.Event.EventTouch) => {
            
        }, this);
        touchContent.on(cc.Node.EventType.TOUCH_END, (event: cc.Event.EventTouch) => {
            
        }, this);
        touchContent.on(cc.Node.EventType.TOUCH_CANCEL, (event: cc.Event.EventTouch) => {
            
        }, this);

    }

    // update (dt) {}
}
