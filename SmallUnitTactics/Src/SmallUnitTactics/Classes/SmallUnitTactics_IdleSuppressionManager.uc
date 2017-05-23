// q: do we prevent shooting from and at units that have a PENDING but not active block?
// it's safer, but does spoil a lot about what's happening 
class SmallUnitTactics_IdleSuppressionManager extends Actor config(Animation);

var config int ShootChance;
var config array<name> ValidWeaponCats;

static function SmallUnitTactics_IdleSuppressionManager GetIdleSuppressionManager()
{
	local Object ThisObj;
	local SmallUnitTactics_IdleSuppressionManager Mgr;
	foreach `TACTICALGRI.AllActors(class'SmallUnitTactics_IdleSuppressionManager', Mgr)
	{
		return Mgr;
	}
	Mgr = `TACTICALGRI.Spawn(class'SmallUnitTactics_IdleSuppressionManager', `TACTICALGRI);
	ThisObj = Mgr;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'AbilityActivated', static.OnAbilityActivated, ELD_OnStateSubmitted);
	return Mgr;
}

// Insert wait action for shooter
static function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none)
	{
		AbilityContext.PostBuildVisualizationFn.AddItem(InsertWaitActionToShooterTrack);
	}
	return ELR_NoInterrupt;
}

simulated static function InsertWaitActionToShooterTrack(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext_Ability AbilityContext;
	local VisualizationTrack Track;
	local SmallUnitTactics_X2Action_WaitForIdleSuppressionEnd WaitAction;
	local int TrackIndex;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	for (TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; TrackIndex++)
	{
		//if (OutVisualizationTracks[TrackIndex].StateObject_OldState.ObjectID == AbilityContext.InputContext.SourceObject.ObjectID)
		// ALL XGUnits need to wait. otherwise, their IdleAnimationStateMachines can go dormant after the action has actually visualized
		// unfortunately, everything that does manual timing will look off. Consider using X2Action_WaitForAbilityEffect instead
		if (XGUnit(OutVisualizationTracks[TrackIndex].TrackActor) != none)
		{
			Track = OutVisualizationTracks[TrackIndex];
			// unreal compiler weirdness
			if (!`XCOMVISUALIZATIONMGR.TrackHasActionOfType(Track, class'SmallUnitTactics_X2Action_WaitForIdleSuppressionEnd'))
			{
				WaitAction = SmallUnitTactics_X2Action_WaitForIdleSuppressionEnd(class'SmallUnitTactics_X2Action_WaitForIdleSuppressionEnd'.static.CreateVisualizationAction(AbilityContext));
				OutVisualizationTracks[TrackIndex].TrackActions.InsertItem(0, WaitAction);
			}
		}
	}
}



// HAX HAX HAX
// we fill out the suppressingabilityContext of the unit state that is lingering somewhere in history
// yes, it's bad. no, we can't change it
function bool ShouldFireSuppression(XComGameState_Unit UnitState, out Actor TargetActor)
{
	local int iVisualizedState;
	local XComGameState_Unit TargetState;
	local XComGameStateContext_Ability FakeContext;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	// fill out variable
	XGUnit(UnitState.GetVisualizer()).GetVisualizedGameState(iVisualizedState);
	
	if (!UnitCanShoot(UnitState, iVisualizedState))
	{
		return false;
	}
	TargetState = ChooseSuppressTarget(UnitState, iVisualizedState);
	if (TargetState == none)
	{
		return false;
	}

	FakeContext = CreateFakeSuppressionContext(UnitState, TargetState, iVisualizedState);
	if (FakeContext == none)
	{
		return false;
	}

	TargetActor = XGUnit(TargetState.GetVisualizer());
	if (TargetActor == none)
	{
		return false;
	}

	// no idea what gets picked up where, just set it everywhere
	// unit state is such a horrible place for that
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference));
	UnitState.m_SuppressionAbilityContext = FakeContext;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, iVisualizedState));
	UnitState.m_SuppressionAbilityContext = FakeContext;
	return true;
}

static function bool UnitCanShoot(XComGameState_Unit UnitState, int iVisualizedState)
{
	local XComGameStateVisualizationMgr VisualizationMgr;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	
	// don't start shooting when you are selected
	if (XComTacticalController(`XCOMGRI.GetALocalPlayerController()).ControllingUnit.ObjectID == UnitState.ObjectID)
	{
		return false;
	}
	// not when participating in Visualization Actions
	if (VisualizationMgr.IsActorBeingVisualized(UnitState.GetVisualizer(), false))
	{
		return false;
	}
	// not when on overwatch / suppressing
	if (UnitState.ReserveActionPoints.Length > 0)
	{
		return false;
	}
	// only if you aren't AI or are in red alert
	if (UnitState.ControllingPlayerIsAI() && UnitState.GetCurrentStat(eStat_AlertLevel) < 2)
	{
		return false;
	}
	/* // only if we are in cover */
	/* if (UnitState.CanTakeCover() && !XGUnit(UnitState.GetVisualizer()).IsInCover()) */
	/* { */
	/* 	return false; */
	/* } */
	// only if we aren't concealed
	if (UnitState.IsConcealed())
	{
		return false;
	}
	// only if we succeed the random roll
	// this is a game state safe random roll, basically
	// the result will be new when a new event happens, and since event chains are quite lengthy, we won't see a pattern
	// eventually, this will be replaced when it actually reads data from the battlefield
	/* RandRoll = ((UnitState.ObjectID + iVisualizedState) * 71) % 100; */
	/* if (RandRoll >= default.ShootChance) */
	/* { */
	/* 	return false; */
	/* } */

	// only if we aren't flanked
	if (class'X2TacticalVisibilityHelpers'.static.GetNumFlankingEnemiesOfTarget(UnitState.ObjectID, iVisualizedState) > 0)
	{
		return false;
	}

  // only if we've shot at someone and apply an ambient suppression penalty
  if (UnitState.AppliedEffectNames.Find('AmbientSuppression') == INDEX_NONE)
  {
    return false;
  }

	return true;
}

// shoot a random visible unit that is not participating in a visualization sequence
// we don't want it to switch again and again, so we're hacking it by seeding it the current history index and source unit state
static function XComGameState_Unit ChooseSuppressTarget(XComGameState_Unit SourceUnitState, int iHistIndex)
{
	local XComGameStateHistory History;
	local XComGameState_Effect Effect;
  local StateObjectReference EffectRef;

	History = `XCOMHISTORY;

  foreach SourceUnitState.AppliedEffects(EffectRef)
  {
    Effect = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID, , iHistIndex));
    if (Effect.GetX2Effect().EffectName == 'AmbientSuppression')
    {
      return XComGameState_Unit(
        History.GetGameStateForObjectID(
          Effect.ApplyEffectParameters.TargetStateObjectRef.ObjectID, , iHistIndex
        )
      );
    }
  }
}

// notes:
// 1. We need ability context, state, item. the UnifiedProjectile requires it.
// for that purpose, each unit has that dummy ability

static function XComGameStateContext_Ability CreateFakeSuppressionContext(XComGameState_Unit Source, XComGameState_Unit Target, int iHistoryIndex)
{
	local XComGameStateContext_Ability DummyContext;
	local AbilityInputContext InputContext;
	local AbilityResultContext ResultContext;
	local XComGameStateHistory History;
	local XComGameState_Item SourceWeapon;

	if (Source.FindAbility('SmallUnitTactics_IdleSuppression_DONTUSE').ObjectID <= 0)
	{
		return none;
	}

	InputContext.AbilityTemplateName = 'SmallUnitTactics_IdleSuppression_DONTUSE';
	InputContext.AbilityRef = Source.FindAbility('SmallUnitTactics_IdleSuppression_DONTUSE');
	InputContext.PrimaryTarget = Target.GetReference();
	InputContext.SourceObject = Source.GetReference();
	InputContext.ItemObject = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(InputContext.AbilityRef.ObjectID)).SourceWeapon;

	SourceWeapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(InputContext.ItemObject.ObjectID));
	
	if (default.ValidWeaponCats.Find(X2WeaponTemplate(SourceWeapon.GetMyTemplate()).WeaponCat) == INDEX_NONE)
	{
		return none;
	}

	ResultContext.CalculatedHitChance = 100;
	ResultContext.HitResult = eHit_Success;

	// is that enough? hope so
	DummyContext = new class'XComGameStateContext_Ability';
	DummyContext.InputContext = InputContext;
	DummyContext.ResultContext = ResultContext;

	// without modifying the history index, units shoot at the future locations of targets
	History = `XCOMHISTORY;
	History.SetCurrentHistoryIndex(iHistoryIndex);
	class'X2Ability'.static.UpdateTargetLocationsFromContext(DummyContext);
	History.SetCurrentHistoryIndex(-1);
	return DummyContext;
}
