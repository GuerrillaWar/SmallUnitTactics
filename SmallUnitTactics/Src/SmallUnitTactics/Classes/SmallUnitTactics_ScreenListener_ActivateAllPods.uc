class SmallUnitTactics_ScreenListener_ActivateAllPods extends UIScreenListener config (ActivateAllPods);

event OnInit(UIScreen screen)
{
    `XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState);
}

event OnRemoved(UIScreen screen)
{
    `XCOMHISTORY.UnRegisterOnNewGameStateDelegate(OnNewGameState);
}

private function OnNewGameState(XComGameState newGameState)
{
    local XComGameStateContext context;
    context = newGameState.GetContext();

    if(context.IsA('XComGameStateContext_ChangeContainer'))
    {
	    //`Log("GameState ChangeInfo"$XComGameStateContext_ChangeContainer(context).ChangeInfo);
        if(XComGameStateContext_ChangeContainer(context).ChangeInfo == "SetupUnitActionsForPlayerTurnBegin")
        {
		//`Log("REGISTERED our event");
            AlertIfPlayerRevealed();
        }
    }
}

defaultProperties
{
    ScreenClass = UITacticalHUD
}


function AlertIfPlayerRevealed() {
    local XComGameStateHistory History;
	local XComGameState_Unit UnitState;


    History = `XCOMHISTORY;
    foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
    {
        if (!UnitState.ControllingPlayerIsAI()  
            && !UnitState.bRemovedFromPlay && UnitState.IsAlive() && !UnitState.IsConcealed())
        {
		        AlertAllUnits(UnitState);
				break;
			
        }
    }
}		

function AlertAllUnits(XComGameState_Unit Unit)
{
	local XComGameStateHistory History;
	local XComGameState_AIGroup AIGroupState;	

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_AIGroup', AIGroupState)
	{
		AIGroupState.ApplyAlertAbilityToGroup(eAC_TakingFire);
		AIGroupState.InitiateReflexMoveActivate(Unit, eAC_SeesSpottedUnit);
	}
}


