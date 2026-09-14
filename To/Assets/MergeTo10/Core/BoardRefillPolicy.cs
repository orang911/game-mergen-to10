using System;
using System.Collections.Generic;
namespace MergeTo10.Core
{
    // Direct port of the frozen Godot BoardRefillPolicy; double precision is intentional.
    public static class BoardRefillPolicy
    {
        static int Clamp(int n,int lo,int hi)=>Math.Max(lo,Math.Min(hi,n));
        static double Clamp(double n,double lo,double hi)=>Math.Max(lo,Math.Min(hi,n));
        public static double[] BaseWeights(int historicalHighest)
        {
            int highest=Clamp(historicalHighest,1,36);
            if(highest<5) return new[]{0.33,0.34,0.33};
            var result=new double[highest];
            double[] window={0.32,0.28,0.22,0.13,0.05};
            for(int i=0;i<5;i++) result[Math.Max(1,highest-4)+i-1]=window[i];
            return result;
        }
        public struct Analysis { public double[] Weights,Scores; }
        public static Analysis Analyze(int highest,int[] values,int grid,int cell)
        {
            highest=Clamp(highest,1,36);
            var baseline=BaseWeights(highest);
            var scores=new double[baseline.Length];
            if(highest<5) return new Analysis{Weights=baseline,Scores=scores};
            var before=Quality(values,grid);
            var raw=new double[baseline.Length];
            for(int i=0;i<baseline.Length;i++)
            {
                if(baseline[i]<=0){scores[i]=-1000;continue;}
                int level=i+1;var board=(int[])values.Clone();board[cell]=level;
                var after=Quality(board,grid);
                int size=Component(board,grid,cell).Count;double score=0;
                if(size==2)score+=3;
                else if(size>=4)score-=2+(size-4)*0.5;
                int reduction=before.Isolated-after.Isolated;
                if(reduction>0)score+=reduction*1.5;
                score+=after.Groups-before.Groups;
                if(size==2 && level>=Math.Max(2,highest-2))score+=1;
                int fragments=after.Fragments-before.Fragments;
                if(fragments>0)score-=fragments*2;
                else if(fragments<0)score+=-fragments*0.5;
                int count=0;foreach(int n in board)if(n==level)count++;
                double ratio=(double)count/Math.Max(1,after.Occupied);
                if(ratio>0.32)score-=1.5*Clamp((ratio-0.32)/0.20,0,1);
                if(after.Empty==0)score+=after.Groups>0?5:-5;
                scores[i]=score;raw[i]=baseline[i]*Math.Exp(Clamp(score/2,-6,6));
            }
            return new Analysis{Weights=Normalize(raw,baseline,highest-1),Scores=scores};
        }
        public static int Sample(int highest,int[] values,int grid,int cell,double roll)
        {
            var weights=Analyze(highest,values,grid,cell).Weights;double cursor=0;
            // <=, including zero-mass boundary behavior, deliberately matches Godot.
            for(int i=0;i<weights.Length;i++){cursor+=weights[i];if(roll<=cursor)return i+1;}
            return Math.Max(1,weights.Length);
        }
        static double[] Normalize(double[] raw,double[] fallback,int special)
        {
            var result=new double[raw.Length];var active=new List<int>();
            for(int i=0;i<raw.Length;i++)if(fallback[i]>0)active.Add(i);
            double remaining=1;
            while(active.Count>0)
            {
                double total=0;foreach(int i in active)total+=Math.Max(0,raw[i]);
                if(total<=0)foreach(int i in active){raw[i]=fallback[i];total+=fallback[i];}
                int clampIndex=-1;double clampValue=0;
                foreach(int i in active)
                {
                    double p=remaining*raw[i]/total,max=i==special?0.05:0.55;
                    if(p<0.03){clampIndex=i;clampValue=0.03;break;}
                    if(p>max){clampIndex=i;clampValue=max;break;}
                }
                if(clampIndex<0){foreach(int i in active)result[i]=remaining*raw[i]/total;break;}
                result[clampIndex]=clampValue;remaining-=clampValue;active.Remove(clampIndex);
            }
            return result;
        }
        struct BoardQuality { public int Occupied,Empty,Isolated,Groups,Fragments; }
        static BoardQuality Quality(int[] board,int grid)
        {
            var q=new BoardQuality();var visited=new HashSet<int>();
            for(int i=0;i<board.Length;i++)
            {
                if(board[i]<=0)continue;q.Occupied++;
                bool same=false;foreach(int n in Neighbors(i,grid,board.Length))if(board[n]==board[i])same=true;
                if(!same)q.Isolated++;
                if(visited.Contains(i))continue;
                var component=Component(board,grid,i);
                foreach(int n in component)visited.Add(n);
                q.Fragments++;if(component.Count>=2)q.Groups++;
            }
            q.Empty=board.Length-q.Occupied;return q;
        }
        static List<int> Component(int[] board,int grid,int start)
        {
            var output=new List<int>();if(start<0||start>=board.Length||board[start]<=0)return output;
            var pending=new Stack<int>();var visited=new HashSet<int>{start};pending.Push(start);
            while(pending.Count>0)
            {
                int cell=pending.Pop();output.Add(cell);
                foreach(int n in Neighbors(cell,grid,board.Length))
                    if(board[n]==board[start]&&visited.Add(n))pending.Push(n);
            }
            return output;
        }
        public static IEnumerable<int> Neighbors(int cell,int grid,int count)
        {
            int x=cell%grid,y=cell/grid;
            foreach(int n in new[]{cell-grid,cell+grid,cell-1,cell+1})
                if(n>=0&&n<count&&Math.Abs(n%grid-x)+Math.Abs(n/grid-y)==1)yield return n;
        }
    }
}
