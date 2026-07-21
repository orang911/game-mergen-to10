import GameManager from "./core/GameManager";
import DataStorage from "./core/DataStorage";
import { DataManager } from "./core/DataManager";
import { BgSoundClipType } from "./auto/BgSoundClio";
import SoundManager from "./core/SoundManager";
import DMAdsSDKMgr from "./util/DMAdsSDKMgr";
import ResourcesManager from "./core/ResourcesManager";
import { ViewName } from "./ui/UIManager";
import CountdownLunch from "./util/CountdownLunch";

const { ccclass, property } = cc._decorator;

@ccclass
export default class Main extends cc.Component {
    private static alreadyPlay: boolean = false;

    @property(cc.Node)
    public canvas: cc.Node = null;

    onLoad() {
        this.canvas.active = false;

        DataManager.instance.loadComfigDatas(() => {
            if (!Main.alreadyPlay) {
                Main.alreadyPlay = true;
                DataManager.instance.getPlayerData().gameTimes++;
            }
            this.canvas.active = true;
        });


        DMAdsSDKMgr.Instance.loadRewardedVideo();
    }
}