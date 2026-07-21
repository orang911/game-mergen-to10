import GameScene from "../gameScene/GameScene";
import Block from "../coreFight/Block";

const { ccclass, property } = cc._decorator;

export enum GameStatus {
    none,
    /**
     * 开始游戏
     */
    start,

    /**
     * 游戏结束
     */
    over,

    /**
     * 游戏暂停
     */
    pause,
}


@ccclass
export default class GameManager extends cc.Component {

    public static get instance() {
        return this._instance;
    }
    private static _instance: GameManager = null;

    public gameStatus: GameStatus = GameStatus.none;

    @property(cc.Node)
    touchContent: cc.Node = null;

    @property(GameScene)
    gameScene: GameScene = null;

    @property(cc.Prefab)
    blockPrefab: cc.Prefab = null;

    @property([cc.SpriteFrame])
    blockCommomIcons: cc.SpriteFrame[] = [];

    @property([cc.SpriteFrame])
    blockSelectIcons: cc.SpriteFrame[] = [];

    onLoad() {
        GameManager._instance = this;
    }

    start() {

    }

    getBlock(level: number) {
        let block: Block = null;

        let node = cc.instantiate(this.blockPrefab);
        block = node.getComponent(Block);
        block.level = level;
        block.selected = false;
        return block;
    }

    // update (dt) {}
}
