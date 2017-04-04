class SmallUnitTactics_AbilityCost_BurstAmmoCost extends X2AbilityCost_Ammo
dependson(SmallUnitTactics_WeaponManager);

var eSUTFireMode FireMode;

simulated function int CalcAmmoCost(XComGameState_Ability Ability, XComGameState_Item ItemState, XComGameState_BaseObject TargetState)
{
  local XComGameState_Item WeaponState;

  WeaponState = XComGameState_Item(
    `XCOMHISTORY.GetGameStateForObjectID(Ability.SourceWeapon.ObjectID)
  );

  return class'SmallUnitTactics_WeaponManager'.static.GetShotCount(
    WeaponState.GetMyTemplateName(), FireMode
  );
}

simulated function name CanAfford(XComGameState_Ability kAbility, XComGameState_Unit ActivatingUnit)
{
	local XComGameState_Item Weapon, SourceAmmo;
	local int Cost;
	Weapon = kAbility.GetSourceWeapon();
	Cost = CalcAmmoCost(kAbility, Weapon, ActivatingUnit);

	if (UseLoadedAmmo)
	{
		SourceAmmo = kAbility.GetSourceAmmo();
		if (SourceAmmo != None)
		{
			if (SourceAmmo.HasInfiniteAmmo() || SourceAmmo.Ammo >= Cost)
				return 'AA_Success';
		}
	}
	else
	{
		Weapon = kAbility.GetSourceWeapon();
		if (Weapon != none)
		{
			// If the weapon has infinite ammo, the weapon must still have an ammo value
			// of at least one. This could happen if the weapon becomes disabled.
			if ((Weapon.HasInfiniteAmmo() && (Weapon.Ammo > 0)) || Weapon.Ammo >= Cost)
				return 'AA_Success';
		}	
	}

	if (bReturnChargesError)
		return 'AA_CannotAfford_Charges';

	return 'AA_CannotAfford_AmmoCost';
}
