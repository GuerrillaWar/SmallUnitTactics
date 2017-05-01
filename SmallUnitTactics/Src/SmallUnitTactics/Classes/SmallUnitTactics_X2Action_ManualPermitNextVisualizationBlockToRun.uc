class SmallUnitTactics_X2Action_ManualPermitNextVisualizationBlockToRun extends X2Action;

simulated state Executing
{
Begin:
    `XCOMVISUALIZATIONMGR.ManualPermitNextVisualizationBlockToRun(CurrentHistoryIndex);
    CompleteAction();
}
