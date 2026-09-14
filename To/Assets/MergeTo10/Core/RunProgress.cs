using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
namespace MergeTo10.Core {
 [Serializable] public sealed class RunCard {public string Id;public int Level,Selections;}
 [Serializable] public sealed class RunProgress {
  public int Merges,MaxMerge;
  public List<RunCard> Cards=new List<RunCard>();
  public void RecordMerge(int count){Merges++;MaxMerge=Math.Max(MaxMerge,count);}
  public void RecordCard(string id,int level){
   if(Array.IndexOf(MetaProgress.Cards,id)<0)throw new ArgumentException("Unknown run card");
   var card=Cards.FirstOrDefault(c=>c.Id==id);if(card==null){card=new RunCard{Id=id};Cards.Add(card);}
   card.Level=Mathf.Clamp(level,1,5);card.Selections++;
  }
  public RunProgress Copy()=>JsonUtility.FromJson<RunProgress>(JsonUtility.ToJson(this));
  public void Validate(){
   if(Merges<0||MaxMerge<0||MaxMerge>25||Cards==null||Cards.Any(c=>c==null||Array.IndexOf(MetaProgress.Cards,c.Id)<0||c.Level<1||c.Level>5||c.Selections<1)||
    Cards.Select(c=>c.Id).Distinct().Count()!=Cards.Count)throw new ArgumentException("Invalid run statistics");
  }
 }
}
