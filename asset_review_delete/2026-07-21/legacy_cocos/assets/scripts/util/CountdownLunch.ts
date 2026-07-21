

/**
 * 异步处理方法
 */
export default class CountdownLunch<T> {

    count: number = 0;

    useData: T = null;

    callFunc: Function = null;

    constructor(callFunc: Function, count: number, useData?: T) {
        this.count = count;
        this.callFunc = callFunc;
        this.useData = useData;
    }

    countdown() {
        this.count--;
        if (this.count == 0) {
            this.callFunc(this.useData);
        }
    }
}
