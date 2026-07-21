


const { ccclass, property } = cc._decorator;


export enum SoundClipType {
    none = 0,
    click,
    mergen,
}

@ccclass
export default class SoundClip extends cc.Component {

    @property(cc.String)
    public clipName: string = "";

    @property({ type: cc.Enum(SoundClipType) })
    public type: SoundClipType = SoundClipType.none;

    @property({ type: cc.AudioClip })
    public clip: cc.AudioClip = null;

}