class SmallUnitTactics_GameState_Effect_PrimedGrenade extends XComGameState_BaseObject;

var bool OnExplosionTurn;
var StateObjectReference SourceGrenade;

function XComGameState_Effect GetOwningEffect()
{
	return XComGameState_Effect(`XCOMHISTORY.GetGameStateForObjectID(OwningObjectId));
}

function EventListenerReturn OnTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Effect Effect;
  local XComGameState_Unit SourceUnit;
  local Object EffectObj;
  local SmallUnitTactics_GameState_Effect_PrimedGrenade NewEffectState;
  local XComGameState NewGameState;

	Effect = GetOwningEffect();
  EffectObj = self;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("X2Effect_PrimedGrenade: Marking Explosion Turn");
  NewEffectState = SmallUnitTactics_GameState_Effect_PrimedGrenade(
    NewGameState.CreateStateObject(Class, ObjectID)
  );
  NewEffectState.OnExplosionTurn = true;
  NewGameState.AddStateObject(NewEffectState);
  `TACTICALRULES.SubmitGameState(NewGameState);

  `log("WILL EXPLODE SOON");
  /* DetonateGrenade(Effect, SourceUnit, GameState); */
  return ELR_NoInterrupt;
}

function EventListenerReturn OnTurnEnded(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Effect Effect;
  local XComGameState_Unit SourceUnit;
  local Object EffectObj;
  local SmallUnitTactics_GameState_Effect_PrimedGrenade NewEffectState;
	Effect = GetOwningEffect();
  EffectObj = self;
	SourceUnit = XComGameState_Unit(
    `XCOMHISTORY.GetGameStateForObjectID(
      Effect.ApplyEffectParameters.SourceStateObjectRef.ObjectID
    )
  );

  `log("DON'T EXPLODE YET");
  if (OnExplosionTurn)
  {
    `log("SHOULD EXPLODE");
    DetonateGrenade(Effect, SourceUnit, GameState);
    RemoveEffect(Effect, GameState);
  }

  return ELR_NoInterrupt;
}


function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Effect Effect;

	local XComGameState_Ability ActivatedAbilityState;
  local XComGameState_Unit SourceUnit;
  local Object EffectObj;
  local SmallUnitTactics_GameState_Effect_PrimedGrenade NewEffectState;
	Effect = GetOwningEffect();
  EffectObj = self;
	SourceUnit = XComGameState_Unit(
    `XCOMHISTORY.GetGameStateForObjectID(
      Effect.ApplyEffectParameters.SourceStateObjectRef.ObjectID
    )
  );

	ActivatedAbilityState = XComGameState_Ability(EventData);
  if (
    (ActivatedAbilityState.OwnerStateObject.ObjectID == SourceUnit.ObjectID) &&
    (ActivatedAbilityState.GetMyTemplateName() == 'SUT_ThrowPrimedGrenade')
  )
  {
    `log("AbilityActivated Called and cleared effect + detonation");
    RemoveEffect(Effect, GameState);
  }
  else
  {
    `log("AbilityActivated Called but not from this unit");
  }

  return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitDied(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Effect Effect;
  local XComGameState_Unit SourceUnit;
  local Object EffectObj;
  local SmallUnitTactics_GameState_Effect_PrimedGrenade NewEffectState;

  `log("Nothing should happen. Explosion should occur.");

  return ELR_NoInterrupt;
}


function RemoveEffect(XComGameState_Effect Effect, XComGameState RespondingToGameState)
{
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
  local Object EffectObj;
	local XComGameStateHistory History;

  `log("Removing Effect and Unregistering");
	History = `XCOMHISTORY;
  EffectObj = self;
  `XEVENTMGR.UnRegisterFromEvent(EffectObj, 'OnAbilityActivated');
  `XEVENTMGR.UnRegisterFromEvent(EffectObj, 'PlayerTurnEnded');
  `XEVENTMGR.UnRegisterFromEvent(EffectObj, 'UnitDied');
  `XEVENTMGR.UnRegisterFromEvent(EffectObj, 'PlayerTurnBegun');


  EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(Effect);
  NewGameState = History.CreateNewGameState(true, EffectRemovedState);
  Effect.RemoveEffect(NewGameState, RespondingToGameState);

  if (NewGameState.GetNumGameStateObjects() > 0)
  {
    `TACTICALRULES.SubmitGameState(NewGameState);
  }
  else
  {
    `XCOMHISTORY.CleanupPendingGameState(NewGameState);
  }
}


function DetonateGrenade(XComGameState_Effect Effect, XComGameState_Unit SourceUnit, XComGameState RespondingToGameState)
{
	local XComGameState_Ability AbilityState;
	local AvailableAction Action, IterAction;
	local AvailableTarget Target;
  local GameRulesCache_Unit UnitCache;
  local XComGameState_Item SourceWeapon;
  local X2AbilityTemplate AbilityTemplate;
  local X2GrenadeTemplate GrenadeTemplate;
	local XComGameStateHistory History;
  local StateObjectReference TargetRef;
	local TTile                 AffectedTile;
  local vector                DetonationLocation;
  local array<vector>         TargetLocations;
	local XComGameState_Unit    UnitState;
  local vector ExplodeLocation;
  local int AbilityID;
  local array<vector> ExplodeLocations;

	History = `XCOMHISTORY;
  `TACTICALRULES.GetGameRulesCache_Unit(SourceUnit.GetReference(), UnitCache);
	AbilityID = SourceUnit.FindAbility(
    class'SmallUnitTactics_X2Ability_Grenades'.default.DetonateGrenadeAbilityName,
    SourceGrenade
  ).ObjectID;
  foreach UnitCache.AvailableActions(IterAction)
  {
    if (IterAction.AbilityObjectRef.ObjectID == AbilityID)
    {
      Action = IterAction;
    }
  }
	SourceWeapon = XComGameState_Item(
    `XCOMHISTORY.GetGameStateForObjectID(SourceGrenade.ObjectID)
  );
	if (Action.AbilityObjectRef.ObjectID != 0)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));

    DetonationLocation = `XWORLD.GetPositionFromTileCoordinates(SourceUnit.TileLocation);
		if (AbilityState != none)
		{
			/* Action.AvailableCode = 'AA_Success'; */
			AbilityState.GatherAdditionalAbilityTargetsForLocation(DetonationLocation, Target);
			Action.AvailableTargets.AddItem(Target);
      TargetLocations.AddItem(DetonationLocation);

      AbilityTemplate = AbilityState.GetMyTemplate();
      GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetMyTemplate());

			class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, TargetLocations);
		}
	}
}

