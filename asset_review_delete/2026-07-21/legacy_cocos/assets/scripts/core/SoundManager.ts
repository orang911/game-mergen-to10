import BgSoundClip, { BgSoundClipType } from "../auto/BgSoundClio";
import SoundClip, { SoundClipType } from "../auto/SoundClip";


const { ccclass, property } = cc._decorator;

@ccclass
export default class SoundManager extends cc.Component {

    private static _instance: SoundManager;
    public static get instance(): SoundManager {
        if (this._instance == null) {
            /*cc.loader.loadRes("prefab/SoundManager",cc.Prefab,(err,prefab)=>{
                var node:cc.Node = cc.instantiate(prefab);
                this._instance = node.getComponent(SoundManager);
            });*/
            //this._instance = new SoundManager();
            //this._instance.init();
        }
        return SoundManager._instance;
    }

    @property(cc.AudioSource)
    private bgAS: cc.AudioSource = null;

    private audioDic: { [key: number]: cc.AudioClip }

    /// <summary>
    /// 背景声音
    /// </summary>
    //@property(BgSoundClip)
    //public bgSoundClips:BgSoundClip[] = [];
    @property(cc.Node)
    private bgSoundSrc: cc.Node = null;
    private bgSoundDic: { [key: number]: BgSoundClip } = {};

    @property(cc.Node)
    private soundSrc: cc.Node = null;
    private soundDic: { [key: number]: SoundClip } = {};

    private lastBgSound: BgSoundClipType = BgSoundClipType.none;

    public get isMute() {
        return this.mute;
    }
    /**
     * 是否静音
     */
    private mute: boolean = false;

    /**
     * 是否静音
     */
    private bgsMute: boolean = false;

    /**
     * 是否静音
     */
    private clipMute: boolean = false;

    onLoad() {
        if (!SoundManager._instance) {
            SoundManager._instance = this;
            cc.game.addPersistRootNode(this.node);
            this.init();
        } else {
            this.node.destroy();
        }
    }

    private init() {
        var children: cc.Node[] = this.bgSoundSrc.children;
        for (var i = 0; i < children.length; i++) {
            var bgSoundClip: BgSoundClip = children[i].getComponent(BgSoundClip);
            this.bgSoundDic[bgSoundClip.type] = bgSoundClip;
        }

        children = this.soundSrc.children;
        for (var i = 0; i < children.length; i++) {
            var soundClip: SoundClip = children[i].getComponent(SoundClip);
            this.soundDic[soundClip.type] = soundClip;
        }

        this.node.parent = null; //把声音父容器置空，否在加载场景后声音会重新播放


        /* cc.systemEvent.on("platformGameShow", () => {
            var bgs: BgSoundClipType = this.lastBgSound;
            this.lastBgSound = BgSoundClipType.none;
            this.PlayBGSound(bgs);
        }); */

    }

    public pause() {
        this.mute = true;
        cc.audioEngine.pauseAll();
        this.bgAS.pause();
    }

    public resume() {
        this.mute = false;
        cc.audioEngine.resumeAll();
        this.bgAS.resume();
    }

    public PlayBGSound(type: BgSoundClipType, loop: boolean = true) {

        if (this.lastBgSound == type) {
            return;
        }

        this.lastBgSound = type;

        if (this.lastBgSound == BgSoundClipType.none) {
            this.bgAS.stop();
            return;
        }

        this.bgAS.stop();
        this.bgAS.loop = loop;
        this.bgAS.clip = this.getBGSoundClip(type);
        if (!this.mute && !this.bgsMute) {
            this.bgAS.play();
        } else {
            this.bgAS.play();
            this.bgAS.pause();
        }
    }

    public StopBgSound() {
        this.bgAS.stop();
    }

    public ReplayBgSound() {
        this.bgAS.play();
    }

    public PauseBgSound() {
        this.bgsMute = true;
        this.bgAS.pause();
    }

    public ResumeBgSound() {
        this.bgsMute = false;
        this.bgAS.resume();
    }

    public PauseClipSound() {
        this.clipMute = true;
        cc.audioEngine.pauseAll();
    }

    public ResumeClipSound() {
        this.clipMute = false;
        cc.audioEngine.resumeAll();
    }

    public getBGSoundClip(type: BgSoundClipType): cc.AudioClip {
        if (this.bgSoundDic[type]) {
            return this.bgSoundDic[type].clip;
        }
        else {
            cc.log("不存在背景声音源 ", BgSoundClipType[type]);
            return null;
        }
    }

    public playAudioClip(type: SoundClipType, volume: number = 1) {

        if (this.mute || this.clipMute) {
            return;
        }

        var clip: cc.AudioClip = this.getSoundClip(type);

        if (clip != null) {
            cc.audioEngine.play(clip, false, volume);
        }
        else {
            cc.log("找不到资源id为 ", type, " PlayOtherSound声音配置");
        }
        //
    }

    public getSoundClip(type: SoundClipType): cc.AudioClip {
        if (this.soundDic[type]) {
            return this.soundDic[type].clip;
        }
        else {
            cc.log("不存在该种声音源 " + SoundClipType[type]);
            return null;
        }
    }
}
