// this is a runtime override: we swap out the AnimNotifies at runtime in the AnimSequences
class SmallUnitTactics_AnimNotify_ViewShake extends AnimNotify_ViewShake;

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
	super.Notify(Owner, AnimSeqInstigator);
}
