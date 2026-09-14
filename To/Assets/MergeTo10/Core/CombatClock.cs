using System;
namespace MergeTo10.Core
{
    // Real monotonic attack time is independent of frame-driven simulation.
    public sealed class CombatClock
    {
        public double AttackTime {get;private set;}
        public double SimulationTime {get;private set;}
        double previous;bool initialized;
        public void Advance(double seconds,double frameDelta,bool paused,bool settlementFrozen)
        {
            if(double.IsNaN(seconds)||double.IsInfinity(seconds)||frameDelta<0||double.IsNaN(frameDelta)||double.IsInfinity(frameDelta))
                throw new ArgumentOutOfRangeException(nameof(seconds));
            if(!initialized){previous=seconds;initialized=true;return;}
            if(seconds<previous)throw new ArgumentException("Clock must be monotonic");
            double elapsed=seconds-previous;previous=seconds;
            if(paused)return;
            AttackTime+=elapsed;
            if(!settlementFrozen)SimulationTime+=frameDelta;
        }
        public void Reset(){AttackTime=0;SimulationTime=0;previous=0;initialized=false;}
    }
}

