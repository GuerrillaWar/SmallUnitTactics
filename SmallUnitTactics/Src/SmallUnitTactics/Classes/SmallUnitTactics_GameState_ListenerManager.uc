class SmallUnitTactics_GameState_ListenerManager
extends XComGameState_BaseObject;

static function SmallUnitTactics_GameState_ListenerManager GetListenerManager(optional bool AllowNULL = false)
{
	return SmallUnitTactics_GameState_ListenerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'SmallUnitTactics_GameState_ListenerManager', AllowNULL));
}

static function CreateListenerManager(optional XComGameState StartState)
{
	local SmallUnitTactics_GameState_ListenerManager ListenerMgr;
	local XComGameState NewGameState;

	//first check that there isn't already a singleton instance of the listener manager
	if(GetListenerManager(true) != none)
		return;

	if(StartState != none)
	{
		ListenerMgr = SmallUnitTactics_GameState_ListenerManager(StartState.CreateStateObject(class'SmallUnitTactics_GameState_ListenerManager'));
		StartState.AddStateObject(ListenerMgr);
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Creating SmallUnitTactics Listener Manager Singleton");
		ListenerMgr = SmallUnitTactics_GameState_ListenerManager(NewGameState.CreateStateObject(class'SmallUnitTactics_GameState_ListenerManager'));
		NewGameState.AddStateObject(ListenerMgr);
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}

	ListenerMgr.InitListeners();
}

static function RefreshListeners()
{
	local SmallUnitTactics_GameState_ListenerManager ListenerMgr;

	ListenerMgr = GetListenerManager(true);
	if(ListenerMgr == none)
		CreateListenerManager();
	else
		ListenerMgr.InitListeners();
}


function InitListeners()
{
	local X2EventManager EventMgr;
	local Object ThisObj;

	ThisObj = self;
	EventMgr = `XEVENTMGR;
	EventMgr.UnregisterFromAllEvents(ThisObj); // clear all old listeners to clear out old stuff before re-registering

	//to hit
	EventMgr.RegisterForEvent(ThisObj, 'OnFinalizeHitChance', ToHitOverrideListener,,,,true);
}



function EventListenerReturn ToHitOverrideListener(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID)
{
	local XComLWTuple						OverrideToHit;
	local X2AbilityToHitCalc				ToHitCalc;
	local X2AbilityToHitCalc_StandardAim	StandardAim;
	/* local ToHitAdjustments					Adjustments; */
	/* local ShotModifierInfo					ModInfo; */

	OverrideToHit = XComLWTuple(EventData);
	if(OverrideToHit == none)
	{
		`REDSCREEN("ToHitOverride event triggered with invalid event data.");
		return ELR_NoInterrupt;
	}

	ToHitCalc = X2AbilityToHitCalc(EventSource);
	if(ToHitCalc == none)
	{
		`REDSCREEN("ToHitOverride event triggered with invalid source data.");
		return ELR_NoInterrupt;
	}

	StandardAim = X2AbilityToHitCalc_StandardAim(ToHitCalc);
	if(StandardAim == none)
	{
		//exit silently with no error, since we're just intercepting StandardAim
		return ELR_NoInterrupt;
	}

	if(OverrideToHit.Id != 'FinalizeHitChance')
		return ELR_NoInterrupt;

	return ELR_NoInterrupt;
}
