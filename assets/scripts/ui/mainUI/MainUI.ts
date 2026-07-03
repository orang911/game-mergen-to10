import GameManager from "../../core/GameManager";
import UIManager from "../UIManager";
import SoundManager from "../../core/SoundManager";
import { BgSoundClipType } from "../../auto/BgSoundClio";
import { SoundClipType } from "../../auto/SoundClip";
import DMAdsSDKMgr from "../../util/DMAdsSDKMgr";

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
export default class MainUI extends cc.Component {

    @property(cc.Button)
    startBtn: cc.Button = null;

    @property(cc.Button)
    musicBtn: cc.Button = null;

    @property(cc.Animation)
    bgAnimation: cc.Animation = null;

    @property(cc.Animation)
    mainAnimation: cc.Animation = null;

    onLoad() {
        this.startBtn.node.on(cc.Node.EventType.TOUCH_END, () => {
            //点击按钮音效
            SoundManager.instance.playAudioClip(SoundClipType.click);

            GameManager.instance.gameScene.startGame();
        }, this);

        this.musicBtn.node.on(cc.Node.EventType.TOUCH_END, () => {
            if (SoundManager.instance.isMute) {
                SoundManager.instance.resume();
            } else {
                SoundManager.instance.pause();
            }
            this.musicBtn.node.parent.getComponent(cc.Button).interactable = !SoundManager.instance.isMute;
        }, this);
    }

    start() {
        this.musicBtn.node.parent.getComponent(cc.Button).interactable = !SoundManager.instance.isMute;
        SoundManager.instance.PlayBGSound(BgSoundClipType.main);

        this.open();
    }

    open() {
        GameManager.instance.gameScene.node.active = false;
        UIManager.instance.gameUI.close();
        this.node.active = true;

        this.bgAnimation.play();
        this.mainAnimation.play();
    }

    close() {
        this.node.active = false;
    }
}
