

const { ccclass, property } = cc._decorator;

export enum BgSoundClipType {
    none = 0,
    main = 1,
}

@ccclass
export default class BgSoundClip extends cc.Component {
    @property(cc.String)
    public clipName: string = "";

    @property({ type: cc.Enum(BgSoundClipType) })
    public type: BgSoundClipType = BgSoundClipType.none;

    @property({ type: cc.AudioClip })
    public clip: cc.AudioClip = null;
}