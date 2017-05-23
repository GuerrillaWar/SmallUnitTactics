class SmallUnitTactics_UIScreenListener_ShotHUD extends UIScreenListener;

var UITacticalHUD TacHUD;
var SmallUnitTactics_UIGrazeDisplay GrazeDisplay;
var bool LastVisibility;
var int LastChance;

event OnInit(UIScreen Screen)
{
	local XComPresentationLayer Pres;

  TacHUD = UITacticalHUD(Screen);
	Pres = XComPresentationLayer(TacHUD.Movie.Pres);
  Pres.SubscribeToUIUpdate(UpdateGrazeDisplay);

  GrazeDisplay = TacHUD.Spawn(class'SmallUnitTactics_UIGrazeDisplay', TacHUD);
  GrazeDisplay.InitPanel('SUT_UIGrazeDisplay');
  GrazeDisplay.InitGrazeDisplay(TacHUD);
}

simulated function UpdateGrazeDisplay()
{
  local AvailableAction SelectedUIAction;
	local XComGameState_Ability SelectedAbilityState;
  local StateObjectReference Shooter, Target;
  local ShotBreakdown kBreakdown;
	local X2TargetingMethod TargetingMethod;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local AvailableTarget kTarget;
  local bool ShowGraze;
  local int GrazeChance, TargetIndex;

  SelectedUIAction = TacHUD.GetSelectedAction();

  if (SelectedUIAction.AvailableCode == 'AA_Success')
  {
    SelectedAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SelectedUIAction.AbilityObjectRef.ObjectID));
    SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();
		TargetingMethod = TacHUD.GetTargetingMethod();

		if( TargetingMethod != None )
		{
			TargetIndex = TargetingMethod.GetTargetIndex();
			if( SelectedUIAction.AvailableTargets.Length > 0 && TargetIndex < SelectedUIAction.AvailableTargets.Length )
				kTarget = SelectedUIAction.AvailableTargets[TargetIndex];
		}

    Shooter = SelectedAbilityState.OwnerStateObject;
    Target = kTarget.PrimaryTarget;
    SelectedAbilityState.LookupShotBreakdown(Shooter, Target, SelectedAbilityState.GetReference(), kBreakdown);

		if (SelectedAbilityTemplate.AbilityToHitCalc != none && SelectedAbilityState.iCooldown == 0)
    {
      ShowGraze = true;
      GrazeChance = kBreakdown.ResultTable[eHit_Graze];
    }
  }

  if (LastVisibility != ShowGraze) {
    if (ShowGraze)
    {
      GrazeDisplay.Show();
    }
    else
    {
      GrazeDisplay.Hide();
    }
  }

  if (GrazeChance != LastChance)
  {
    GrazeDisplay.UpdateChance(GrazeChance);
  }

  LastChance = GrazeChance;
  LastVisibility = ShowGraze;
}

event OnRemoved(UIScreen Screen)
{
	local XComPresentationLayer Pres;

	Pres = XComPresentationLayer(TacHUD.Movie.Pres);
  Pres.UnsubscribeToUIUpdate(UpdateGrazeDisplay);
  TacHUD = none;
  GrazeDisplay = none;
}

defaultproperties
{
    ScreenClass = class'UITacticalHUD'
}
