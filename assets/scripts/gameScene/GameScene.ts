import GameManager, { GameStatus } from "../core/GameManager";
import Block from "../coreFight/Block";
import CountdownLunch from "../util/CountdownLunch";
import UIManager, { ViewName } from "../ui/UIManager";
import SoundManager from "../core/SoundManager";
import { SoundClipType } from "../auto/SoundClip";
import DMAdsSDKMgr from "../util/DMAdsSDKMgr";


const { ccclass, property } = cc._decorator;
const max_line_num = 5;
const max_raw_num = 5;
const block_width = 132;

@ccclass
export default class GameScene extends cc.Component {


    @property(cc.Node)
    blockLayer: cc.Node = null;

    @property(cc.Node)
    effectLayer: cc.Node = null;

    @property(cc.Label)
    scoreText: cc.Label = null;

    @property(cc.Animation)
    mergenEffect: cc.Animation = null;

    blockMap: { [index: number]: Block } = {};

    indexMap: number[][] = [];

    selectBlockArr: Block[] = [];

    currentLevel: number = 0;

    blockCount = 0;

    score: number = 0;

    start() {
        for (let i = 0; i < max_line_num; i++) {
            this.indexMap[i] = [];
            for (let j = 0; j < max_raw_num; j++) {
                this.indexMap[i][j] = -1;
            }
        };
    }

    startGame() {
        UIManager.instance.mainUI.close();
        this.node.active = true;
        this.scheduleOnce(() => {
            //下一帧执行
            this.firstCreateBlock(() => {
                GameManager.instance.gameStatus = GameStatus.start;
                UIManager.instance.gameUI.open();
            });
        }, 0.02);

        DMAdsSDKMgr.Instance.onGameStateChanged(0, "开始游戏");
    }

    replayGame() {
        GameManager.instance.gameStatus = GameStatus.pause;
        this.clearGameWorld();
        this.firstCreateBlock(() => {
            GameManager.instance.gameStatus = GameStatus.start;
        });

        DMAdsSDKMgr.Instance.onGameStateChanged(1, "重新开始");
    }

    /**
     * 刷新分数
     */
    refreshScore(mergenNum: number, level: number) {
        this.score += (mergenNum - 1) * level * 2;
        this.scoreText.node.runAction(
            cc.sequence(
                cc.scaleTo(0.15, 1.5),
                cc.callFunc(() => {
                    this.scoreText.string = "" + this.score;
                }),
                cc.scaleTo(0.1, 1)/* .easing(cc.easeBounceInOut()), */
            )
        );
    }

    firstCreateBlock(callFunc?: Function) {
        this.scoreText.string = "0";
        this.score = 0;

        let index = this.blockCount;
        for (let y = 0; y < max_line_num; y++) {
            for (let x = 0; x < max_raw_num; x++) {
                let randNum = Math.floor(Math.random() * 3) + 1;
                let block = GameManager.instance.getBlock(randNum);
                block.node.parent = this.blockLayer;
                block.index = index;
                block.site = cc.v2(x, y);
                block.ceateMove(index * 0.04);

                this.blockMap[index] = block;
                this.indexMap[y][x] = index;

                index++;
            }
        }
        this.blockCount = index;
        this.scheduleOnce(() => {
            callFunc && callFunc();
        }, index * 0.04 + 0.3);
    }

    getPosBySite(site: cc.Vec2) {
        let { x, y } = site;
        return cc.v2((x - 2) * block_width, (y - 2) * block_width)
    }

    /**
     * 双击未选中方块后所有相邻的同等级方块变为被选中状态
     */
    selectNextBlocks(clickBlock: Block) {
        let level = clickBlock.level;

        for (const block of this.selectBlockArr) {
            block.selected = false;
        }
        this.selectBlockArr.length = 0;

        //合成10级后的方块不再可以选择
        if (clickBlock.level >= 10) {
            return;
        }

        this.DEFCheckSelect(clickBlock, level);

        if (this.selectBlockArr.length == 1) {
            clickBlock.selected = false;
        }
    }

    private DEFCheckSelect(block: Block, level: number) {
        if (!block || block.level != level || block.selected) {
            return;
        }
        block.selected = true;
        this.selectBlockArr.push(block);

        let { x, y } = block.site;

        y - 1 >= 0 && this.DEFCheckSelect(this.blockMap[this.indexMap[y - 1][x]], level);
        y + 1 < max_line_num && this.DEFCheckSelect(this.blockMap[this.indexMap[y + 1][x]], level);
        x - 1 >= 0 && this.DEFCheckSelect(this.blockMap[this.indexMap[y][x - 1]], level);
        x + 1 < max_raw_num && this.DEFCheckSelect(this.blockMap[this.indexMap[y][x + 1]], level);
    }

    /**
     * 双击选中状态中的方块时，合并所有已选中方块至点击方块位置
     */
    mergeSelectBlocks(clickBlock: Block) {
        //点击合成音效
        SoundManager.instance.playAudioClip(SoundClipType.mergen);

        //播放合成特效
        this.playMergetEffect(clickBlock);

        //开始消除时锁定游戏，防止多次调用方块按钮事件
        GameManager.instance.gameStatus = GameStatus.pause;

        let clickIndex = this.selectBlockArr.indexOf(clickBlock);
        let length = this.selectBlockArr.length;
        let actionTime = 0.3 / length;//合并动作的总时长为0.2
        let max = Math.max(length - 1 - clickIndex, clickIndex);

        let countdownLunch = new CountdownLunch<any>(() => {

            //console.log(this.blockMap);
            //console.log(this.indexMap);
            //console.log(this.blockLayer.children);

            //刷新分数显示
            this.refreshScore(length, clickBlock.level);

            this.selectBlockArr.length = 0;
            clickBlock.hadMergen = false;
            clickBlock.selected = false;
            clickBlock.level++;

            //刷新当前最大方块等级
            if (clickBlock.level > this.currentLevel) {
                this.currentLevel = clickBlock.level;
            }

            //合到10后消除10,并弹窗提示
            if (clickBlock.level == 10) {
                this.scheduleOnce(() => {
                    this.fallAction(() => {
                        clickBlock.removeAction(() => {
                            this.fallAction(() => {
                                UIManager.instance.OpenView(ViewName.SuccessShowView);
                            })
                        });
                    });
                }, 0.05);
            } else {
                this.scheduleOnce(() => {
                    this.fallAction();
                }, 0.05);
            }
        }, length - 1);

        for (let key in this.selectBlockArr) {
            let index = parseInt(key);
            if (index == clickIndex) continue;

            const block = this.selectBlockArr[index];

            let sub = index - clickIndex;
            let nextIndex = index;
            if (sub > 0) {
                nextIndex--;
            } else if (sub < 0) {
                nextIndex++;
            }

            block.node.runAction(
                cc.sequence(
                    cc.delayTime((max - Math.abs(sub)) * actionTime),
                    cc.spawn(
                        cc.moveTo(actionTime, this.selectBlockArr[nextIndex].node.position),
                        cc.fadeOut(actionTime)
                    ),
                    cc.callFunc(() => {
                        countdownLunch.countdown();
                        block.removeSelf();
                    }),
                )
            );
        }
    }

    private playMergetEffect(clickBlock: Block) {
        let pos = clickBlock.node.position;
        pos.subSelf(this.blockLayer.position);

        this.mergenEffect.node.position = cc.v2(pos);

        this.mergenEffect.node.active = true;
        let time = this.mergenEffect.play().duration;
        this.scheduleOnce(() => {
            this.mergenEffect.node.active = false;
        }, time);
    }

    /**
     * 合并方块后方块下落填满界面
     */
    fallAction(callFunc?: Function) {
        let countdown1 = new CountdownLunch<any>(() => {
            /**
             * 生成新的方块
             */
            let createLevel = (this.currentLevel > 4 ? 4 : 3);

            let countdown2 = new CountdownLunch<any>(() => {

                if (!this.checkFail()) {
                    //所有方块下落动作完成后，取消游戏锁定
                    GameManager.instance.gameStatus = GameStatus.start;
                    callFunc && callFunc();
                } else {
                    this.endAction(false);
                }
            }, 1);
            for (let y = 0; y < max_line_num; y++) {
                for (let x = 0; x < max_raw_num; x++) {
                    let index = this.indexMap[y][x];
                    if (index == -1) {
                        let randNum = Math.floor(Math.random() * createLevel) + 1;
                        let block = GameManager.instance.getBlock(randNum);
                        block.node.parent = this.blockLayer;
                        block.index = this.blockCount;
                        block.site = cc.v2(x, y);

                        countdown2.count++;
                        block.ceateMove(0, () => {
                            countdown2.countdown();
                        });

                        this.blockMap[this.blockCount] = block;
                        this.indexMap[y][x] = this.blockCount;
                        this.blockCount++;
                    }
                }
            };
            countdown2.countdown();
        }, 1);

        /**
         * 原有方块下落
         */
        for (let y = 0; y < max_line_num; y++) {
            for (let x = 0; x < max_raw_num; x++) {
                let index = this.indexMap[y][x];
                if (index != -1) {
                    let newSite = cc.v2(x, y);
                    let hadChange = false;
                    while (newSite.y - 1 >= 0 && this.indexMap[newSite.y - 1][newSite.x] == -1) {
                        newSite.y--;
                        hadChange = true;
                    }
                    if (hadChange) {
                        this.indexMap[newSite.y][newSite.x] = index;
                        this.indexMap[y][x] = -1;
                        countdown1.count++;
                        this.blockMap[index].fall(newSite, () => {
                            countdown1.countdown();
                        });
                    }
                }
            }
        };
        countdown1.countdown();
    }

    /**
     * 复活动作
     */
    resurAction() {

        DMAdsSDKMgr.Instance.onGameStateChanged(1, "复活");
        //清除当前场景中最小等级的方块

        //获得当前最小等级
        let minLevel = 0;
        //console.log(this.blockLayer.childrenCount, this.effectLayer.childrenCount);
        for (let i = 0; i < this.blockLayer.childrenCount; i++) {
            let block = this.blockLayer.children[i].getComponent(Block);
            if (block) {
                if (minLevel == 0 || minLevel > block.level) {
                    minLevel = block.level;
                }
            }
        }

        let countdown = new CountdownLunch<any>(() => {
            //复活动作结束后,执行原有下落逻辑
            this.scheduleOnce(() => {
                this.fallAction();
            }, 0.05);
        }, 1);

        //消除所有最小等级的方块
        for (const key in this.blockMap) {
            if (this.blockMap.hasOwnProperty(key)) {
                const block = this.blockMap[key];
                if (block && block.level == minLevel) {
                    countdown.count++;
                    block.removeAction(() => {
                        countdown.countdown();
                    });
                }
            }
        }
        countdown.countdown();
    }

    /**
     * 判断游戏是否结束
     */
    checkFail() {
        for (let y = 0; y < max_line_num; y++) {
            for (let x = 0; x < max_raw_num; x++) {
                let index = this.indexMap[y][x];
                if (index == -1) continue;
                let block = this.blockMap[index];
                //10级方块不能合并,故不参与结束判定
                if (block.level >= 10) continue;

                if (this.checkHadNext(block)) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * 判断是否有相邻的同级方块
     */
    checkHadNext(block: Block) {
        let { x, y } = block.site;
        let level = block.level;
        if (y - 1 >= 0 && this.blockMap[this.indexMap[y - 1][x]].level == level) {
            return true;
        }
        if (y + 1 < max_line_num && this.blockMap[this.indexMap[y + 1][x]].level == level) {
            return true
        }
        if (x - 1 >= 0 && this.blockMap[this.indexMap[y][x - 1]].level == level) {
            return true;
        }
        if (x + 1 < max_raw_num && this.blockMap[this.indexMap[y][x + 1]].level == level) {
            return true;
        }
        return false;
    }

    /**
     * 结束游戏动作
     */
    endAction(hadPass: boolean) {
        GameManager.instance.gameStatus = GameStatus.over;

        if (hadPass) {
            DMAdsSDKMgr.Instance.onGameStateChanged(4, "游戏成功");
            //胜利动作
            this.scheduleOnce(() => {
                UIManager.instance.OpenView(ViewName.AccountView);
            }, 0.5);
        } else {
            DMAdsSDKMgr.Instance.onGameStateChanged(3, "无可合成方块");
            //失败动作
            let failCountdown = new CountdownLunch<any>(() => {

                UIManager.instance.OpenView(ViewName.AccountView);

            }, this.blockLayer.childrenCount);

            this.blockLayer.children.forEach(node => {
                let delayTime = Math.random();
                node.runAction(
                    cc.sequence(
                        cc.delayTime(delayTime + 0.3),
                        cc.moveBy(0.1, cc.v2(0, 15)),
                        cc.moveBy(0.1, cc.v2(0, -15)),
                        cc.callFunc(() => {
                            failCountdown.countdown();
                        })
                    )
                );
            });
        }
    }

    /**
     * 从游戏场景中删除方块
     * @param block 
     */
    removeBlock(block: Block) {
        let { x, y } = block.site;
        let index = this.indexMap[y][x];
        this.indexMap[y][x] = -1;
        this.blockMap[index] = null;
    }

    /**
     * 清除游戏世界数据
     */
    private clearGameWorld() {
        for (const key in this.blockMap) {
            if (this.blockMap.hasOwnProperty(key)) {
                const block = this.blockMap[parseInt(key)];
                block && block.node.removeFromParent();
            }
        }
        this.blockMap = {};
        this.blockCount = 0;
        this.currentLevel = 0;
    }

    overGame() {
        this.clearGameWorld();
        this.node.active = false;
        UIManager.instance.mainUI.open();
        UIManager.instance.gameUI.close();
        //cc.director.loadScene("game");
    }

    // update (dt) {}
}
