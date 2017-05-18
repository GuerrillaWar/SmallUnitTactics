// this is a runtime override: we swap out the AnimNotifies at runtime in the AnimSequences
class SmallUnitTactics_AnimNotify_CineScript extends AnimNotify_Scripted;

var() string EventLabel;

event Notify(Actor Owner, AnimNodeSequence AnimSeqInstigator)
{
	local XComUnitPawn Pawn;
	local XGUnitNativeBase OwnerUnit;
	Pawn = XComUnitPawn(Owner);
	if (Pawn != none)
	{
		OwnerUnit = Pawn.GetGameUnit();
		if (OwnerUnit != none)
		{
			if (SmallUnitTactics_IdleAnimationStateMachine(OwnerUnit.IdleStateMachine).IsIdleSuppressing())
			{
				return;
			}
		}
	}
	XComCamera(XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).PlayerCamera).OnAnimNotifyCinescript(EventLabel);
}
