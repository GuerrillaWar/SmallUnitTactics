class SmallUnitTactics_X2AbilityMultiTarget_Burst extends X2AbilityMultiTargetStyle;

var bool AutomaticFire;


simulated function GetMultiTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets)
{ 
  local XComGameState_Item WeaponState;
  local StateObjectReference AdditionalTarget;
  local SmallUnitTacticsWeaponProfile WeaponProfile;
  local SmallUnitTacticsShotProfile ShotProfile;
  local int ix;

  WeaponState = XComGameState_Item(
    `XCOMHISTORY.GetGameStateForObjectID(Ability.SourceWeapon.ObjectID)
  );

  `log("WeaponShotProfile==" @ WeaponState.GetMyTemplateName());
  WeaponProfile = class'SmallUnitTactics_WeaponManager'.static.GetWeaponProfile(
    WeaponState.GetMyTemplateName()
  );

  if (AutomaticFire)
  {
    ShotProfile = WeaponProfile.Automatic;
  }
  else
  {
    ShotProfile = WeaponProfile.Burst;
  }

  `log("ShotProfileCount==" @ ShotProfile.ShotCount);

  
  for (ix = 0; ix < Targets.Length; ix++)
  {
    while (Targets[ix].AdditionalTargets.Length < ShotProfile.ShotCount - 1)
    {
      `log("Adding Target");
      Targets[ix].AdditionalTargets.AddItem(Targets[ix].PrimaryTarget);
    }
  }
}


DefaultProperties
{
  bAllowSameTarget=true
}
