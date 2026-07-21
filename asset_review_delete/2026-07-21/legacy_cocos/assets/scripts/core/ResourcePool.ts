

export default class ResourcePool {

    public static get instance() {
        if (!this._instance) {

        }
        return this._instance;
    }
    private static _instance: ResourcePool = null;

    private cacheMap: { [key: string]: any[] } = {};


    public get<T extends Recycle>(type: Function | string): T {
        let key;

        if (typeof type === 'function') {
            //key = (<Function>type).name;
            key = (<any>type).name;
        } else {
            key = <string>type;
        }

        let cacheArr = this.cacheMap[key];

        if (!cacheArr || cacheArr.length == 0)
            return null;

        let cache = cacheArr.shift();
        return cache;
    }

    put(cache: Recycle, maxNum: number) {

        let key = cache.getKey();

        let cacheArr = this.cacheMap[key];
        if (!cacheArr) {
            this.cacheMap[key] = new Array();
            cacheArr = this.cacheMap[key];
        }

        if (cacheArr.length < maxNum) {
            cache.sleep();
            cacheArr.push(cache);
        } else {
            if (cache instanceof cc.Component) {
                cache.node.destroy();
            } else if (cache instanceof cc.Object) {
                cache.destroy();
            }
        }
    }

    public remove(type: Function | string) {
        let key;

        if (typeof type === 'function') {
            //key = (<Function>type).name;
            key = (<any>type).name;
        } else {
            key = <string>type;
        }

        if (this.cacheMap[key]) {
            let len: number = this.cacheMap[key].length;

            for (let i = 0; i < len; i++) {
                let obj: any = this.cacheMap[key][i];

                if (obj instanceof cc.Component) {
                    (<cc.Component>obj).node.destroy();
                } else if (obj instanceof cc.Object) {
                    (<cc.Object>obj).destroy();
                } else {
                }
            }
        }

        this.cacheMap[key] = null;

    }
}

interface Recycle {
    getKey();
    awake();
    sleep();
    destorySelf();
}