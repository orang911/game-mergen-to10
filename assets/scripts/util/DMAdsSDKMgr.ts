const { ccclass, property } = cc._decorator;
/**
 * SDK管理器
 */
export default class DMAdsSDKMgr {
    /** 单例 */
    public static readonly Instance: DMAdsSDKMgr = new DMAdsSDKMgr();

    private constructor() {
    }

    private dmApi = window["DoMobile"];

    private rewardedCallback: Function = null;

    private rewardedVideoAdLoadingCallback: Function = null;  //显示广告时回调 正在加载广告 (可做按钮置灰处理)

    private rewardedVideoAdLoadFailedCallback: Function = null;  //显示广告时回调加载失败 (可恢复之前置灰的按钮)

    /**
     *     设置激励视频回调函数
     */
    public SetRewardedCallback(callback: Function) {
        this.rewardedCallback = callback;
    }

    /**
     *     设置激励视频正在Loading回调
     */
    public SetRewardedVideoAdLoadingCallback(callback: Function) {
        this.rewardedVideoAdLoadingCallback = callback;
    }

    /**
     *     设置激励视频加载失败
     */
    public SetRewardedVideoAdLoadFailedCallback(callback: Function) {
        this.rewardedVideoAdLoadFailedCallback = callback;
    }

    public Test(msg) {
        this.dmApi.onGameInvoke(msg)
    }

    /**
     * 改变屏幕方向 入参orientation说明 -> 0:竖屏 1:横屏
     */
    public changeOrientation(orientation) {
        if (this.dmApi)
            this.dmApi.changeOrientation(orientation)
    }

    /**
     *     游戏状态改变 入参state说明 -> 0: 开始游戏 正式开始某小游戏时上报（如点开始按钮）
     *      1: 重玩游戏 重新开始某小游戏时（复活、重新挑战等)
     *      2: 消耗道具 消耗任意类型道具时
     *      3: 游戏失败 游戏失败时（犯规、超时、等等）
     *      4: 游戏成功（如每次闯关成功)
     *      入参value说明 -> 游戏成功时 传关卡数
     */
    public onGameStateChanged(state: number, value: string) {
        if (this.dmApi)
            this.dmApi.onGameStateChanged(state, value)
    }

    /**
     *     加载插屏广告
     */
    public loadInterstitialAd() {
        if (this.dmApi)
            this.dmApi.loadInterstitialAd()
    }

    /**
     * 显示插屏广告
     */
    public showInterstitialAd() {
        if (this.dmApi)
            this.dmApi.showInterstitialAd()
    }

    /**
     *     加载激励视频广告
     */
    public loadRewardedVideo() {
        if (this.dmApi)
            this.dmApi.loadRewardedVideo()
    }

    /**
     *     显示激励视频广告 入参rewardId说明 -> 用于观看完成回传给游戏
     */
    public showRewardedVideoAd(rewardId: string = "", rewardedCallback: Function = null, loadingCallback: Function = null, loadFailCallback: Function = null) {
        if (rewardedCallback)
            this.rewardedCallback = rewardedCallback;
        if (loadingCallback)
            this.rewardedVideoAdLoadingCallback = loadingCallback;
        if (loadFailCallback)
            this.rewardedVideoAdLoadFailedCallback = loadFailCallback;
        if (this.dmApi) {
            this.dmApi.showRewardedVideoAd(rewardId)
        } else {
            rewardedCallback("1");
        }
    }

    /**
     * 暂停正在loading后直接加载的广告   只有调用了showRewardedVideoAd回调了正在加载状态时候 需要主动调用这个方法
     * 例如: 调用showRewardedVideoAd方法后  APP端回调rewardedVideoAdLoading   如果此时我们做了其他操作就要取消掉加载后播放广告
     */
    public stopRewardedVideoAd() {
        if (this.dmApi)
            this.dmApi.stopRewardedVideoAd()
    }


    /**
     * 插屏广告结果回调  results:是否显示成功  不成功的原因可能是没有加载到广告
     */
    public interstitialAdCallback(results) {
        //一般无需处理 插屏广告一般为游戏结束时插播显示  无需给奖励
        console.log("插屏广告结果回调:", results)
    }

    /**
     * 逻辑说明:
     当调用 showRewardedVideoAd 方法时
     如果当前没有激励视频广告,则会重新加载激励视频广告并回调 rewardedVideoAdLoading 方法
     ->加载成功 则直接显示激励视频广告
     ->加载失败 则回调 rewardedVideoAdLoadFailed 方法
     如果当前已有激励视频广告,则直接显示
     */
    public rewardedVideoAdLoading() {
        DMAdsSDKMgr.Instance.rewardedVideoAdLoadingCallback && DMAdsSDKMgr.Instance.rewardedVideoAdLoadingCallback()
        //这个时候可以将广告按钮 置灰或者loading显示 (应要求 说要给一个无广告播放或者广告还在加载 的用户反馈)
        console.log("激励视频广告显示失败,正在加载")
    }

    public rewardedVideoAdLoadFailed() {
        //这个时候需要把置灰的按钮恢复正常状态  注意:下面的 rewardedVideoAdCallback也需要处理恢复按钮状态
        DMAdsSDKMgr.Instance.rewardedVideoAdLoadFailedCallback && DMAdsSDKMgr.Instance.rewardedVideoAdLoadFailedCallback();
        console.log("激励视频广告加载显示失败回调")
    }

    /**
     *     激励视频广告 结果回调
     *     @results 是否播放完成 '1':成功 '0':失败,
     *     @rewardId 用于观看完成回传给游戏 String
     */
    public rewardedVideoAdCallback(results, rewardId) {
        //这里也应做一次恢复置灰按钮状态
        console.log(results)
        console.log(rewardId)
        DMAdsSDKMgr.Instance.loadRewardedVideo()
        console.log(DMAdsSDKMgr.Instance.rewardedCallback)
        if (DMAdsSDKMgr.Instance.rewardedCallback) {
            DMAdsSDKMgr.Instance.rewardedCallback(results, rewardId)
        }
        //做一次按钮恢复操作
        DMAdsSDKMgr.Instance.rewardedVideoAdLoadFailedCallback && DMAdsSDKMgr.Instance.rewardedVideoAdLoadFailedCallback();
    }
}
cc["interstitialAdCallback"] = DMAdsSDKMgr.Instance.interstitialAdCallback;
cc["rewardedVideoAdLoading"] = DMAdsSDKMgr.Instance.rewardedVideoAdLoading;
cc["rewardedVideoAdLoadFailed"] = DMAdsSDKMgr.Instance.rewardedVideoAdLoadFailed;
cc["rewardedVideoAdCallback"] = DMAdsSDKMgr.Instance.rewardedVideoAdCallback;
