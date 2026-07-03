// Learn TypeScript:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/typescript.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/typescript.html
// Learn Attribute:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/reference/attributes.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/life-cycle-callbacks.html
//  - [English] http://www.cocos2d-x.org/docs/creator/manual/en/scripting/life-cycle-callbacks.html

const { ccclass, property } = cc._decorator;

@ccclass
export default class ResourcesManager extends cc.Component {

    private static _instance: ResourcesManager;
    public static get instance(): ResourcesManager {
        if (this._instance == null) {
            this._instance = new ResourcesManager();
            this._instance.init();
        }
        return ResourcesManager._instance;
    }

    private jsonRoot = "configtable/";

    //private prefabDic:{[key:string]:cc.Prefab} = {};

    private assetDic: { [key: string]: cc.Asset } = {};

    private loadQueue = [];

    private waitingQueue = [];

    /**
     * 最大同时加载资源数量
     */
    private maxLoadCount: number = 5;


    private init() {

    }


    public loadJson(jsonName: string, callback: Function) {
        cc.loader.loadRes(this.jsonRoot + jsonName, (error, data) => {
            if (!error) {
                callback(data.json, jsonName);
            } else {
                cc.log("json" + jsonName + "加载失败 ", error);
            }
        });
    }
    
    public load(resName: string, callback: Function = null, type: typeof cc.Asset = cc.Prefab, isCache: boolean = true, isInstant: boolean = true, root: string = "prefab/") {
        var path: string = root + resName;

        if (this.assetDic[path]) {
            if (isInstant) {
                if (this.assetDic[path] instanceof cc.Prefab) {
                    var node: cc.Node = cc.instantiate(this.assetDic[path] as cc.Prefab);
                    callback && callback(node);
                }
            } else {
                callback && callback(this.assetDic[path]);
            }

            return;
        }

        var loadData: object = {
            path: path,
            type: type,
            callback: callback,
            isCache: isCache,
            isInstant: isInstant,
        };

        var i: number = 0;

        for (i = 0; i < this.loadQueue.length; i++) {
            if (this.loadQueue[i].path == path) {
                this.loadQueue[i].loadDatas.push(loadData);
                return;
            }
        }

        for (i = 0; i < this.waitingQueue.length; i++) {
            if (this.waitingQueue[i].path == path) {
                this.waitingQueue[i].loadDatas.push(loadData);
                return;
            }
        }

        var loadObj: Object = {
            path: path,
            type: type,
            isCache: isCache,
            loadDatas: [loadData]
        };

        if (this.loadQueue.length < this.maxLoadCount) {
            this.loadQueue.push(loadObj);
            this.loadRes(loadObj);
        } else {
            this.waitingQueue.push(loadObj);
        }

    }

    public loadImage(imgName: string, sprite: cc.Sprite = null, callback: Function = null, isCache: boolean = true, root: string = "image/"): void {
        this.load(imgName, (spriteFrame: cc.SpriteFrame) => {

            if (sprite) {
                sprite.spriteFrame = spriteFrame;

                if (spriteFrame && sprite.node) {
                    sprite.node.width = spriteFrame.getRect().width;
                    sprite.node.height = spriteFrame.getRect().height;
                }
            }

            callback && callback(spriteFrame);

        }, cc.SpriteFrame, isCache, false, root);
    }


    private loadRes(loadObj: any): void {
        cc.loader.loadRes(loadObj.path, loadObj.type, (error, asset) => {

            if (!error) {
                this.loadResComp(loadObj, asset);
            } else {
                cc.log("加载资源失败 path", loadObj.path, error.toString());
                this.loadResComp(loadObj, null);
            }
        });
    }

    /**
     *资源加载完成
    * @param preIconId
    * 
    */
    private loadResComp(loadObj: any, asset: cc.Asset): void {

        if (asset && loadObj.isCache) {
            this.assetDic[loadObj.path] = asset;
        }

        loadObj.loadDatas.forEach(loadData => {

            var callback: Function = loadData.callback;

            if (callback) {
                if (loadData.isInstant && asset instanceof cc.Prefab) {
                    var node: cc.Node = cc.instantiate(asset as cc.Prefab);
                    callback(node);
                } else {
                    callback(asset);
                }
            }
        });

        var index: number = this.loadQueue.indexOf(loadObj);
        if (index != -1) {
            this.loadQueue.splice(index, 1);
        }

        this.loadWaitRes();
    }

    /**
     *前一个已加载完的图标id 
    * @param preIconId
    * 
    */
    private loadWaitRes(): void {
        if (this.loadQueue.length < this.maxLoadCount && this.waitingQueue.length > 0) {
            var loadObj: any = this.waitingQueue.shift();
            this.loadQueue.push(loadObj);
            this.loadRes(loadObj);
        }
    }


}
