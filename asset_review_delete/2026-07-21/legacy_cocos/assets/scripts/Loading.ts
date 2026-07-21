import Mathf from "./util/Mathf";
import ResourcesManager from "./core/ResourcesManager";
import { ViewName } from "./ui/UIManager";

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
export default class Loading extends cc.Component {

    /** 加载进度 */
    @property(cc.Label)
    labProgress: cc.Label = null;
    /** 进度条 */
    @property(cc.ProgressBar)
    progressBar: cc.ProgressBar = null;

    //虚假进度
    private shamProgress: number = 0.8;
    //加载进度
    private progress: number = 0;

    //进度条是否加载完毕
    private progressFinish: boolean = false;

    //场景加载进度
    sceneProgress = 0;

    //预制体总数
    prefabAll: number = 1;
    //预制体已加载个数
    prefabCount: number = 1;

    start() {
        this.sceneProgress = 0;
        cc.director.preloadScene("game", (completedCount: number, totalCount: number, item: any) => {
            this.sceneProgress = completedCount / totalCount;
            //console.log(this.shamProgress, completedCount, totalCount);
        }, (error) => {

        });
        this.prefabAll = 1;
        this.prefabCount = 1;

        this.loadPreAssent();

        this.progressFinish = false;
    }

    update(dt: number): void {
        if (this.progressFinish) return;
        let currentProgress = Math.min(this.sceneProgress, this.prefabCount / this.prefabAll);
        this.shamProgress = Math.max(currentProgress, this.shamProgress);

        let speed = this.shamProgress == 1 ? dt * 5 : dt;
        this.progress = Mathf.lerp(this.progress, this.shamProgress, speed);
        this.labProgress.string = Math.floor(this.progress * 100) + "%";
        if (this.progress > 0.99 && this.shamProgress == 1) {
            this.labProgress.string = "100%";
            this.progress = this.shamProgress;
            this.progressFinish = true;
            this.scheduleOnce(() => {
                cc.director.loadScene("game");
            }, 0.2)
        }
        this.progressBar.progress = this.progress;
    }

    loadPreAssent() {

        this.prefabAll++;
        ResourcesManager.instance.load("view/" + ViewName.AccountView, () => {
            this.prefabCount++;
        });

        this.prefabAll++;
        ResourcesManager.instance.load("view/" + ViewName.SuccessShowView, () => {
            this.prefabCount++;
        });
    }

    // update (dt) {}
}
