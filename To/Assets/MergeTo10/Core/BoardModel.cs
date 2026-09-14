using System;
using System.Collections.Generic;
using System.Linq;
namespace MergeTo10.Core
{
    [Serializable] public sealed class BoardSnapshot {public int[] Values;public int Highest,Score;}
    public sealed class Cell
    {
        public readonly int Id;public int Level,X,Y;
        public Cell(int id,int level,int x,int y){Id=id;Level=level;X=x;Y=y;}
    }
    public sealed class MergeStep
    {
        public Cell Target;public List<Cell> Group;public int SourceLevel,StepIndex;
        public double ActionTime,Duration;public bool Automatic;
    }
    public struct CellMove {public Cell Cell;public int FromX,FromY;}
    public sealed class BoardModel
    {
        public const int Size=5,MaxLevel=36,ChainLimit=5;
        readonly Cell[] cells=new Cell[25];int nextId=1;
        public int Highest{get;private set;}=1;
        public int Score{get;private set;}
        public BoardSnapshot Capture()=>new BoardSnapshot{Values=Values(),Highest=Highest,Score=Score};
        public void Restore(BoardSnapshot snapshot)
        {
            if(snapshot==null||snapshot.Values==null||snapshot.Values.Length!=25||snapshot.Values.Any(v=>v<0||v>36)||snapshot.Highest<1||snapshot.Highest>36||snapshot.Score<0)
                throw new ArgumentException("Invalid board snapshot");
            Load(snapshot.Values,snapshot.Highest);Score=snapshot.Score;
        }
        public Cell At(int x,int y)=>x<0||x>=5||y<0||y>=5?null:cells[y*5+x];
        public IEnumerable<Cell> Cells=>cells.Where(c=>c!=null);
        public int[] Values()=>cells.Select(c=>c==null?0:c.Level).ToArray();
        public Cell Find(int id)=>Cells.FirstOrDefault(c=>c.Id==id);
        public void Load(int[] values,int historicalHighest=1)
        {
            if(values.Length!=25||values.Any(v=>v<0||v>36))throw new ArgumentException("25 levels in 0..36 required");
            Array.Clear(cells,0,25);nextId=1;Score=0;Highest=Math.Max(1,historicalHighest);
            for(int i=0;i<25;i++)if(values[i]>0)cells[i]=new Cell(nextId++,values[i],i%5,i/5);
        }
        public List<Cell> Group(Cell start,bool breadthFirst)
        {
            var output=new List<Cell>();
            if(start==null||start.Level>=36||At(start.X,start.Y)!=start)return output;
            var visited=new HashSet<int>();
            if(!breadthFirst)
            {
                Action<Cell> visit=null;
                visit=c=>{if(c==null||c.Level!=start.Level||!visited.Add(c.Id))return;
                    output.Add(c);foreach(int n in BoardRefillPolicy.Neighbors(c.Y*5+c.X,5,25))visit(cells[n]);};
                visit(start);
            }
            else
            {
                var pending=new Queue<Cell>();pending.Enqueue(start);visited.Add(start.Id);
                while(pending.Count>0)
                {
                    var c=pending.Dequeue();output.Add(c);
                    foreach(int n in BoardRefillPolicy.Neighbors(c.Y*5+c.X,5,25))
                    {var other=cells[n];if(other!=null&&other.Level==start.Level&&visited.Add(other.Id))pending.Enqueue(other);}
                }
            }
            return output;
        }
        public List<Cell> FindAutomatic(IEnumerable<Cell> settled)
        {
            foreach(var c in settled.Where(c=>c!=null&&Find(c.Id)!=null&&c.Level<36).Distinct().OrderBy(c=>c.Y*5+c.X))
            {var group=Group(c,true);if(group.Count>=2)return group;}
            return new List<Cell>();
        }
        public MergeStep Prepare(Cell target,List<Cell> group,int stepIndex)
        {
            if(target==null||group.Count<2||!group.Contains(target)||target.Level>=36||
               group.Any(c=>At(c.X,c.Y)!=c||c.Level!=target.Level))throw new ArgumentException("Invalid merge group");
            int index=group.IndexOf(target),maxSteps=Math.Max(group.Count-1-index,index);
            double action=Math.Max(0.045,0.36/group.Count)*(stepIndex>0?Math.Pow(0.85,stepIndex):1);
            return new MergeStep{Target=target,Group=group,SourceLevel=target.Level,StepIndex=stepIndex,
                Automatic=stepIndex>0,ActionTime=action,Duration=(maxSteps+1)*action+0.08};
        }
        public void Apply(MergeStep step)
        {
            foreach(var c in step.Group)if(c!=step.Target)Remove(c);
            step.Target.Level++;Highest=Math.Max(Highest,step.Target.Level);
            Score+=(step.Group.Count-1)*step.SourceLevel*2;
        }
        public void Remove(Cell cell){if(cell!=null&&At(cell.X,cell.Y)==cell)cells[cell.Y*5+cell.X]=null;}
        public List<CellMove> Compact()
        {
            var moves=new List<CellMove>();
            for(int x=0;x<5;x++)
            {
                int writeY=0;
                for(int y=0;y<5;y++)
                {
                    var c=At(x,y);if(c==null)continue;
                    if(y!=writeY){moves.Add(new CellMove{Cell=c,FromX=x,FromY=y});cells[y*5+x]=null;cells[writeY*5+x]=c;c.Y=writeY;}
                    writeY++;
                }
            }
            return moves;
        }
        public List<Cell> Refill(Func<double> random)
        {
            var born=new List<Cell>();
            for(int y=0;y<5;y++)for(int x=0;x<5;x++)if(At(x,y)==null)
            {
                int level=BoardRefillPolicy.Sample(Highest,Values(),5,y*5+x,random());
                var c=new Cell(nextId++,level,x,y);cells[y*5+x]=c;born.Add(c);
            }
            return born;
        }
        public bool HasMove()=>Cells.Any(c=>c.Level<36&&Group(c,false).Count>=2);
        public void Rearrange(IReadOnlyList<Cell> order)
        {
            var sites=Cells.OrderBy(c=>c.Y*5+c.X).Select(c=>c.Y*5+c.X).ToArray();
            if(order.Count!=sites.Length||order.Distinct().Count()!=sites.Length||order.Any(c=>!Cells.Contains(c)))throw new ArgumentException("Rearrange must preserve all cell identities");
            Array.Clear(cells,0,25);
            for(int i=0;i<sites.Length;i++){var c=order[i];c.X=sites[i]%5;c.Y=sites[i]/5;cells[sites[i]]=c;}
        }
        public void RecordResultHighest(Cell result){if(result!=null)Highest=Math.Max(Highest,result.Level);}
    }
}
