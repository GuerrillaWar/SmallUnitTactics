class SmallUnitTactics_Effect_ConditionalGraze extends X2Effect_Persistent;

function bool UniqueToHitModifiers() { return true; }

function GetToHitModifiers(
  XComGameState_Effect EffectState,
  XComGameState_Unit Attacker,
  XComGameState_Unit Target,
  XComGameState_Ability AbilityState,
  class<X2AbilityToHitCalc> ToHitType,
  bool bMelee,
  bool bFlanking,
  bool bIndirectFire,
  out array<ShotModifierInfo> ShotModifiers
)
{
	local ShotModifierInfo ShotMod;
  local SmallUnitTacticsGrazeProfile GrazeProfile;
	local XComGameState_Item SourceItemState, UsedItemState;
	local XComGameState_Ability SourceAbility;
	local name WeaponName, AbilityName;
	local GameRulesCache_VisibilityInfo VisInfo;
  local int GrazeModifier;

	SourceAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	SourceItemState = SourceAbility.GetSourceWeapon();
  UsedItemState = AbilityState.GetSourceWeapon();

  if (SourceItemState.ObjectID == UsedItemState.ObjectID)
  {
    WeaponName = SourceItemState.GetMyTemplateName();
    AbilityName = AbilityState.GetMyTemplateName();

    `TACTICALRULES.VisibilityMgr.GetVisibilityInfo(
      Attacker.ObjectID, Target.ObjectID, VisInfo
    );
    GrazeProfile = class'SmallUnitTactics_WeaponManager'.static.GetGrazeProfile(
      WeaponName, AbilityName
    );

    if (Target.CanTakeCover())
    {
      switch (VisInfo.TargetCover)
      {
        case CT_MidLevel:
        GrazeModifier = GrazeProfile.Low;
        break;

        case CT_Standing:
        GrazeModifier = GrazeProfile.High;
        break;

        default:
        GrazeModifier = GrazeProfile.Flanked;
        break;
      }
    }
    else
    {
      GrazeModifier = GrazeProfile.Flanked;
    }

    ShotMod.ModType = eHit_Graze;
    ShotMod.Value = GrazeModifier;
    ShotMod.Reason = FriendlyName;

    ShotModifiers.AddItem(ShotMod);
  }
}

DefaultProperties
{
	EffectName="CoverGraze"
	bUseSourcePlayerState=true
}
