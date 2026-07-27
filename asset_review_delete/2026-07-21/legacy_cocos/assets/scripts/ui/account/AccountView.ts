import View from "../View";
import GameManager from "../../core/GameManager";
import DataStorage from "../../core/DataStorage";
import Block from "../../coreFight/Block";
import { SoundClipType } from "../../auto/SoundClip";
import SoundManager from "../../core/SoundManager";
import DMAdsSDKMgr from "../../util/DMAdsSDKMgr";


const { ccclass, property } = cc._decorator;

@ccclass
export default class AccountView extends View {

    @property(cc.Button)
    closeBtn: cc.Button = null;

    @property(cc.Button)
    restartBtn: cc.Button = null;

    @property(cc.Label)
    currentScoreText: cc.Label = null;

    @property(cc.Label)
    maxScoreText: cc.Label = null;

    @property(cc.Node)
    newRecordIcon: cc.Node = null;

    @property(Block)
    showBlock: Block = null;

    maxScore: number = 0;

    currentScore: number = 0;

    isLoadingAdv: boolean = false;

    start() {
        this.closeBtn.node.on(cc.Node.EventType.TOUCH_END, () => {
            DMAdsSDKMgr.Instance.stopRewardedVideoAd();

            //点击按钮音效
            SoundManager.instance.playAudioClip(SoundClipType.click);

            this.closeSelf();
            GameManager.instance.gameScene.overGame();
        }, this);

        this.restartBtn.node.on(cc.Node.EventType.TOUCH_END, () => {
            //点击按钮音效
            SoundManager.instance.playAudioClip(SoundClipType.click);

            if (this.isLoadingAdv) return;
            //播放广告,广告回调在open方法中
            DMAdsSDKMgr.Instance.showRewardedVideoAd();
        });
    }

    init(score: number) {
        this.maxScore = DataStorage.getIntItem("max_Score", 0);
        this.currentScore = score;
        this.currentScoreText.string = "" + this.currentScore;

        if (score > this.maxScore) {

            this.maxScore = score;
            this.newRecordIcon.active = true;
            DataStorage.setItem("max_Score", this.maxScore);
        } else {
            this.newRecordIcon.active = false;
        }
        this.maxScoreText.string = "" + this.maxScore;

        this.showBlock.level = GameManager.instance.gameScene.currentLevel;
    }

    awake() {
        super.awake();
        this.init(GameManager.instance.gameScene.score);
    }

    open() {
        super.open();

        //设置广告回调
        DMAdsSDKMgr.Instance.SetRewardedCallback((results, rewardId) => {
            if (results == "1") {
                this.closeSelf();
                this.scheduleOnce(() => {
                    GameManager.instance.gameScene.resurAction();
                }, 0.2);
            }
        });
        DMAdsSDKMgr.Instance.SetRewardedVideoAdLoadingCallback(() => {
            this.isLoadingAdv = true;
            this.restartBtn.node.getChildByName("loading").active = true;;
        });
        DMAdsSDKMgr.Instance.SetRewardedVideoAdLoadFailedCallback(() => {
            this.isLoadingAdv = false;
            this.restartBtn.node.getChildByName("loading").active = false;
        });
    }
    // update (dt) {}
}
