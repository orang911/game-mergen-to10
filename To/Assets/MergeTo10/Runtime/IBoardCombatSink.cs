using System.Collections;
using MergeTo10.Core;
namespace MergeTo10.Runtime
{
    // One owner per settlement. Complete waits for impacts; Cancel invalidates them synchronously.
    public interface IBoardCombatSink
    {
        void BeginSettlement();
        void RecordMerge(MergeAttack contribution);
        IEnumerator CompleteBatch(MergeAttackBatch batch);
        void EndSettlement();
        void CancelSettlement();
    }
}

