

const { ccclass, property } = cc._decorator;

@ccclass
export class LongNumberUtils extends cc.Component {

    private static _instance: LongNumberUtils;
    public static get instance(): LongNumberUtils {
        return LongNumberUtils._instance;
    }

    @property(cc.JsonAsset)
    jsonAsset: cc.JsonAsset = null;

    private currencyConfigDatas: { id: number, unit: string }[] = null;

    onLoad() {
        LongNumberUtils._instance = this;
        this.currencyConfigDatas = this.jsonAsset.json;
    }

    /**
     * 将数字转化为K,M,G,B,T计数
     */
    addCompanyByString(numStr: string) {
        let self = this;
        function wait() {
            if (this.currencyConfigDatas != null) {
                console.log(this.currencyConfigDatas);
                self.addCompanyByString(numStr);
                self.unschedule(wait);
            }
        }
        if (this.currencyConfigDatas == null) {
            this.schedule(wait, 0.02);
            return;
        }
        if (numStr.length <= 3) {
            return numStr;
        }
        let count = Math.floor(numStr.length / 3);
        let id = count;
        if (id >= this.currencyConfigDatas.length) {
            return 999 + this.currencyConfigDatas[this.currencyConfigDatas.length - 1].unit;
        }
        let end = numStr.length % 3;
        let float = "";
        let company = "";
        if (end == 0) {
            id -= 1;
            end = 3;
            if (id <= 0) {
                return numStr;
            }
        }
        let sNum = numStr.slice(end, end + 1)
        if (sNum == "0") {
            float = numStr.slice(0, end);
        } else {
            float = numStr.slice(0, end) + "." + sNum;
        }
        company = this.currencyConfigDatas[id - 1].unit;

        return float + company;
    }

    /**
     * 
     * 增加千位分隔符
     */
    addStringDelimiter(str: string) {
        return str.replace(/(\d)(?=(?:\d{3})+$)/g, '$1,');
    }

    /**
     * 将字符串转化为指定位数的整数数组,字符串不够长则在头部用0补足
     */
    getNumArrFromString(numStr: string, length: number) {
        let strArr: string[] = numStr.split("");
        let numArr: number[] = [];
        strArr.reverse();
        for (let i = 0; i < length; i++) {
            let num = i < strArr.length ? parseInt(strArr[i]) : 0;
            numArr[i] = num;
        }
        return numArr.reverse();
    }

    /**
     * 用字符串存储的s数值加法;
     * @param 参数为代正表整数的字符串
     */
    add(numStr1: string, numStr2: string) {
        //判断能否使用数字直接运算
        /*   if (numStr1.length < 16 && numStr2.length < 16) {
              //在整数精度范围内
              let num1: number = parseInt(numStr1);
              let num2: number = parseInt(numStr2);
              let returnNum = num1 + num2;
              return returnNum.toString();
          }
   */
        let length = numStr1.length > numStr2.length ? numStr1.length : numStr2.length;

        //将字符串转化为整数数组
        let numArr1: number[] = this.getNumArrFromString(numStr1, length);
        let numArr2: number[] = this.getNumArrFromString(numStr2, length);

        numArr1.reverse();
        numArr2.reverse();

        let numArr: number[] = [];
        for (let i = 0; i < length; i++) {
            let baseNum = numArr[i] ? numArr[i] : 0;
            let addNum1 = numArr1[i];
            let addNum2 = numArr2[i];
            let temp = baseNum + addNum1 + addNum2;
            numArr[i] = temp % 10;
            numArr[i + 1] = Math.floor(temp / 10);
        }

        if (numArr[numArr.length - 1] == 0) {//去除一位先导0
            numArr.pop();
        }

        numArr.reverse();
        let returnStr = "";
        numArr.forEach(num => {
            returnStr += num
        });

        //console.log(numStr1 + " + " + numStr2 + " = " + returnStr, this.addStringDelimiter(returnStr));
        return returnStr;
    }

    /**
    * 用字符串存储的数字减法,numStr1的数值需要大于等于numStr2的数值
    * @param 参数为代表正整数的字符串;
    */
    sub(numStr1: string, numStr2: string) {
        //判断能否使用数字直接运算
        /*    if (numStr1.length < 16 && numStr2.length < 16) {
               //在整数精度范围内
               let num1: number = parseInt(numStr1);
               let num2: number = parseInt(numStr2);
               let returnNum = num1 - num2;
               return returnNum.toString();
           } */

        if (numStr1 == numStr2) {
            return "0";
        }

        let length = numStr1.length > numStr2.length ? numStr1.length : numStr2.length;

        //将字符串转化为整数数组
        let numArr1: number[] = this.getNumArrFromString(numStr1, length);
        let numArr2: number[] = this.getNumArrFromString(numStr2, length);

        numArr1.reverse();
        numArr2.reverse();


        let numArr: number[] = this.numArrSub(numArr1, numArr2, length);

        numArr.reverse();
        let returnStr = "";
        numArr.forEach(num => {
            returnStr += num
        });

        //console.log(numStr1 + " - " + numStr2 + " = " + returnStr, this.addStringDelimiter(returnStr));
        return returnStr;
    }

    /**
     * 除法也用，提出来公用
     * @param 参数为倒序存放的数值数组
     * @param length 为数组的长度
     * @returns 返回为倒叙的差值数组，已去先导0
     */
    private numArrSub(numArr1: number[], numArr2: number[], length: number) {
        let numArr: number[] = [];
        for (let i = 0; i < length; i++) {
            let subNum1 = numArr1[i];
            let subNum2 = numArr2[i];
            let temp = subNum1 - subNum2;
            if (temp >= 0) {
                numArr[i] = temp;
            } else {
                numArr[i] = temp + 10;
                numArr1[i + 1] -= 1;
            }
        }
        while (numArr[numArr.length - 1] == 0) {//去除所有先导0，直到最后一位
            numArr.pop();
            if (numArr.length == 1) {
                break;
            }
        }
        //console.log("numArrSub", numArr1, numArr2, numArr);
        return numArr;
    }

    /**
    * 用字符串存储的数字乘法,返回值默认为整数
    * @param 参数为代表正整数或者正小数的字符串;
    */
    mul(numStr1: string, numStr2: string, returnFloat: boolean = false) {
        let start = new Date().getTime();
        //计算小数点位置
        let dot1 = numStr1.indexOf(".") == -1 ? 0 : numStr1.length - 1 - numStr1.indexOf(".");
        let dot2 = numStr2.indexOf(".") == -1 ? 0 : numStr2.length - 1 - numStr2.indexOf(".");
        let dot = dot1 + dot2;

        let temp1 = numStr1.split(".");
        let temp2 = numStr2.split(".");
        let strOffDot1 = temp1.length > 1 ? temp1[0] + temp1[1] : temp1[0];
        let strOffDot2 = temp2.length > 1 ? temp2[0] + temp2[1] : temp2[0];

        let returnStr = this.karatsuba(strOffDot1, strOffDot2);


        while (returnStr[0] == "0") {//去除所有先导0，直到小数点前最后一位
            returnStr = returnStr.slice(1);
            if (returnStr.length - dot == 1) {
                break;
            }
        }

        if (dot == 0) {
            return returnStr;
        }

        if (returnFloat) {
            //保留小数点
            if (dot >= returnStr.length) {
                let zoreTimes = dot - returnStr.length;
                let str = "0.";
                for (let i = 0; i < zoreTimes; i++) {
                    str += "0";
                }
                returnStr = str + returnStr;
            } else {
                returnStr = returnStr.substr(0, returnStr.length - dot) + "." + returnStr.substr(returnStr.length - dot, returnStr.length);
            }
        } else {
            //舍弃小数点后数字
            let count = returnStr.length - dot;
            returnStr = returnStr.substring(0, count)// + "." + returnStr.substring(count, returnStr.length);
        }
        //console.log("乘法耗时", new Date().getTime() - start, numStr1 + "*" + numStr2 + "=" + returnStr);
        //console.log(numStr1 + " * " + numStr2 + " = " + returnStr, numStr1.length, numStr2.length, returnStr.length);
        return returnStr;
    }

    /**
     * 累加乘法，参数都是正整数
     */
    commonMul(numStr1: string, numStr2: string, clearZero: boolean = false) {

        //判断能否使用数字直接运算
        /*  if (numStr1.length + numStr2.length < 16) {
             //在整数精度范围内
             let num1: number = parseInt(numStr1);
             let num2: number = parseInt(numStr2);
             let returnNum = num1 * num2;
             return returnNum.toString();
         }
  */
        //将字符串转化为整数数组
        let numArr1: number[] = this.getNumArrFromString(numStr1, numStr1.length);
        let numArr2: number[] = this.getNumArrFromString(numStr2, numStr2.length);

        numArr1.reverse();
        numArr2.reverse();


        let numArr: number[] = [];
        for (let i = 0; i < numArr1.length; i++) {
            for (let j = 0; j < numArr2.length; j++) {
                if (!numArr[i + j]) {
                    numArr[i + j] = 0;
                }
                numArr[i + j] += numArr1[i] * numArr2[j];
            }
        }
        let length1 = numArr.length;
        for (let k = 0; k < length1; k++) {
            let remainder = numArr[k] % 10;
            let quotient = Math.floor(numArr[k] / 10);
            numArr[k] = remainder;
            if (!numArr[k + 1]) {
                numArr[k + 1] = 0;
            }
            numArr[k + 1] += quotient;
        }

        if (clearZero) {
            while (numArr[numArr.length - 1] == 0) {
                numArr.pop();
                if (numArr.length - 1 == 0) {
                    break;
                }
            }
        }

        numArr.reverse();
        let returnStr = "";
        numArr.forEach(num => {
            returnStr += num
        });
        return returnStr;
    }

    /**
     * 因为要用到自己写的加减法法，因此性能一般，暂时不用
     * 分治 - Karatsuba算法
     */
    private karatsuba(numStr1: string, numStr2: string) {
        //递归结束判断
        if (numStr1.length <= 1 || numStr2.length <= 1) {
            let returnStr = this.commonMul(numStr1, numStr2, true);
            return returnStr;
        }

        let length1 = numStr1.length;
        let length2 = numStr2.length;
        let max = Math.max(length1, length2);
        let min = Math.min(length1, length2);
        let half = Math.floor((max + 1) / 2);
        if (half >= min) half = min - 1;

        let a = this.clearZore(numStr1.slice(0, length1 - half));
        let b = this.clearZore(numStr1.slice(length1 - half));
        let c = this.clearZore(numStr2.slice(0, length2 - half));
        let d = this.clearZore(numStr2.slice(length2 - half));

        //console.log(a, b, c, d);
        let p1 = this.karatsuba(a, c);//a*c
        let p2 = this.karatsuba(b, d);//b*d
        let aADDb = this.add(a, b);
        let cADDd = this.add(c, d);
        let temp = this.karatsuba(aADDb, cADDd);
        let temp1 = this.add(p1, p2);
        let p3 = this.sub(temp, temp1);//(a+c) * (b+d) - a*c - b*d = b*c + a*d

        //p1乘以10的2*half次方,p3乘以10的half次方
        for (let i = 0; i < half; i++) {
            p1 += "00";
            p3 += "0";
        }
        let temp2 = this.add(p1, p2);
        let returnNum = this.add(p3, temp2);
        //console.log(returnNum, p1, p2, p3, temp, temp1, temp2, a, b, c, d, numStr1, numStr2);
        return returnNum
    }

    /**
     * 去除所有先导零
     */
    private clearZore(numStr: string) {
        let length = numStr.length;
        if (length == 1 || numStr[0] != "0") {
            return numStr;
        }
        for (let index = 0; index < length; index++) {
            if (numStr.length == 1) {
                return numStr;
            }
            if (numStr[index] == "0") {
                numStr = numStr.slice(1);
            } else {
                return numStr;
            }
        }
    }

    /**
    * 用字符串存储的数字除法，整除,向下舍入
    * @param 参数为代表正整数的字符串;
    * @returns 返回值为商和余数
    */
    div(numStr1: string, numStr2: string) {
        //判断能否使用数字直接运算
        /* if (numStr1.length < 16 && numStr2.length < 16) {
            //在整数精度范围内
            let num1: number = parseInt(numStr1);
            let num2: number = parseInt(numStr2);
            let quotient = Math.floor(num1 / num2);
            let remainder = num1 % num2;
            return { quotient: quotient.toString(), remainder: remainder.toString() };
        }
 */
        let quotient: string = "0";//商
        let remainder: string = "0";//余数

        if (numStr1 == numStr2) {
            quotient = "1";
            remainder = "0";
        }

        let bool = this.judgeInt(numStr1, numStr2);
        if (!bool) {
            quotient = "0";
            remainder = numStr1;
        } else {
            //已知numstr1 > numstr2
            //将字符串转化为整数数组
            let numArr1: number[] = this.getNumArrFromString(numStr1, numStr1.length);
            let numArr2: number[] = this.getNumArrFromString(numStr2, numStr2.length);
            numArr1.reverse();
            numArr2.reverse();

            remainder = numStr1;
            while (true) {
                let bool = this.judgeInt(remainder, numStr2);
                if (!bool) {
                    break;
                }
                let times = numArr1.length - numArr2.length;
                let tempQuotient = 1;
                let tempeStr = numStr2;

                let tempQuotientStr = "";
                let tempArr: number[] = [];
                tempArr.push(...numArr2);
                for (let i = 0; i < times; i++) {
                    //在颠倒数组头部部补零，相当于数值乘以10的times次方
                    tempArr.unshift(0);
                    tempQuotientStr += "0";
                    tempeStr += "0";
                }
                if (!this.judgeInt(remainder, tempeStr)) {
                    //被减术小于减数，减数去掉一个零
                    tempArr.shift();
                    tempQuotientStr = tempQuotientStr.slice(0, tempQuotientStr.length - 1);
                }
                if (tempArr.length < numArr1.length) {
                    //在颠倒数组尾部补零，不影响数值大小,便于减法法运算
                    tempArr.push(0);
                }

                quotient = this.add(quotient, tempQuotient + tempQuotientStr);
                numArr1 = this.numArrSub(numArr1, tempArr, numArr1.length);

                remainder = numArr1.reverse().toString().replace(/,/g, "");
                numArr1.reverse();
                //console.log(quotient, remainder, times);
            }

        }

        //console.log(numStr1 + " / " + numStr2 + " = " + quotient + ",余数 = " + remainder);
        return { quotient: quotient, remainder: remainder };
    }

    /**
     * 获得numstr1相对于numstr2的百分比值,保留小数到指定位数
     */
    percentage(numStr1: string, numStr2: string, floatNum: number = 0) {
        let divNum = numStr1;

        //至少能显示出整数百分比
        floatNum += 2;
        for (let i = 0; i < floatNum; i++) {
            divNum += "0";
        }
        let percentage = this.div(divNum, numStr2).quotient;
        //console.log("商=", percentage)
        if (floatNum >= percentage.length) {
            let times = floatNum - percentage.length;
            let str = "0.";
            for (let i = 0; i < times; i++) {
                str += "0";
            }
            percentage = str + percentage;
        } else {
            percentage = percentage.substr(0, percentage.length - floatNum) + "." + percentage.substr(percentage.length - floatNum, percentage.length);
        }

        return percentage;
    }

    /**
     * 乘方运算，参数都为number类型
     * @param num 乘方底数
     * @param times 乘方次数
     */
    pow(num: number, times: number) {

        let numStr = num.toString();
        //计算小数点位置
        let dot = numStr.indexOf(".") == -1 ? 0 : numStr.length - 1 - numStr.indexOf(".");

        let temp = numStr.split(".");
        let strOffDot = temp.length > 1 ? temp[0] + temp[1] : temp[0];

        let useNum = parseInt(strOffDot);
        let a = [1];
        for (let i = 0; i < times; i++) {
            let length = a.length;
            for (let j = 0; j < length; j++) {
                a[j] *= useNum;
            }
            let k = 0;
            while (k < a.length) {
                if (a[k] >= 10) {
                    let mult = a[k];
                    a[k] = mult % 10;
                    if (!a[k + 1]) {
                        a[k + 1] = 0;
                    }
                    a[k + 1] += Math.floor(mult / 10);
                }
                k++;
            }
        }
        a.reverse();
        let returnStr = "";
        a.forEach(num => {
            returnStr += num
        });


        dot *= times;
        while (returnStr[0] == "0") {//去除所有先导0，直到小数点前最后一位
            returnStr = returnStr.slice(1);
            if (returnStr.length - dot == 1) {
                break;
            }
        }

        if (dot == 0) {
            return returnStr;
        }

        if (dot >= returnStr.length) {
            let zoreTimes = dot - returnStr.length;
            let str = "0.";
            for (let i = 0; i < zoreTimes; i++) {
                str += "0";
            }
            returnStr = str + returnStr;
        } else {
            returnStr = returnStr.substr(0, returnStr.length - dot) + "." + returnStr.substr(returnStr.length - dot, returnStr.length);
        }

        return returnStr;
    }

    /**
     * 判断整数字符串数值大小,a >= b则true,否则为false
     * @param a 
     * @param b 
     */
    judgeInt(a: string, b: string): boolean {
        if (a.length < 15 && b.length < 15) {
            return parseInt(a) >= parseInt(b);
        }

        if (a.length > b.length) {
            return true
        }
        if (a.length < b.length) {
            return false;
        }
        for (let i = 0; i < a.length; i++) {
            if (parseInt(a[i]) > parseInt(b[i])) {
                return true;
            } else if (parseInt(a[i]) < parseInt(b[i])) {
                return false;
            }
        }
        return true;
    }

    /**
     * 判断浮点数字符串数值大小,a >= b则true，否则false
     * @param a
     * @param b
     */
    judgeFloat(a: string, b: string) {
        /* if (a.length < 15 && b.length < 15) {
            return parseFloat(a) >= parseFloat(b);
        } */
        let temp1 = a.split(".");
        let temp2 = b.split(".");

        let int1 = temp1[0];
        let float1 = temp1.length > 1 ? temp1[1] : "0";

        let int2 = temp2[0];
        let float2 = temp2.length > 1 ? temp2[1] : "0";
        if (int1 == int2) {

            let length = Math.max(float1.length, float2.length);
            for (let i = 0; i < length; i++) {
                let num1 = float1[i] ? parseInt(float1[i]) : 0;
                let num2 = float2[i] ? parseInt(float2[i]) : 0;
                if (num1 > num2) {
                    return true;
                } else if (num1 < num2) {
                    return false;
                }
            }
            return true;
        }

        let bool = this.judgeInt(int1, int2);
        return bool;


    }

}