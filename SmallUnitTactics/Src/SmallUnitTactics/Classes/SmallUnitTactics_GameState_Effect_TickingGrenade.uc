class SmallUnitTactics_GameState_Effect_TickingGrenade extends XComGameState_BaseObject;

var bool Launched;
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
	Effect = GetOwningEffect();
  EffectObj = self;

	SourceUnit = XComGameState_Unit(
    `XCOMHISTORY.GetGameStateForObjectID(
      Effect.ApplyEffectParameters.SourceStateObjectRef.ObjectID
    )
  );

  `XEVENTMGR.UnRegisterFromEvent(EffectObj, EventID);
  DetonateGrenade(Effect, SourceUnit, GameState);
  return ELR_NoInterrupt;
}


function DetonateGrenade(XComGameState_Effect Effect, XComGameState_Unit SourceUnit, XComGameState RespondingToGameState)
{
	local XComGameState_Ability AbilityState;
	local AvailableAction Action;
	local AvailableTarget Target;
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local TTile                 AffectedTile;
	local XComGameState_Unit    UnitState;
  local vector ExplodeLocation;
  local array<vector> ExplodeLocations;

	History = `XCOMHISTORY;
	Action.AbilityObjectRef = SourceUnit.FindAbility(
    Launched
      ? class'SmallUnitTactics_X2Ability_Grenades'.default.DetonateLaunchedGrenadeAbilityName
      : class'SmallUnitTactics_X2Ability_Grenades'.default.DetonateGrenadeAbilityName,
    SourceGrenade
  );
	if (Action.AbilityObjectRef.ObjectID != 0)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		if (AbilityState != none)
		{
			Action.AvailableCode = 'AA_Success';
			AbilityState.GatherAdditionalAbilityTargetsForLocation(Effect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0], Target);
      ExplodeLocations = Effect.ApplyEffectParameters.AbilityInputContext.TargetLocations;
			Action.AvailableTargets.AddItem(Target);

			if (class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, Effect.ApplyEffectParameters.AbilityInputContext.TargetLocations))
			{
				EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(Effect);
				NewGameState = History.CreateNewGameState(true, EffectRemovedState);
				Effect.RemoveEffect(NewGameState, RespondingToGameState);

        if (NewGameState.GetNumGameStateObjects() > 0)
        {
          `TACTICALRULES.SubmitGameState(NewGameState);

          //  effects may have changed action availability - if a unit died, took damage, etc.
        }
        else
        {
          `XCOMHISTORY.CleanupPendingGameState(NewGameState);
        }
			}
		}
	}
}

