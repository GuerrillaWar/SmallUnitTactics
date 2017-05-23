class SmallUnitTactics_Effect_AmbientSuppression extends X2Effect_Suppression;

var eSUTFireMode FireMode;

function bool UniqueToHitModifiers() { return false; } // stack suppression

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;
	local XComGameState_Ability SourceAbility;

	SourceAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

  ShotMod.ModType = eHit_Success;
  ShotMod.Value = GetAimModifierFromAbility(SourceAbility);
  ShotMod.Reason = FriendlyName;

  ShotModifiers.AddItem(ShotMod);
}

function int GetAimModifierFromAbility(XComGameState_Ability SourceAbility)
{
	local XComGameState_Item ItemState;
	local name WeaponName;

	ItemState = SourceAbility.GetSourceWeapon();
	WeaponName = ItemState.GetMyTemplateName();
	
  return class'SmallUnitTactics_WeaponManager'.static.GetSuppressionPenalty(
    WeaponName, FireMode
  );
}


simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit SourceUnit;
	local XComGameStateContext_Ability AbilityContext;

	// override X2Effect_Sppression code, but not X2Effect_Persistent one
	super(X2Effect_Persistent).OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	SourceUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	SourceUnit.m_SuppressionAbilityContext = AbilityContext;
	NewGameState.AddStateObject(SourceUnit);
}


DefaultProperties
{
	EffectName="AmbientSuppression"
	bUseSourcePlayerState=true
	CleansedVisualizationFn=CleansedSuppressionVisualization
}
