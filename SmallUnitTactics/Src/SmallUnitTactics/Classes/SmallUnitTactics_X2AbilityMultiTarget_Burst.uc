class SmallUnitTactics_X2AbilityMultiTarget_Burst extends X2AbilityMultiTargetStyle
dependson(SmallUnitTactics_WeaponManager);

var eSUTFireMode FireMode;

simulated function GetMultiTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets)
{ 
  local XComGameState_Item WeaponState;
  local int ix, ShotCount;

  WeaponState = XComGameState_Item(
    `XCOMHISTORY.GetGameStateForObjectID(Ability.SourceWeapon.ObjectID)
  );

  ShotCount = class'SmallUnitTactics_WeaponManager'.static.GetShotCount(
    WeaponState.GetMyTemplateName(), FireMode
  );

  for (ix = 0; ix < Targets.Length; ix++)
  {
    while (Targets[ix].AdditionalTargets.Length < ShotCount - 1)
    {
      Targets[ix].AdditionalTargets.AddItem(Targets[ix].PrimaryTarget);
    }
  }
}


DefaultProperties
{
  bAllowSameTarget=true
}
