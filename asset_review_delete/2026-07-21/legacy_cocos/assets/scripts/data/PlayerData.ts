
export default class PlayerData {
    /**
     * 玩了多少次小程序游戏，用户每打开一次小程序统计一次
     */
    public playTimes: number = 0;

    /**
     * 登录天数
     */
    public logindays: number = 0;

    /**
     * 玩游戏的次数
     */
    public gameTimes: number = 0;

    /**
     * 玩家得分 
     */
    public score: number = 0;


    public init() {

    }

    public reset() {
        this.score = 0;
    }

    public addScore(value: number) {
        this.score += value;
        //TODO:如果要排行榜则要上传分数至服务器
    }
}