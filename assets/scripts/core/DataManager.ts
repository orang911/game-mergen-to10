import PlayerData from "../data/PlayerData";
import ResourcesManager from "./ResourcesManager";
import CountdownLunch from "../util/CountdownLunch";
import DataStorage from "./DataStorage";
import CustomEventType from "../event/CustomEventType";

const { ccclass, property } = cc._decorator;

@ccclass
export class DataManager extends cc.Component {
    public static get instance() {
        if (this._instance == null) {
            this._instance = new DataManager();
            this._instance.init();
        }
        return DataManager._instance;
    }
    private static _instance: DataManager = null;

    private _playerData: PlayerData = null;

    private _isJosnLoaded = false;

    init() {

    }

    //加载配置数据
    public loadComfigDatas(callback: Function) {
        if (this._isJosnLoaded) {
            callback();
            return;
        }

        var nameTable: string = "WXNameTable";

        /* if (GamePlatform.type == GamePlatformType.tt) {
            nameTable = "TTNameTable";
        } */

        var jsonArr = [/* "ItemConfigTable", "CustomsPassConfigTable", nameTable, "WorldConfig", "BirthPlaceConfig",
            "PopLevelConfig", "SkillLevelConfig", "SkillMotionConfig", "TrialConfig", "DailyTaskConfig" */];

        var resMgr = ResourcesManager.instance;

        let countdownLaunch = new CountdownLunch<any>(() => {
            this.onConfigDataLoadComp();
            callback();
            this._isJosnLoaded = true;
        }, jsonArr.length + 1)
        countdownLaunch.countdown();
    }

    /**
     * 将json文件以指定属性为键值进行存储
     * @param jsonData 读取到的Json文件
     * @param keyName 指定为键值的属性名
     * @param callFunc 加载回调
     */
    private getMapFromJson<T>(jsonData: any, keyName: string, callFunc: Function) {
        let map: { [key: number]: T } = {};
        for (const index in jsonData) {
            if (jsonData.hasOwnProperty(index)) {
                let item = jsonData[index];
                let key = item[keyName];
                map[key] = item;
            }
        }
        callFunc(map);
    }

    private onConfigDataLoadComp() {

        //TODO:加载道具表

        this.updateDataEveryDay();
    }


    private updateDataEveryDay() {
        //DataStorage.setItem("day","2018/11/22");

        var yesterday: Date = new Date();
        yesterday.setDate(yesterday.getDate() - 1);

        var lastDay: string = DataStorage.getItem("day", this.getLocaleDateString(yesterday));

        //cc.log("上次登录时间",lastDay,DataStorage.getItem("day","没存储"));
        var lastDate: Date = new Date(lastDay); //上一次的日期

        var nowDate: Date = new Date(this.getLocaleDateString(new Date())); //现在的日期

        var dateDifc = (nowDate.getTime() - lastDate.getTime()) / 86400000;

        //cc.log("dateDifc",dateDifc,this.getLocaleDateString(nowDate),this.getLocaleDateString(new Date()),this.getSignInData().lastLoginDay);

        var checkTimer = (dt) => {
            nowDate = new Date();

            if (nowDate.getHours() >= 0)//每天凌晨0点钟刷新数据
            {
                console.log("新的一天到了");

                this.getPlayerData().logindays++;

                this.savePlayerData();

                this.unschedule(checkTimer);

                DataStorage.setItem("day", this.getLocaleDateString(nowDate));

                cc.systemEvent.emit(CustomEventType.NewDay);

            }

        };

        //this.scheduleOnce(checkTimer,1.25);//首次快速更新一下

        if (dateDifc >= 1)//如果是新的一天
        {
            this.schedule(checkTimer, 5);
            checkTimer(0);

        } else if (dateDifc < 0) {
            DataStorage.setItem("day", this.getLocaleDateString(nowDate));//重新存储当前时间
        }
    }

    public getLocaleDateString(date: Date): string {

        var year: string = date.getFullYear().toString();
        var mon: number = date.getMonth() + 1;
        var month: string = mon < 10 ? "0" + mon : mon.toString();
        var day: string = date.getDate() < 10 ? "0" + date.getDate() : date.getDate().toString();

        return year + "/" + month + "/" + day;

    }

    public getPlayerData(): PlayerData {
        if (this._playerData == null) {
            this._playerData = new PlayerData();
            this._playerData.init();
            var localData: PlayerData = JSON.parse(DataStorage.getItem("playerData"));

            if (localData) {
                for (var key in localData) {
                    if (typeof this._playerData[key] != "undefined") {
                        this._playerData[key] = localData[key];
                    }
                }
            }

        }

        return this._playerData;
    }

    public savePlayerData(): void {

        DataStorage.setItem("playerData", JSON.stringify(this._playerData));
        // SystemManager.instance.synchronousDataToServer();
    }
}