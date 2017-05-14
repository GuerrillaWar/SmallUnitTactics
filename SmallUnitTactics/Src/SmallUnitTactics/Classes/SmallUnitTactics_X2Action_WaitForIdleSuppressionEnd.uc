// This action waits for idle suppression to end, so we don't exit cover without having entered it and other things
// since the manager doesn't allow visualized units to run idle suppression,
// we don't run risk of never exiting / timing out, and other weirdness
class SmallUnitTactics_X2Action_WaitForIdleSuppressionEnd extends X2Action;

var float InitialTimeDilation;
var bool bAbilityEffectReceived;

function HandleTrackMessage()
{
	// stahp!
	bAbilityEffectReceived = true;
}

simulated state Executing
{
Begin:
	InitialTimeDilation = Unit.CustomTimeDilation;
	Unit.SetTimeDilation(1.5f);
	while (SmallUnitTactics_IdleAnimationStateMachine(Unit.IdleStateMachine).IsIdleSuppressing() && !bAbilityEffectReceived)
	{
		Sleep(0.0);
	}
	Unit.SetTimeDilation(InitialTimeDilation);
	if (!SmallUnitTactics_IdleAnimationStateMachine(Unit.IdleStateMachine).IsDormant())
	{
		SmallUnitTactics_IdleAnimationStateMachine(Unit.IdleStateMachine).GoDormant();
	}
	CompleteAction();
}
