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
  `XEVENTMGR.UnRegisterFromEvent(EffectObj, EventID);
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
    `XEVENTMGR.UnRegisterFromEvent(EffectObj, EventID);
  }

  return ELR_NoInterrupt;
}


function DetonateGrenade(XComGameState_Effect Effect, XComGameState_Unit SourceUnit, XComGameState RespondingToGameState)
{
	local XComGameState_Ability AbilityState;
	local AvailableAction Action;
	local AvailableTarget Target;
  local XComGameState_Item SourceWeapon;
  local X2AbilityTemplate AbilityTemplate;
  local X2GrenadeTemplate GrenadeTemplate;
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
  local StateObjectReference TargetRef;
	local TTile                 AffectedTile;
  local vector                DetonationLocation;
  local array<vector>         TargetLocations;
	local XComGameState_Unit    UnitState;
  local vector ExplodeLocation;
  local array<vector> ExplodeLocations;

	History = `XCOMHISTORY;
	Action.AbilityObjectRef = SourceUnit.FindAbility(
    class'SmallUnitTactics_X2Ability_Grenades'.default.DetonateGrenadeAbilityName,
    SourceGrenade
  );
	SourceWeapon = XComGameState_Item(
    `XCOMHISTORY.GetGameStateForObjectID(SourceGrenade.ObjectID)
  );
	if (Action.AbilityObjectRef.ObjectID != 0)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));

    DetonationLocation = `XWORLD.GetPositionFromTileCoordinates(SourceUnit.TileLocation);
		if (AbilityState != none)
		{
			Action.AvailableCode = 'AA_Success';
			AbilityState.GatherAdditionalAbilityTargetsForLocation(DetonationLocation, Target);
			Action.AvailableTargets.AddItem(Target);
      TargetLocations.AddItem(DetonationLocation);

      AbilityTemplate = AbilityState.GetMyTemplate();
      GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetMyTemplate());

      `log("Detonating" @ SourceWeapon.GetMyTemplateName());
      `log("UseThrowEffects:" @ AbilityTemplate.bUseThrownGrenadeEffects);
      `log("UseLaunchEffects:" @ AbilityTemplate.bUseLaunchedGrenadeEffects);
      `log("Detonation locations:");
      foreach TargetLocations(ExplodeLocation)
      {
        `log("-" @ ExplodeLocation);
      }
      `log("END Detonation locations");
      `log("Targets:");
      foreach Target.AdditionalTargets(TargetRef)
      {
        `log("-" @ TargetRef.ObjectID);
      }
      `log("END Targets");

      `log("Triggering ability" @ class'SmallUnitTactics_X2Ability_Grenades'.default.DetonateGrenadeAbilityName);
			/* if (class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, TargetLocations)) */
			if (class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, TargetLocations))
			{
        `log("Triggered ability" @ class'SmallUnitTactics_X2Ability_Grenades'.default.DetonateGrenadeAbilityName);
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

