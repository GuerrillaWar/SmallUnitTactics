class UIDebugStateMachines extends UIScreen;

struct UnitTextMapping
{
	var name ActorName;
	var UIText Text;
};

var array<UnitTextMapping> Texts;

static function UIDebugStateMachines GetThisScreen()
{
	local UIDebugStateMachines Scr;
	foreach `TACTICALGRI.AllActors(class'UIDebugStateMachines', Scr)
	{
		return Scr;
	}
	Scr = `PRES.Spawn(class'UIDebugStateMachines', `PRES);
	Scr.InitScreen(XComPlayerController(`PRES.GetALocalPlayerController()), `PRES.Get2DMovie());
	`PRES.Get2DMovie().LoadScreen(Scr);
	return Scr;
}


event Tick(float fDeltaTime)
{
	local XGUnit Unit;
	if (!bIsVisible)
	{
		return;
	}
	foreach DynamicActors(class'XGUnit', Unit)
	{
		UpdateFlagForUnit(Unit);
	}
}

simulated function UpdateFlagForUnit(XGUnit Unit)
{
	local int i;
	local UnitTextMapping NewMapping;
	local vector2d TextLoc;
	i = Texts.Find('ActorName', Unit.Name);
	if (i == INDEX_NONE)
	{
		`log("Created flag for" @ Unit.Name);
		i = Texts.Length;
		NewMapping.ActorName = Unit.Name;
		NewMapping.Text = Spawn(class'UIText', self).InitText();
		Texts.AddItem(NewMapping);
	}
	if (!Unit.IsVisible())
	{
		Texts[i].Text.Hide();
	}
	else
	{
		if (class'UIUtilities'.static.IsOnscreen(Unit.GetPawn().GetHeadshotLocation(), TextLoc))
		{
			Texts[i].Text.Show();
			Texts[i].Text.SetNormalizedPosition(TextLoc);
			Texts[i].Text.SetText("<font color='#ffffff'>"$ Unit.Name @ Unit.IdleStateMachine.GetStateName() $ "</font>");
			//Texts[i].Text.SetText(Unit.Name @ Unit.IdleStateMachine.GetStateName());
		}
		else
		{
			Texts[i].Text.Hide();
		}		
	}
}


defaultproperties
{
	bIsVisible=false
	TickGroup=TG_PostAsyncWork	
}
