class SmallUnitTactics_IdleAnimationStateMachine extends XComIdleAnimationStateMachine;

// some projectiles (like the sectoid plasma pistol one) have a flag set that doesn't show them on suppression
// patch it up here!
struct ProjectileFixup
{
	var string ProjectilePath;
	var array<int> SuppressionProjectiles;
};

var config array<ProjectileFixup> ProjectileFixups;

var transient AnimNodeSequence PlaySeq;

var bool bOverrideReturnToState;
var name nmOverrideReturnToStateName;

var bool bRequestedGoDormantWhileIdleSuppressing;


// gw change -- allow idle suppression. required for the projectile system
function bool IsUnitSuppressing()
{
	return Unit.m_bSuppressing || GetStateName() == 'IdleSuppression';
}


function bool IsIdleSuppressing()
{
	local name StateName;
	StateName = GetStateName();
	return StateName == 'IdleSuppressionTurn' || StateName == 'IdleSuppressionStart' || StateName == 'IdleSuppression' || StateName == 'IdleSuppressionEnd';
}


state Idle
{

begin:
	bDeferredGotoIdle = false;

	if( !Unit.IsAlive() || UnitNative.GetVisualizedGameState().IsIncapacitated() || !Unit.GetIsAliveInVisualizer() )
	{
		//In the case where the unit is dead, make the idle state machine dormant
		GotoState('Dormant');
	}

	if( bWaitingForStanceEval )
	{		
		`log("*********************** GOTO EvaluateStance ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		GotoState('EvaluateStance');
	}

	if( bIsTurret && Unit.IsAlive() )
	{
		GotoState('TurretIdle');
	}
	else if( IsUnitPanicked() ) 
	{
		GotoState('Panicked');
	}
	else if( Unit.IsHunkeredDown() )
	{
		GotoState('HunkeredDown');
	}
	else if( ShouldUseTargetingAnims() )
	{
		GotoState('TargetingStart');
	}
	else if( PersistentEffectIdleName != '' )
	{
		GotoState('PersistentEffect');
	}
	else
	{
		if(FacePod(TempFaceLocation))
		{
			// in AI patrols, have the pod members turn to have each other while talking
			TurnTowardsPosition(TempFaceLocation);
		}

		PlayIdleAnim();
	}
	PeekTimeoutCurrent = Lerp(PeekTimeoutMin, PeekTimeoutMax, FRand());
	SetTimer(PeekTimeoutCurrent, false, nameof(PerformPeek), self);
}


function PerformPeek()
{
	if( class'SmallUnitTactics_IdleSuppressionManager'.static.GetIdleSuppressionManager().ShouldFireSuppression(UnitNative.GetVisualizedGameState(), TargetActor) )
	{
		TargetLocation = TargetActor.Location;
		if (XGUnit(TargetActor) != none)
		{
			TargetLocation = XGUnit(TargetActor).GetPawn().GetHeadshotLocation();
		}
		GoToState('IdleSuppressionTurn');
	}
	else
	{
		super.PerformPeek();
	}
}

function bool IsStateInterruptible()
{
	local name StateName;

	StateName = GetStateName();
	return StateName == 'Idle' || StateName == 'Dormant' || StateName == 'PeekStart' || StateName == 'TargetingStart' || StateName == 'TargetingHold' || StateName == 'Panicked' || StateName == 'TurretIdle'
				|| StateName == 'IdleSuppressionTurn';
}

// this state exists to give units a chance to turn to the right direction before attempting to shoot
// this is the same as what X2Action_ExitCover does, but there, the code is State Logic in a different class
// here, we need a dummy state
// if we called that from IdleSuppressionStart, we would need to push the state and pop it, but since it does GotoState, that's not possiböe
state IdleSuppressionTurn
{
	simulated function BeginState(name PrevStateName)
	{
		`log("SmallUnitTactics_IdleSuppression:" @ GetFuncName() @ PrevStateName $ "->" $ GetStateName());
	}

	simulated event EndState(name NextStateName)
	{
		`log("SmallUnitTactics_IdleSuppression:" @ GetFuncName() @ GetStateName() $ "->" $ NextStateName);
	}
Begin:
	bOverrideReturnToState = true;
	nmOverrideReturnToStateName = 'IdleSuppressionStart';
	CheckForStanceUpdate();
}

// This is based on peeking: step out of cover, take a shot, enter cover, go to idle
// if someone requests a stance update, it will then happen
// while a idle suppression shot is happening, we won't be able to do anything else!

// Also: this is copied from X2Action_ExitCover, without GameStates, Abilities, IdleStateMachines etc.
// note: we have reached idle, which means there isn't a stance update happening.
// if that's not enough, we'll have to turn manually
state IdleSuppressionStart
{
	simulated function BeginState(name PrevStateName)
	{
		`log("SmallUnitTactics_IdleSuppression:" @ GetFuncName() @ PrevStateName $ "->" $ GetStateName());
	}

	simulated event EndState(name NextStateName)
	{
		`log("SmallUnitTactics_IdleSuppression:" @ GetFuncName() @ GetStateName() $ "->" $ NextStateName);
	}

	
	// we use a function here to have local variables available
	function AnimNodeSequence PlayStepOutAnim()
	{
		local XComGameStateContext_Ability FakeContext;
		local Actor PrimaryTarget;
		local vector NewTargetLocation;
		local Vector TowardsTarget;

		local CustomAnimParams Params;
		local BoneAtom DesiredStartingAtom;
		local vector StepOutLocation;
		local bool bStepoutHasFloor;
		local int iHistIndex;

		local TTile StepOutTile;

		local int UseCoverDirectionIndex; //Set within GetExitCoverType
		local UnitPeekSide UsePeekSide;   //Set within GetExitCoverType
		local int RequiresLean;
		local int bCanSeeFromDefault;

		local XComGameState_Item WeaponState;
		local XGWeapon UseWeapon;

		local AnimNodeSequence FinishAnimNodeSequence;

		Unit.GetVisualizedGameState(iHistIndex);

		FakeContext = Unit.GetVisualizedGameState().m_SuppressionAbilityContext;
		PrimaryTarget = `XCOMHISTORY.GetGameStateForObjectID( FakeContext.InputContext.PrimaryTarget.ObjectID ).GetVisualizer();
		NewTargetLocation = X2VisualizerInterface(PrimaryTarget).GetShootAtLocation(FakeContext.ResultContext.HitResult, FakeContext.InputContext.SourceObject);
	
		WeaponState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(FakeContext.InputContext.ItemObject.ObjectID));
		UseWeapon = XGWeapon(WeaponState.GetVisualizer());
		MaybePatchupProjectiles(XComWeapon(UseWeapon.m_kEntity).DefaultProjectileTemplate);
		UnitPawn.SetCurrentWeapon(XComWeapon(UseWeapon.m_kEntity));
		UnitPawn.UpdateAnimations();
		UnitPawn.TargetLoc = NewTargetLocation;

		Unit.bShouldStepOut = Unit.GetStepOutCoverInfo(PrimaryTarget, NewTargetLocation, UseCoverDirectionIndex, UsePeekSide, RequiresLean, bCanSeeFromDefault, iHistIndex);

		UnitPawn.EnableRMAInteractPhysics(true);
		UnitPawn.EnableRMA(true, true);

		if( Unit.bShouldStepOut && Unit.m_eCoverState != eCS_None )
		{
			switch( Unit.m_eCoverState )
			{
				case eCS_LowLeft:
				case eCS_HighLeft:
					Params.AnimName = 'HL_StepOut';
					break;
				case eCS_LowRight:
				case eCS_HighRight:
					Params.AnimName = 'HR_StepOut';
					break;
			}
			DesiredStartingAtom.Translation = UnitPawn.Location;
			DesiredStartingAtom.Rotation = QuatFromRotator(UnitPawn.Rotation);
			DesiredStartingAtom.Scale = 1.0f;
			UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(Params, DesiredStartingAtom);

			// Find the tile location we are stepping to			
			StepOutLocation = Params.DesiredEndingAtom.Translation;
			if( `XWORLD.GetFloorTileForPosition(Params.DesiredEndingAtom.Translation, StepOutTile, false) )
			{
				StepOutLocation.Z = Unit.GetDesiredZForLocation(StepOutLocation);
				bStepoutHasFloor = true;
			}
			else
			{
				StepOutLocation.Z = Unit.GetDesiredZForLocation(StepOutLocation, false);
				bStepoutHasFloor = false;
			}
			if( RequiresLean == 1 )
			{
				//Turn off all IK, the unit may be clipping into railings to make this shot
				UnitPawn.bSkipIK = true;
				UnitPawn.EnableFootIK(false);

				//Step out a little further if there is floor, otherwise don't step outside our tile
				if( bStepoutHasFloor )
				{
					Params.DesiredEndingAtom.Translation = UnitPawn.Location + (Normal(StepOutLocation - UnitPawn.Location) * VSize(StepOutLocation - UnitPawn.Location) * 0.70f);
				}
				else
				{
					UnitPawn.bNoZAcceleration = true; //Don't allow falling if there is no floor where we are going
					Params.DesiredEndingAtom.Translation = UnitPawn.Location + (Normal(StepOutLocation - UnitPawn.Location) * VSize(StepOutLocation - UnitPawn.Location) * 0.5f);
				}
			}
			else
			{
				Params.DesiredEndingAtom.Translation = StepOutLocation;
			}
			// Now Determine our facing based on our ending location and the target
			TowardsTarget = NewTargetLocation - Params.DesiredEndingAtom.Translation;
			TowardsTarget.Z = 0;
			TowardsTarget = Normal(TowardsTarget);
			Params.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(TowardsTarget));
			FinishAnimNodeSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
			Unit.bSteppingOutOfCover = true;
		}
		if( Unit.bShouldStepOut == false )
		{
			Params.HasDesiredEndingAtom = true;
			Params.DesiredEndingAtom.Scale = 1.0f;
			Params.DesiredEndingAtom.Translation = UnitPawn.Location;
			TowardsTarget = NewTargetLocation - UnitPawn.Location;
			TowardsTarget.Z = 0;
			TowardsTarget = Normal(TowardsTarget);
			Params.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(TowardsTarget));
			switch( Unit.m_eCoverState )
			{
			case eCS_LowLeft:
			case eCS_LowRight:
				Params.AnimName = 'LL_FireStart';
				break;
			case eCS_HighLeft:
			case eCS_HighRight:
				Params.AnimName = 'HL_FireStart';
				break;
			case eCS_None:
				Params.AnimName = 'NO_FireStart';
				break;
			}

			if( UnitPawn.GetAnimTreeController().CanPlayAnimation(Params.AnimName) )
			{
				FinishAnimNodeSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
			}
			else
			{
				if( UseWeapon != None && XComWeapon(UseWeapon.m_kEntity) != None && XComWeapon(UseWeapon.m_kEntity).WeaponAimProfileType != WAP_Unarmed )
				{
					UnitPawn.UpdateAimProfile();
					UnitPawn.SetAiming(true, 0.5f, 'AimOrigin', false);
				}
			}
		}
		return FinishAnimNodeSequence;
	}

Begin:
	
	UnitPawn.EnableLeftHandIK(true);
	Unit.RestoreLocation = UnitPawn.Location;
	Unit.RestoreHeading = vector(UnitPawn.Rotation);
	FinishAnim(PlayStepOutAnim());

	if (bRequestedGoDormantWhileIdleSuppressing)
	{
		// end asap
		GotoState('IdleSuppressionEnd');
	}
	else
	{
		GotoState('IdleSuppression');
	}
}

state IdleSuppression
{
	simulated function BeginState(name PrevStateName)
	{
		`log("SmallUnitTactics_IdleSuppression:" @ GetFuncName() @ PrevStateName $ "->" $ GetStateName());
	}

	simulated event EndState(name NextStateName)
	{
		`log("SmallUnitTactics_IdleSuppression:" @ GetFuncName() @ GetStateName() $ "->" $ NextStateName);
	}

	simulated function Name GetSuppressAnimName()
	{
		local XComWeapon Weapon;

		Weapon = XComWeapon(UnitPawn.Weapon);
		if( Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponSuppressionFireAnimSequenceName) )
		{
			return Weapon.WeaponSuppressionFireAnimSequenceName;
		}
		else if( UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponSuppressionFireAnimSequenceName) )
		{
			return class'XComWeapon'.default.WeaponSuppressionFireAnimSequenceName;
		}
		else if( UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponFireAnimSequenceName) )
		{
			return Weapon.WeaponFireAnimSequenceName;
		}
	}
	
Begin:
	XComWeapon(UnitPawn.Weapon).Spread[0] = 0.05f;

//	UnitPawn.TargetLoc = Unit.AdjustTargetForMiss(XGUnit(TargetActor), 3.0f);
	AnimParams = default.AnimParams;
	AnimParams.AnimName = GetSuppressAnimName();
	//PatchUpSequence(AnimParams.AnimName);
	PlaySeq = UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	PatchUpSingleSequence(PlaySeq.AnimSeq);
	FinishAnim(PlaySeq);

	GotoState('IdleSuppressionEnd');
}
/*
function PatchUpSequence(name SeqName)
{
	local AnimSequence Seq;
	local int ch;

	Seq = UnitPawn.Mesh.FindAnimSequence(SeqName);
	if (Seq != none)
	{
		PatchUpSingleSequence(Seq);
	}
	// they tend to have FF_FireA etc. just do a loop to catch A, B, C, stop when D isn't present
	ch = 65;
	Seq = UnitPawn.Mesh.FindAnimSequence(name(SeqName $ Chr(ch)));
	while (Seq != none)
	{
		PatchUpSingleSequence(Seq);
		Seq = UnitPawn.Mesh.FindAnimSequence(name(SeqName $ Chr(++ch)));
	}
}
*/
static function AnimSequence PatchUpSingleSequence(AnimSequence Sequence)
{
	local int i;
	local bool bDidAPatch;
	bDidAPatch = false;
	for (i = 0; i < Sequence.Notifies.Length; i++)
	{
		if (Sequence.Notifies[i].Notify.Class.Name == 'AnimNotify_ViewShake')
		{
			// create a replacement with the same outer as the original notify and using that as a template
			Sequence.Notifies[i].Notify = new (Sequence.Notifies[i].Notify.Outer) class'SmallUnitTactics_AnimNotify_ViewShake' (Sequence.Notifies[i].Notify);
			bDidAPatch = true;
		}
	}
	if (bDidAPatch)
	{
		`log("Changed" @ PathName(Sequence));
	}
	return Sequence;
}

// todo: play animation
state IdleSuppressionEnd
{
	simulated function BeginState(name PrevStateName)
	{
		`log("SmallUnitTactics_IdleSuppression:" @ GetFuncName() @ PrevStateName $ "->" $ GetStateName());
	}

	simulated event EndState(name NextStateName)
	{
		`log("SmallUnitTactics_IdleSuppression:" @ GetFuncName() @ GetStateName() $ "->" $ NextStateName);
	}

	// we use a function here to have local variables available
	function AnimNodeSequence PlayStepInAnim()
	{
		local CustomAnimParams Params;
		local AnimNodeSequence SeqToPlay;
		UnitPawn.EnableLeftHandIK(false);
		UnitPawn.EnableRMAInteractPhysics(true);
		UnitPawn.EnableRMA(true, true);

		if( Unit.CanUseCover() && Unit.bSteppingOutOfCover )
		{
			Unit.bShouldStepOut = false;

			Params.HasDesiredEndingAtom = true;
			Params.DesiredEndingAtom.Translation = Unit.RestoreLocation;
			Params.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(Unit.RestoreHeading));
			Params.DesiredEndingAtom.Scale = 1.0f;

			switch (Unit.m_eCoverState)
			{
				case eCS_LowLeft:
				case eCS_HighLeft:
					Params.AnimName = 'HL_StepIn';
					break;
				case eCS_LowRight:
				case eCS_HighRight:
					Params.AnimName = 'HR_StepIn';
					break;
				case eCS_None:
					Params.AnimName = 'NO_IdleGunUp';
					break;
			}
			SeqToPlay = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
		}
		else
		{
			Params.HasDesiredEndingAtom = true;
			Params.DesiredEndingAtom.Translation = Unit.RestoreLocation;
			Params.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(Unit.RestoreHeading));
			Params.DesiredEndingAtom.Scale = 1.0f;

			switch (Unit.m_eCoverState)
			{
				case eCS_LowLeft:
				case eCS_LowRight:
					Params.AnimName = 'LL_FireStop';
					break;
				case eCS_HighLeft:
				case eCS_HighRight:
					Params.AnimName = 'HL_FireStop';
					break;
				case eCS_None:
					Params.AnimName = 'NO_FireStop';
					break;
			}
			if (UnitPawn.GetAnimTreeController().CanPlayAnimation(Params.AnimName))
			{
				SeqToPlay = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
			}


		}
		return SeqToPlay;
	}

Begin:
	if (Unit.IsAlive())
	{
		PlaySeq = PlayStepInAnim();
		if (PlaySeq != none)
		{
			FinishAnim(PlaySeq);
		}
		else if (XComWeapon(UnitPawn.Weapon).WeaponAimProfileType != WAP_Unarmed)
		{
			UnitPawn.SetAiming(false, 0.5f);
		}
		if (VSizeSq(UnitPawn.Location - Unit.RestoreLocation) > 16 * 16)
		{
			// Forcefully set location to restore location
			UnitPawn.SetLocation(Unit.RestoreLocation);
		}
		if (PlaySeq != none)
		{
			ForceHeading(Unit.RestoreHeading);
		}

		
		//Reset RMA systems
		UnitPawn.EnableRMA(false, false);
		UnitPawn.EnableRMAInteractPhysics(false);
		UnitPawn.bSkipIK = false;
		UnitPawn.EnableFootIK(true);
		UnitPawn.bNoZAcceleration = false;

		Unit.bSteppingOutOfCover = false;

		Unit.UpdateInteractClaim();

		Unit.IdleStateMachine.CheckForStanceUpdateOnIdle();

		if (bRequestedGoDormantWhileIdleSuppressing)
		{
			bRequestedGoDormantWhileIdleSuppressing = false;
			GotoState('Dormant');
		}
		else
		{
			GotoState('Idle');
		}
	}
	else
	{
		GotoState('Dormant');
	}
}

static function MaybePatchupProjectiles(X2UnifiedProjectile Proj)
{
	local int i, j;
	i = default.ProjectileFixups.Find('ProjectilePath', PathName(Proj));
	if (i != INDEX_NONE)
	{
		for (j = 0; j < default.ProjectileFixups[i].SuppressionProjectiles.Length; j++)
		{
			Proj.ProjectileElements[default.ProjectileFixups[i].SuppressionProjectiles[j]].bPlayOnSuppress = true;
		}
	}
}

// functionality overrides

state EvaluateStance
{
	// don't lock up when Turning towards the right position
	event BeginState(name PreviousStateName)
	{		
		super.BeginState(PreviousStateName);
		if (bOverrideReturnToState)
		{
			ReturnToState = nmOverrideReturnToStateName;
			bOverrideReturnToState = false;
		}
	}

}



//De-activates the state machine, used when the unit intends to perform an action that will override the unit's animations. The force flag permits external users
//to make the system allow going dormant from states such as 'HunkeredDown'. In this situation, the caller is responsible for restoring the proper state when its business is done.
simulated function GoDormant(optional Actor LockResume=none, optional bool Force=false, optional bool bDisableWaitingForEval=false)
{
	local name Statename;	

	Statename = GetStateName();
	if (bDisableWaitingForEval)
		bWaitingForStanceEval = false;

	if (kDormantLock != none && kDormantLock != LockResume)
	{
		`log("*********************** IdleStateMachine GoDormant() ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Dormant state is locked by" @ kDormantLock @ "but new GoDormant request was made by" @ LockResume @ ", cannot GoDormant");
		return;     //  don't override existing lock
	}
	kDormantLock = LockResume;
	
	if( Statename != 'EvaluateStance' && !IsIdleSuppressing())
	{
		if( Force || (Statename != 'HunkeredDown' && Statename != 'Strangling' && Statename != 'Strangled' && Statename != 'NeuralDampingStunned')) //These are equivalent to dormant - except that evaluate stance cannot be called from them
		{			
			`log("*********************** IdleStateMachine GoDormant() ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("Dormant now locked by" @ LockResume,  `CHEATMGR.MatchesXComAnimUnitName(Unit.Name) && LockResume != none, 'XCom_Anim');
			`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			
			GotoState('Dormant');
		}
	}
	else if (IsIdleSuppressing()) // GW change
	{
		bRequestedGoDormantWhileIdleSuppressing = true;
	}
	else
	{
		`log("*********************** IdleStateMachine Requested GoDormant() - bDeferredGotoDormant = true ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		bDeferredGotoIdle = false;
		bDeferredGotoDormant = true;
	}
}

//Returns true if a target has been found. Used by the EvaluateStance state
event bool SetTargetUnit()
{		
	local X2Action_ExitCover ExitCoverAction;
	local Vector NewTargetLocation;
	local Actor  NewTargetActor;
	local XGUnit TempUnit;
	local int CoverIndex;
	local int BestCoverIndex;
	local float CoverScore;
	local float BestCoverScore;	
	local bool bEnemiesVisible;
	local bool bFoundTarget;	
	local bool bCurrentlyTargeting;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;
	local XComGameStateHistory History;
	local X2TargetingMethod TargetingMethod;
	local UITacticalHUD TacticalHUD;
	local bool bActorFromTargetingMethod;
	local int HasEnemiesOnLeftPeek;
	local int HasEnemiesOnRightPeek;
	local UnitPeekSide PeekSide;
	local int CanSeeFromDefault;
	local int RequiresLean;
	
	History = `XCOMHISTORY;
	UnitState = UnitNative.GetVisualizedGameState();

	if( UnitState == None )
	{
		return false;
	}

	NewTargetActor = TargetActor;
	NewTargetLocation = TargetLocation;	
	bFoundTarget = false; //return value, indicates whether there were any targets for this unit, if there were none we clear the target info	
	bEnemiesVisible = UnitState.GetNumVisibleEnemyUnits() > 0;

	`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	`log("*** Processing SetTargetUnit ***", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

//******** Find the current values for NewTargetActor and NewTargetLocation **********	
	TacticalHUD = `PRES.GetTacticalHUD();
	if (TacticalHUD != none)
		TargetingMethod = TacticalHUD.GetTargetingMethod();
	else
		TargetingMethod = none;

	bCurrentlyTargeting = TargetingMethod != none;
	
	//If targeting is happening, and we are the shooter
	// Can also happen if the source unit is doing a multi turn ability
	bActorFromTargetingMethod = bCurrentlyTargeting && (TargetingMethod.Ability.OwnerStateObject.ObjectID == UnitState.ObjectID);
	if ( bActorFromTargetingMethod || (UnitState.m_MultiTurnTargetRef.ObjectID > 0) )
	{
		if( bActorFromTargetingMethod )
		{
			NewTargetActor = TargetingMethod.GetTargetedActor();
		}
		else
		{
			NewTargetActor = History.GetVisualizer(UnitState.m_MultiTurnTargetRef.ObjectID);
		}

		// can't Target yourself, so just early out to focus on the shooter
		if (NewTargetActor == Unit)
		{
			NewTargetActor = LastAttacker; 
			TargetActor = NewTargetActor;
			if( TargetActor != None )
			{
				TargetLocation = TargetActor.Location;
			}
			return TargetActor != none;
		}
		else if ( (bActorFromTargetingMethod && TargetingMethod.GetCurrentTargetFocus(NewTargetLocation)) || (NewTargetActor != None) )
		{
			bFoundTarget = true;
		}
	}
	else if( Unit.CurrentExitAction != none ) //If we are performing a fire sequence
	{	
		`log("     Unit is performing a targeting action:", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		ExitCoverAction = Unit.CurrentExitAction;
			
		bFoundTarget = true;
		NewTargetActor = ExitCoverAction.PrimaryTarget;
		if( ExitCoverAction.PrimaryTarget != none )
		{
			if( ExitCoverAction.PrimaryTarget == Unit )
			{
				`log("          *ExitCover action has a target, it is ourselves. Do Nothing.", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
				bFoundTarget = false;
			}
			else
			{
				`log("          *ExitCover action has a target, aiming at"@NewTargetActor, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
				NewTargetLocation = ExitCoverAction.AimAtLocation;
			}
		}
		else
		{
			`log("          *ExitCover action has no primary target, aiming at"@ExitCoverAction.TargetLocation, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			NewTargetLocation = ExitCoverAction.AimAtLocation;
		}			
	}
	else if( bEnemiesVisible ) //If enemies are visible but we are not in a targeting action
	{
		`log("     Unit is idle and there are visible enemies:", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');		
		//Face enemies that are attacking us (and visible) first, but not if they are dead or dying
		if (LastAttacker != none && 
			LastAttacker.IsAlive() &&
			!LastAttacker.GetVisualizedGameState().IsIncapacitated() &&
			Unit.GetDirectionInfoForTarget(LastAttacker, CoverIndex, PeekSide, CanSeeFromDefault, RequiresLean) )
		{			
			`log("          *LastAttacker is not none, aiming at LastAttacker:"@LastAttacker, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			NewTargetActor = LastAttacker;
		}
		else //Fall back to facing the closest enemy
		{
			TestEnemyUnitsForPeekSides(DesiredCoverIndex, HasEnemiesOnLeftPeek, HasEnemiesOnRightPeek);
			if( (DesiredPeekSide == ePeekLeft && HasEnemiesOnLeftPeek == 1) || (DesiredPeekSide == ePeekRight && HasEnemiesOnRightPeek == 1) )
			{
				NewTargetActor = GetClosestEnemyForPeekSide(DesiredCoverIndex, DesiredPeekSide);
			}
			else if( class'X2TacticalVisibilityHelpers'.static.GetClosestVisibleEnemy(UnitNative.ObjectID, OutVisibilityInfo, VisualizationMgr.LastStateHistoryVisualized) )
			{
				NewTargetActor = XGUnit( History.GetVisualizer(OutVisibilityInfo.TargetID) );
			}
			// GW change -- take unit from idle suppressing
			if (!class'SmallUnitTactics_IdleSuppressionManager'.static.GetIdleSuppressionManager().ShouldFireSuppression(Unit.GetVisualizedGameState(), NewTargetActor))
			{
				`log("          *LastAttacker is none, aiming at closest visible enemy:"@NewTargetActor, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			}
			// GW change end
		}

		if( NewTargetActor != none )
		{
			bFoundTarget = true;			
			NewTargetLocation = NewTargetActor.Location;
			TempUnit = XGUnit(NewTargetActor);
			if( TempUnit != None )
			{
				NewTargetLocation = TempUnit.GetPawn().GetHeadshotLocation();
			}
		}
	}
	else //In the absence of a valid target, we should choose a valid cover direction and use the cover
	{
		`log("     No targets were found, clearing targeting state", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		ClearTargetInformation();
		
		BestCoverScore = 0.0f;
		BestCoverIndex = -1;

		if( UnitNative.CanUseCover() )
		{
			CurrentCoverPeekData = UnitNative.GetCachedCoverAndPeekData(VisualizationMgr.LastStateHistoryVisualized);
			for (CoverIndex = 0; CoverIndex < 4; CoverIndex++)
			{
				if( CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].bHasCover == 1 )
				{
					CoverScore = 1.0f;
					if( CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].LeftPeek.bHasPeekaround == 1 ||
						CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].RightPeek.bHasPeekaround == 1 )
					{
						CoverScore += 1.0f;
					}

					if( DesiredCoverIndex == CoverIndex )
					{
						CoverScore += 0.1f;
					}

					if( CoverScore > BestCoverScore )
					{
						BestCoverIndex = CoverIndex;
						BestCoverScore = CoverScore;
					}
				}
			}		

			bFoundTarget = true;
			NewTargetActor = none;
			if( BestCoverIndex > -1 )
			{
				NewTargetLocation = Unit.Location + (CurrentCoverPeekData.CoverDirectionInfo[BestCoverIndex].CoverDirection * 1000.0f);
			}
			else
			{
				NewTargetLocation = Unit.Location + (Vector(Unit.Rotation) * 1000.0f); // Aim straight forward
			}
		}	
	}
//************************************************************************************
	
//******** Ascertain whether the target/target location, or our location, has changed **********
	if( bFoundTarget )
	{
		`log("     A target was found, processing the target:", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

		`log("          *(NewTargetLocation != TargetLocation):"@(NewTargetLocation != TargetLocation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');			
		TargetLocation = NewTargetLocation;

		`log("          *(NewTargetActor != TargetActor):"@(NewTargetActor != TargetActor), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

		// Check to see if we were previously targeting a unit and no longer are
		TempUnit = XGUnit(TargetActor);
		if( TempUnit != none && 
		    !bActorFromTargetingMethod &&
			TempUnit.IdleStateMachine.LastAttacker != none &&
			TempUnit.IdleStateMachine.LastAttacker == Unit) //In order for us clearing the last attacker to be valid, we must have been the last attacker
		{	
			TempUnit.IdleStateMachine.LastAttacker = none;
		}

		TargetActor = NewTargetActor;			

		//If the new target actor is an XGUnit, mark us as an attacker
		TempUnit = XGUnit(TargetActor);
		if(TempUnit != none && bActorFromTargetingMethod && TempUnit.IdleStateMachine.LastAttacker != Unit)
		{   
			TempUnit.IdleStateMachine.LastAttacker = Unit;
			TempUnit.IdleStateMachine.CheckForStanceUpdate(); //Tell the target that we are targeting them now
		}
	}
//**********************************************************************************************

	UnitPawn.TargetLoc = TargetLocation;

	`log("     SetTargetUnit returning:"@bFoundTarget, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	`log("*** End Processing SetTargetUnit ***", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

	`assert(TargetActor != Unit);
	return bFoundTarget;
}
