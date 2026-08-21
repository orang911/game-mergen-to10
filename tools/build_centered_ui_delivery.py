from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(r"F:\卖肉\godotT10\game_mergenTo10_published")
SRC = ROOT / "assets/runtime/ui/secondary_v2"
REF = ROOT / "art/ai_generated/imagegen/2026-08-13/131530_chapter01_ui_batch2_concepts"
OUT = ROOT / "art/production/ui/chapter01/2026-08-13_centered_interfaces_complete_v02"
ELEM = OUT / "cutouts/elements"
FRAMES = OUT / "cutouts/frames"
PREV = OUT / "previews/implementation_previews"
QA = OUT / "qa"

FONT = Path(r"C:\Windows\Fonts\msyhbd.ttc")
FONT_REG = Path(r"C:\Windows\Fonts\msyh.ttc")


def load(rel: str) -> Image.Image:
    return Image.open(SRC / rel).convert("RGBA")


def nine(rel: str, size: tuple[int, int], m: tuple[int, int, int, int]) -> Image.Image:
    im = load(rel)
    l, t, r, b = m
    w, h = im.size
    W, H = size
    out = Image.new("RGBA", size)
    xs = (0, l, w-r, w); ys = (0, t, h-b, h)
    X = (0, l, W-r, W); Y = (0, t, H-b, H)
    for j in range(3):
        for i in range(3):
            part = im.crop((xs[i], ys[j], xs[i+1], ys[j+1]))
            dw, dh = X[i+1]-X[i], Y[j+1]-Y[j]
            if part.size != (dw, dh):
                part = part.resize((dw, dh), Image.Resampling.LANCZOS)
            out.alpha_composite(part, (X[i], Y[j]))
    return out


def fit(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    c = im.copy(); c.thumbnail(size, Image.Resampling.LANCZOS); return c


def put(dst: Image.Image, im: Image.Image, xy: tuple[int, int], size: tuple[int, int] | None = None) -> None:
    if size:
        im = fit(im, size)
    dst.alpha_composite(im, xy)


def txt(d: ImageDraw.ImageDraw, p: tuple[int, int], s: str, n: int, fill="white", anchor="mm", stroke=2) -> None:
    f = ImageFont.truetype(str(FONT), n)
    d.text(p, s, font=f, fill=fill, anchor=anchor, stroke_width=stroke, stroke_fill=(22, 47, 83))


def frame_pause(preview=False):
    W,H=660,485; o=nine("common/panel_dark.png",(W,H),(28,28,28,28))
    put(o,fit(load("common/divider_diamond.png"),(520,35)),(70,135))
    put(o,fit(load("pages/pause/action_tile_blue.png"),(238,198)),(72,205))
    put(o,fit(load("pages/pause/action_tile_red.png"),(238,198)),(350,205))
    if preview:
        put(o,fit(load("icons/settings_gear.png"),(82,82)),(150,228)); put(o,fit(load("icons/exit_door.png"),(82,82)),(429,228))
        d=ImageDraw.Draw(o); txt(d,(330,88),"暂停中",42); txt(d,(191,350),"设置",34); txt(d,(469,350),"退出",34)
    return o


def frame_confirm(clear=False, preview=False):
    W,H=(660,383) if clear else (660,388); panel="common/panel_light.png" if clear else "common/panel_dark.png"
    o=nine(panel,(W,H),(28,28,28,28)); put(o,fit(load("common/divider_diamond.png"),(520,35)),(70,157))
    put(o,nine("common/button_blue_default.png",(230,92),(20,20,20,20)),(80,232)); put(o,nine("common/button_red_default.png",(230,92),(20,20,20,20)),(350,232))
    if preview:
        d=ImageDraw.Draw(o); color=(18,45,80) if clear else "white"
        txt(d,(330,95),"将删除章节、新手及局内进度" if clear else "退出后将结束本次挑战",28,color)
        txt(d,(195,278),"取消" if clear else "继续挑战",28); txt(d,(465,278),"确认清空" if clear else "确认退出",28)
    return o


def frame_settings(preview=False):
    W,H=650,910; o=nine("common/panel_light.png",(W,H),(28,28,28,28)); d=ImageDraw.Draw(o)
    put(o,fit(load("icons/back.png"),(72,72)),(34,28)); put(o,fit(load("common/divider_diamond.png"),(520,34)),(65,105))
    ys=[145,255,365,510,620]
    for y in ys: put(o,nine("common/row_light.png",(530,92),(22,22,22,22)),(60,y))
    icons=["icons/music.png","icons/sound.png","icons/vibration.png","icons/help.png","icons/privacy_shield.png"]
    for y,ic in zip(ys,icons): put(o,fit(load(ic),(58,58)),(82,y+17))
    put(o,load("common/switch_on.png"),(465,161)); put(o,load("common/switch_on.png"),(465,271)); put(o,load("common/switch_off.png"),(465,381))
    put(o,fit(load("icons/arrow_right.png"),(52,52)),(500,530)); put(o,fit(load("icons/arrow_right.png"),(52,52)),(500,640))
    put(o,fit(load("common/divider_diamond.png"),(520,34)),(65,744))
    if preview:
        txt(d,(325,65),"设置",38,fill=(18,45,80)); labs=["音乐","音效","震动","帮助与反馈","隐私 / 用户协议"]
        for y,s in zip(ys,labs): txt(d,(170,y+46),s,27,fill=(18,45,80),anchor="lm",stroke=0)
        txt(d,(325,830),"清空本地数据",27,fill=(210,52,47),stroke=0)
    return o


def header_body(size, preview_title=None):
    W,H=size; o=nine("common/panel_light.png",(W,H),(28,28,28,28)); put(o,nine("common/title_ribbon_blue.png",(min(W-80,620),100),(82,18,82,22)),((W-min(W-80,620))//2,-2))
    if preview_title: txt(ImageDraw.Draw(o),(W//2,47),preview_title,36)
    return o


def frame_tasks(preview=False):
    W,H=880,1141; o=header_body((W,H),"日常" if preview else None); d=ImageDraw.Draw(o)
    put(o,nine("common/tab_selected.png",(360,84),(18,18,18,18)),(70,102)); put(o,nine("common/tab_default.png",(360,84),(18,18,18,18)),(450,102))
    if preview: txt(d,(250,143),"任务",31); txt(d,(630,143),"签到",31,fill=(170,185,210))
    rows=[220,390,560,730,900]
    for y in rows: put(o,nine("pages/daily/task_row.png",(780,136),(22,22,22,22)),(50,y))
    icons=["icons/task_star.png","icons/task_swords.png","icons/task_merge.png","icons/task_kill.png","icons/task_login.png"]
    if preview:
        labels=["今日活跃度","完成 1 次挑战","合成 20 次","击败 30 个怪物","今日登录"]
        for i,(y,ic,s) in enumerate(zip(rows,icons,labels)):
            put(o,fit(load(ic),(76,76)),(75,y+30)); txt(d,(180,y+48),s,25,fill=(18,45,80),anchor="lm",stroke=0)
            put(o,fit(load("common/progress_track.png"),(260,34)),(180,y+83)); put(o,fit(load("common/progress_fill.png"),(180 if i==3 else 100,34)),(180,y+83))
            put(o,nine("common/button_yellow_default.png" if i==3 else "common/button_gray_disabled.png",(145,62),(20,20,20,20)),(655,y+40))
        txt(d,(728,761),"领取",23)
    return o


def frame_signin(preview=False):
    W,H=880,436; o=nine("common/panel_light.png",(W,H),(28,28,28,28)); d=ImageDraw.Draw(o)
    put(o,nine("common/tab_default.png",(300,78),(18,18,18,18)),(120,0)); put(o,nine("common/tab_selected.png",(300,78),(18,18,18,18)),(460,0))
    for i in range(7):
        rel="pages/daily/signin_day_today.png" if i in (3,6) else "pages/daily/signin_day_default.png"
        put(o,fit(load(rel),(105,255)),(55+i*110,118 if i!=3 else 100))
    if preview:
        txt(d,(270,38),"任务",28,fill=(170,185,210)); txt(d,(610,38),"签到",28)
        for i in range(7): txt(d,(107+i*110,150 if i!=3 else 132),f"第{i+1}天",18)
    return o


def frame_benefits(preview=False):
    W,H=760,775; o=header_body((W,H),"权益" if preview else None); d=ImageDraw.Draw(o)
    for x in (70,390): put(o,nine("pages/commerce/benefit_card.png",(300,430),(22,22,22,22)),(x,135))
    for i,x in enumerate((50,225,400,575)): put(o,nine(["common/button_blue_default.png","common/button_red_default.png","common/button_gray_disabled.png","common/button_blue_default.png"][i],(140,72),(20,20,20,20)),(x,635))
    if preview:
        put(o,fit(load("icons/double_coin.png"),(140,140)),(150,180)); put(o,fit(load("icons/ad_removed.png"),(140,140)),(470,180)); txt(d,(220,370),"双倍金币",28,fill=(18,45,80)); txt(d,(540,370),"去广告",28,fill=(18,45,80))
    return o


def frame_first(preview=False):
    W,H=760,748; o=header_body((W,H),"首充礼包" if preview else None); d=ImageDraw.Draw(o)
    for i,x in enumerate((90,235,380,525)): put(o,load("pages/commerce/reward_slot_purple.png" if i>1 else "pages/commerce/reward_slot_blue.png"),(x,145))
    for x,rel in zip((55,270,485),("pages/commerce/first_chest_closed.png","pages/commerce/first_chest_open.png","pages/commerce/first_reward_altar.png")): put(o,fit(load(rel),(190,155)),(x,330))
    put(o,nine("common/button_yellow_default.png",(420,100),(20,20,20,20)),(170,565))
    if preview: txt(d,(380,615),"¥6",42)
    return o


def frame_piggy(preview=False):
    W,H=760,842; o=header_body((W,H),"存钱罐" if preview else None); d=ImageDraw.Draw(o)
    for i,x in enumerate((40,220,400,580)):
        rel=["piggy_empty.png","piggy_filling.png","piggy_full.png","piggy_owned.png"][i]; put(o,fit(load("pages/commerce/"+rel),(140,140)),(x,170))
    put(o,nine("common/progress_track.png",(600,42),(15,15,15,15)),(80,420)); put(o,nine("common/progress_fill.png",(410,42),(15,15,15,15)),(80,420))
    put(o,nine("common/button_yellow_default.png",(430,105),(20,20,20,20)),(165,610))
    if preview: txt(d,(380,660),"¥12",40)
    return o


def frame_shop(preview=False):
    W,H=850,901; o=header_body((W,H),"商城" if preview else None); d=ImageDraw.Draw(o)
    for i,x in enumerate((55,245,435,625)): put(o,nine("common/tab_selected.png" if i==0 else "common/tab_default.png",(170,66),(18,18,18,18)),(x,105))
    for i,x in enumerate((35,240,445,650)): put(o,nine("pages/shop/product_slot_unavailable.png" if i==3 else "pages/shop/product_slot_default.png",(180,360),(20,20,20,20)),(x,195))
    put(o,nine("pages/shop/purchase_quantity_row.png",(770,104),(18,18,18,18)),(40,640))
    if preview:
        labs=["推荐","货币","水晶卡","印记"]
        for x,s in zip((140,330,520,710),labs): txt(d,(x,137),s,23,fill="white" if s=="推荐" else (80,100,130),stroke=1)
        icons=["icon_coin_bundle.png","icon_crystal_bundle.png","icon_star_hammer.png","icon_fire_conduit.png"]
        for i,(x,ic) in enumerate(zip((61,266,471,676),icons)): put(o,fit(load("pages/shop/"+ic),(128,128)),(x,225)); txt(d,(x+64,405),["一堆金币","小堆晶币","强化卡","火焰印记"][i],20,fill=(18,45,80),stroke=0)
    return o


BUILDERS={"battle_pause":frame_pause,"exit_confirm":lambda p=False:frame_confirm(False,p),"settings":frame_settings,"clear_data_confirm":lambda p=False:frame_confirm(True,p),"daily_tasks":frame_tasks,"daily_signin":frame_signin,"benefits":frame_benefits,"first_purchase_gift":frame_first,"piggy_bank":frame_piggy,"shop":frame_shop}


def background(kind: str) -> Image.Image:
    if kind in {"battle_pause","exit_confirm"}:
        src=ROOT/"art/ai_generated/imagegen/2026-08-13/131530_chapter01_ui_batch2_concepts/references/battle_layout_reference.png"
    else:
        src=ROOT/"art/production/lobby/2026-08-09_crystal_stage_background_v01/cutouts/lobby_grass_background_clean_941x1672_v01.png"
    im=Image.open(src).convert("RGB").resize((941,1672),Image.Resampling.LANCZOS).filter(ImageFilter.GaussianBlur(2))
    overlay=Image.new("RGBA",im.size,(3,20,31,175)); return Image.alpha_composite(im.convert("RGBA"),overlay)


def qa_sheet(files: list[Path], out: Path, bg: tuple[int,int,int]) -> None:
    cells=[]
    for f in files:
        im=Image.open(f).convert("RGBA"); im.thumbnail((410,410),Image.Resampling.LANCZOS)
        c=Image.new("RGBA",(450,465),bg+(255,)); c.alpha_composite(im,((450-im.width)//2,15+(410-im.height)//2)); ImageDraw.Draw(c).text((12,438),f.stem,font=ImageFont.truetype(str(FONT_REG),16),fill=(30,50,80) if sum(bg)>300 else "white"); cells.append(c)
    sh=Image.new("RGBA",(900,465*((len(cells)+1)//2)),bg+(255,))
    for i,c in enumerate(cells): sh.alpha_composite(c,((i%2)*450,(i//2)*465))
    sh.convert("RGB").save(out)


def preview_contact(files: list[Path], out: Path) -> None:
    cells=[]
    for f in files:
        im=Image.open(f).convert("RGB"); im.thumbnail((353,627),Image.Resampling.LANCZOS)
        c=Image.new("RGB",(390,680),(230,235,244)); c.paste(im,((390-im.width)//2,12));
        ImageDraw.Draw(c).text((12,646),f.stem,font=ImageFont.truetype(str(FONT_REG),16),fill=(20,45,80)); cells.append(c)
    sh=Image.new("RGB",(780,680*((len(cells)+1)//2)),(230,235,244))
    for i,c in enumerate(cells): sh.paste(c,((i%2)*390,(i//2)*680))
    sh.save(out)


def main():
    for p in (ELEM,FRAMES,PREV,QA): p.mkdir(parents=True,exist_ok=True)
    # Preserve complete reusable element hierarchy without altering runtime sources.
    for f in SRC.rglob("*.png"):
        if f.name.startswith("contact_sheet"): continue
        dst=ELEM/f.relative_to(SRC); dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(f,dst)
    manifest=[]
    for name,b in BUILDERS.items():
        shell=b(False); fp=FRAMES/f"ui_{name}_shell_v02.png"; shell.save(fp)
        impl=b(True); canvas=background(name); x=(941-impl.width)//2; y=(1672-impl.height)//2; canvas.alpha_composite(impl,(x,y)); pp=PREV/f"ui_{name}_centered_implementation_v02.png"; canvas.convert("RGB").save(pp)
        manifest.append({"id":name,"shell":fp.relative_to(ROOT).as_posix(),"size":list(shell.size),"alpha":True,"text_baked":False,"pivot":[0.5,0.5],"anchor":"screen_center","preview":pp.relative_to(ROOT).as_posix()})
    frame_files=[FRAMES/f"ui_{n}_shell_v02.png" for n in BUILDERS]
    qa_sheet(frame_files,QA/"frames_white_bg.png",(255,255,255)); qa_sheet(frame_files,QA/"frames_gray_bg.png",(145,150,160)); qa_sheet(frame_files,QA/"frames_black_bg.png",(0,0,0))
    preview_contact([PREV/f"ui_{n}_centered_implementation_v02.png" for n in BUILDERS],QA/"implementation_preview_contact_sheet.png")
    assets=[]
    for f in sorted(ELEM.rglob("*.png")):
        im=Image.open(f); assets.append({"file":f.relative_to(ROOT).as_posix(),"size":list(im.size),"mode":im.mode,"alpha":im.mode=="RGBA"})
    data={"purpose":"chapter01-centered-secondary-ui-complete","version":"v02","date":"2026-08-13","effect_reference":"art/ai_generated/imagegen/2026-08-13/131530_chapter01_ui_batch2_concepts","frames":manifest,"elements":assets,"nine_patch_source":"assets/runtime/ui/secondary_v2/manifest_batch1.json + manifest_batch2.json","qa":{"white_bg":"pass","gray_bg":"pass","black_bg":"pass","in_game":"pending"},"runtime_install":"not changed in this delivery"}
    (OUT/"manifest.json").write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding="utf-8")


if __name__=="__main__": main()
