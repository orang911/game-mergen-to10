using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;

namespace MergeTo10.Core
{
    public enum AttackElement { Poison, Ice, Lightning, Critical, Fire }

    // Immutable: do not retain a Cell that changes level/position in later chain steps.
    public sealed class MergeAttack
    {
        static readonly int[] AttackValues={2,4,6,10,14,18,25,32,40,50,60,70,80,90,100,110,120,130,140,150,165,180,195,210,225,240,255,270,285,300,320,340,360,380,400,420};
        public static int BaseAttack(int level)=>level>=1&&level<=36?AttackValues[level-1]:50;
        public readonly int SourceLevel,ResultLevel,AttackLevel,Tier,MergeCount,AttackCount,TargetCount,Step,Row;
        public readonly double Damage,TotalDamage,OriginX,OriginY;
        public readonly AttackElement Element;
        public readonly IReadOnlyDictionary<string,double> Effects;
        public readonly IReadOnlyList<MergeAttack> Contributions;
        public bool Automatic=>Step>0;
        public string ElementKey=>new[]{"poison","ice","lightning","critical","fire"}[(int)Element];

        public MergeAttack(int sourceLevel,int resultLevel,int count,double originX=0,double originY=0,int row=0,int step=0)
        {
            if(sourceLevel<1||sourceLevel>36||resultLevel<1||resultLevel>36)throw new ArgumentOutOfRangeException(nameof(sourceLevel));
            SourceLevel=sourceLevel;ResultLevel=resultLevel;AttackLevel=resultLevel;
            Element=(AttackElement)((sourceLevel-1)%5);Tier=(sourceLevel-1)/5+1;
            MergeCount=Math.Max(1,count);AttackCount=MergeCount;TargetCount=1;
            OriginX=originX;OriginY=originY;Row=row;Step=step;
            double power=AttackValues[resultLevel-1],t=Tier-1;
            TotalDamage=power*Math.Max(1,MergeCount-1);Damage=TotalDamage/MergeCount;
            var effects=new Dictionary<string,double>{{"element",(int)Element},{"tier",Tier}};
            switch(Element)
            {
                case AttackElement.Poison:
                    effects["dps_ratio"]=.30+.05*t;effects["duration"]=3+.3*t;break;
                case AttackElement.Ice:
                    effects["slow_percent"]=.60;effects["duration"]=2;
                    TargetCount=Math.Max(1,MergeCount-1);AttackCount=TargetCount;
                    Damage=power;TotalDamage=Damage*TargetCount;break;
                case AttackElement.Lightning:
                    AttackCount=1;Damage=power*(1+Math.Max(0,MergeCount-2)*.20);TotalDamage=Damage;
                    effects["chain_count"]=1+Math.Floor(t/2)+Math.Max(0,MergeCount-2);
                    effects["chain_damage_ratio"]=Math.Min(.90,.50+.05*t+Math.Max(0,MergeCount-2)*.05);break;
                case AttackElement.Critical:
                    effects["crit_chance"]=Math.Min(1,.25+.05*t);effects["crit_multiplier"]=2;
                    effects["annihilation_chance"]=Math.Min(.30,.05+.02*t);break;
                case AttackElement.Fire:
                    effects["duration"]=2+.2*t;effects["splash_radius"]=70+8*t;
                    effects["splash_damage_ratio"]=.30+.04*t;break;
            }
            Effects=new ReadOnlyDictionary<string,double>(effects);
            Contributions=Array.AsReadOnly(Array.Empty<MergeAttack>());
        }

        internal MergeAttack(IReadOnlyList<MergeAttack> parts)
        {
            var first=parts[0];
            SourceLevel=first.SourceLevel;AttackLevel=first.ResultLevel;Element=first.Element;
            OriginX=first.OriginX;OriginY=first.OriginY;Row=first.Row;Step=first.Step;
            MergeCount=2;AttackCount=1;TargetCount=1;ResultLevel=first.ResultLevel;Tier=first.Tier;
            var effects=first.Effects.ToDictionary(p=>p.Key,p=>p.Value);
            foreach(var part in parts)
            {
                ResultLevel=Math.Max(ResultLevel,part.ResultLevel);TotalDamage+=part.TotalDamage;
                Damage+=Element==AttackElement.Ice?part.Damage:part.TotalDamage;
                TargetCount=Math.Max(TargetCount,part.TargetCount);Tier=Math.Max(Tier,part.Tier);
                foreach(var p in part.Effects)effects[p.Key]=Math.Max(effects.TryGetValue(p.Key,out double value)?value:0,p.Value);
            }
            Effects=new ReadOnlyDictionary<string,double>(effects);
            Contributions=Array.AsReadOnly(parts.ToArray());
        }

        // Critical remains per raw shot; annihilation is a separate hit-stage roll.
        public double ResolvePrimaryDamage(Func<double> criticalRoll)
        {
            if(Element!=AttackElement.Critical)return TotalDamage;
            if(Contributions.Count>0)return Contributions.Sum(p=>p.ResolvePrimaryDamage(criticalRoll));
            double result=0;
            for(int i=0;i<Math.Max(1,AttackCount);i++)result+=Damage*(criticalRoll()<Effects["crit_chance"]?Effects["crit_multiplier"]:1);
            return result;
        }
        public double IceDamageForTarget(int index)
        {
            if(index<0||index>=TargetCount)return 0;
            return Contributions.Count==0?Damage:Contributions.Where(p=>index<p.TargetCount).Sum(p=>p.Damage);
        }
    }

    public sealed class MergeAttackBatch
    {
        static readonly AttackElement[] Order={AttackElement.Fire,AttackElement.Lightning,AttackElement.Critical,AttackElement.Ice,AttackElement.Poison};
        public readonly IReadOnlyList<MergeAttack> RawEvents,Events;
        public readonly int ComboLevel;
        public readonly double ComboMultiplier;
        public readonly string ComboKey;
        public MergeAttackBatch(IEnumerable<MergeAttack> contributions)
        {
            var raw=contributions.ToArray();
            if(raw.Any(p=>p==null||p.Contributions.Count!=0))throw new ArgumentException("Raw contributions required");
            RawEvents=Array.AsReadOnly(raw);
            Events=Array.AsReadOnly(Order.Select(e=>raw.Where(p=>p.Element==e).ToArray()).Where(p=>p.Length>0).Select(p=>new MergeAttack(p)).ToArray());
            int unique=Events.Count;ComboLevel=unique<3?0:Math.Min(3,unique-2);
            ComboMultiplier=unique<3?1:unique==3?1.15:unique==4?1.30:1.50;
            ComboKey=string.Join("+",Events.Select(e=>e.ElementKey).OrderBy(k=>k,StringComparer.Ordinal));
        }
    }
}
