import View from "./View";
import MainUI from "./mainUI/MainUI";
import GameUI from "./mainUI/GameUI";
import ResourcesManager from "../core/ResourcesManager";

const { ccclass, property } = cc._decorator;

@ccclass
export default class UIManager extends cc.Component {

    private static _instance: UIManager;

    public static get instance(): UIManager {
        /*if(this._instance == null)
        {
            this._instance = new UIManager();
            this._instance.init();
        }*/
        return UIManager._instance;
    }

    private static viewDic: { [key: string]: View } = {};

    @property(cc.Node)
    private viewLayers: Array<cc.Node> = [];

    @property(MainUI)
    public mainUI: MainUI = null;

    @property(GameUI)
    public gameUI: GameUI = null;

    constructor() {
        super();
    }

    onLoad() {
        UIManager._instance = this;
        UIManager._instance.init();
    }

    private init() {
    }

    start() {

    }

    /**
     * 打开一个界面
     * @param viewName 
     * @param callback 
     * @param layerType 
     * @param root 
     */
    public OpenView(viewName: string, callback: Function = null, layerType: LayerType = LayerType.popup, root: string = "prefab/view/") {
        var path = root + viewName;

        if (UIManager.viewDic[viewName]) {
            var view: View = UIManager.viewDic[viewName];
            view.node.setParent(null);
            this.viewLayers[layerType].addChild(view.node);
            view.node.position = cc.Vec2.ZERO;
            view.open();

            if (callback) {
                callback.apply(this, [UIManager.viewDic[viewName]]);
            }
            return;
        }

        ResourcesManager.instance.load("view/" + viewName, (prefab) => {
            if (UIManager.viewDic[viewName]) {
                //防止同时生成多个相同窗口
                return;
            }
            var node: cc.Node = cc.instantiate(prefab);
            var view: View = node.getComponent(View);
            //view.node.setParent(this.viewLayers[layerType]);
            view.node.setParent(null);
            this.viewLayers[layerType].addChild(view.node);
            view.node.position = cc.Vec2.ZERO;
            view.open();
            cc.log("加载到的资源", prefab, view.name);
            UIManager.viewDic[viewName] = view;
            if (callback != null) {
                callback.apply(this, [view]);
            }

        }, cc.Prefab);
    }

    /**
     * 关闭一个界面
     * @param viewName 
     * @param isDele 
     */
    public closeView(viewName: string, isDele: boolean = true): boolean {
        if (UIManager.viewDic[viewName]) {
            UIManager.viewDic[viewName].close();
            UIManager.viewDic[viewName].node.setParent(null);
            if (isDele) {
                UIManager.viewDic[viewName].destroySelf();
                UIManager.viewDic[viewName] = null;
                delete UIManager.viewDic[viewName];
            }
            return true;
        }

        return false;

    }

    public getLayer(layerType: LayerType): cc.Node {
        return this.viewLayers[layerType];
    }

    /**
     * 当前是否有View窗口弹出
     */
    public hasViewShow(): boolean {

        for (var i = 0; i < this.viewLayers.length; i++) {
            if (this.viewLayers[i].childrenCount > 0) {
                return true;
            }
        }

        return false;
    }
}

export class ViewName {
    public static AccountView = "AccountView";
    public static SuccessShowView = "SuccessShowView";
}

export enum LayerType {
    back = 0,
    popup,
}
