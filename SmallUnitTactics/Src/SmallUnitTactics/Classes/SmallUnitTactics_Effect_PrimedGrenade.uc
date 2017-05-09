class SmallUnitTactics_Effect_PrimedGrenade extends X2Effect_ModifyStats config(SmallUnitTactics);

var bool Launched;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local SmallUnitTactics_GameState_Effect_PrimedGrenade GrenadeEffectState;
	local X2EventManager EventMgr;
	local Object ListenerObj;
  local XComGameState_Ability Ability;
  local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local StatChange Change;

  History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(NewEffectState.ApplyEffectParameters.PlayerStateObjectRef.ObjectID));

	Change.StatType = eStat_Mobility;
	Change.StatAmount = -100;
	NewEffectState.StatChanges.AddItem(Change);

	if (GetEffectComponent(NewEffectState) == none)
	{
		//create component and attach it to GameState_Effect, adding the new state object to the NewGameState container
		GrenadeEffectState = SmallUnitTactics_GameState_Effect_PrimedGrenade(
      NewGameState.CreateStateObject(class'SmallUnitTactics_GameState_Effect_PrimedGrenade')
    );
    Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(
      ApplyEffectParameters.AbilityStateObjectRef.ObjectID
    ));
    GrenadeEffectState.SourceGrenade = Ability.SourceWeapon;
		NewEffectState.AddComponentObject(GrenadeEffectState);
		NewGameState.AddStateObject(GrenadeEffectState);
	}

	//add listener to new component effect -- do it here because the RegisterForEvents call happens before OnEffectAdded, so component doesn't yet exist
	ListenerObj = GrenadeEffectState;
	if (ListenerObj == none)
	{
		`Redscreen("PrimedGrenade: Failed to find GrenadeComponent Component when registering listener");
		return;
	}

  EventMgr.RegisterForEvent(ListenerObj, 'PlayerTurnBegun', GrenadeEffectState.OnTurnBegun, ELD_OnStateSubmitted, , PlayerState);
  EventMgr.RegisterForEvent(ListenerObj, 'PlayerTurnEnded', GrenadeEffectState.OnTurnEnded, ELD_OnStateSubmitted, , PlayerState);

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

static function SmallUnitTactics_GameState_Effect_PrimedGrenade GetEffectComponent(XComGameState_Effect Effect)
{
	if (Effect != none) 
		return SmallUnitTactics_GameState_Effect_PrimedGrenade(
      Effect.FindComponentObject(class'SmallUnitTactics_GameState_Effect_PrimedGrenade')
    );
	return none;
}


simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack)
{
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
}

DefaultProperties
{
	EffectName="PrimedGrenade"
	DuplicateResponse = eDupe_Allow;
	bCanBeRedirected = false;
}
