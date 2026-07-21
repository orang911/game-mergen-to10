import GameManager, { GameStatus } from "../../core/GameManager";
import { SoundClipType } from "../../auto/SoundClip";
import SoundManager from "../../core/SoundManager";


const { ccclass, property } = cc._decorator;

@ccclass
export default class GameUI extends cc.Component {

    @property(cc.Button)
    replayBtn: cc.Button = null;

    @property(cc.Button)
    backBtn: cc.Button = null;

    onLoad() {
        this.replayBtn.node.on(cc.Node.EventType.TOUCH_END, () => {
            //点击按钮音效
            SoundManager.instance.playAudioClip(SoundClipType.click);

            //if (GameManager.instance.gameStatus != GameStatus.start) return;
            GameManager.instance.gameScene.replayGame();
        }, this);

        this.backBtn.node.on(cc.Node.EventType.TOUCH_END, () => {
            //点击按钮音效
            SoundManager.instance.playAudioClip(SoundClipType.click);

            GameManager.instance.gameScene.overGame();
        }, this);
    }

    open() {
        this.node.active = true;
        this.replayBtn.node.active = true;
        this.backBtn.node.active = true;
    }

    close() {
        this.node.active = false;
        this.replayBtn.node.active = false;
        this.backBtn.node.active = false;
    }
}
