class SmallUnitTactics_X2Ability_ShotTypes extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
  local array<X2DataTemplate> Templates;

  Templates.AddItem(AddShotType('SUT_AimedShot', 2, eSUTFireMode_Aimed));
  Templates.AddItem(AddShotType('SUT_SnapShot', 1, eSUTFireMode_Snap));
  Templates.AddItem(AddShotType('SUT_BurstShot', 1, eSUTFireMode_Burst));
  Templates.AddItem(AddShotType('SUT_AutoShot', 2, eSUTFireMode_Automatic));

  return Templates;
}

static function X2AbilityTemplate AddShotType(
  name AbilityName='AimedShot',
  int AbilityCost=1,
  eSUTFireMode FireMode=eSUTFireMode_Aimed
) {
  local X2AbilityTemplate                 Template;	
  local SmallUnitTactics_AbilityCost_BurstAmmoCost  AmmoCost;
  local X2AbilityCost_ActionPoints        ActionPointCost;
  local array<name>                       SkipExclusions;
  local X2Effect_Knockback				KnockbackEffect;
  local X2Condition_Visibility            VisibilityCondition;
  local SmallUnitTactics_X2AbilityMultiTarget_Burst BurstMultiTarget;
	local X2AbilityMultiTarget_BurstFire    BurstFireMultiTarget;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;

  // Macro to do localisation and stuffs
  `CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

  // Icon Properties
  Template.bDontDisplayInAbilitySummary = true;
  Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standard";
  Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_SHOT_PRIORITY;
  Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
  Template.DisplayTargetHitChance = true;
  Template.AbilitySourceName = 'eAbilitySource_Standard';    // color of the icon
  // Activated by a button press; additionally, tells the AI this is an activatable
  Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

  SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
  SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
  Template.AddShooterEffectExclusions(SkipExclusions);

  // Targeting Details
  // Can only shoot visible enemies
  VisibilityCondition = new class'X2Condition_Visibility';
  VisibilityCondition.bRequireGameplayVisible = true;
  VisibilityCondition.bAllowSquadsight = true;
  Template.AbilityTargetConditions.AddItem(VisibilityCondition);
  // Can't target dead; Can't target friendlies
  Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
  // Can't shoot while dead
  Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
  // Only at single targets that are in range.
  Template.AbilityTargetStyle = default.SimpleSingleTarget;

  // Action Point
  ActionPointCost = new class'X2AbilityCost_ActionPoints';
  ActionPointCost.iNumPoints = AbilityCost;
  ActionPointCost.bConsumeAllPoints = false;
  Template.AbilityCosts.AddItem(ActionPointCost);	

  // Ammo
  AmmoCost = new class'SmallUnitTactics_AbilityCost_BurstAmmoCost';	
  AmmoCost.FireMode = FireMode;
  Template.AbilityCosts.AddItem(AmmoCost);
  Template.bAllowAmmoEffects = true;
  Template.bAllowBonusWeaponEffects = true;

  // Weapon Upgrade Compatibility
  Template.bAllowFreeFireWeaponUpgrade = true;                        // Flag that permits action to become 'free action' via 'Hair Trigger' or similar upgrade / effects

  //  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
  Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
  //  Various Soldier ability specific effects - effects check for the ability before applying	
  Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());

	// Damage Effect
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	Template.AddTargetEffect(WeaponDamageEffect);
	Template.AddMultiTargetEffect(WeaponDamageEffect);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;

  BurstMultiTarget = new class'SmallUnitTactics_X2AbilityMultiTarget_Burst';
  BurstMultiTarget.FireMode = FireMode;
  BurstMultiTarget.bAllowSameTarget = true;
  Template.AbilityMultiTargetStyle = BurstMultiTarget;
  // we will not use this soon, recursive ability calls ideal because
  // X2 doesn't really handle more than one projectile well in terms
  // of environ damage
  /* BurstFireMultiTarget = new class'X2AbilityMultiTarget_BurstFire'; */
  /* BurstFireMultiTarget.NumExtraShots = 4; */
  /* Template.AbilityMultiTargetStyle = BurstFireMultiTarget; */
    
  // Targeting Method
  Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
  Template.bUsesFiringCamera = true;
  Template.CinescriptCameraType = "StandardGunFiring";	

  Template.AssociatedPassives.AddItem('HoloTargeting');

  // MAKE IT LIVE!
  Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	
  Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

  Template.bDisplayInUITooltip = false;
  Template.bDisplayInUITacticalText = false;

  KnockbackEffect = new class'X2Effect_Knockback';
  KnockbackEffect.KnockbackDistance = 2;
  KnockbackEffect.bUseTargetLocation = true;
  Template.AddTargetEffect(KnockbackEffect);
  Template.DamagePreviewFn = FireDamagePreview;

  Template.PostActivationEvents.AddItem('StandardShotActivated');

  return Template;	
}


function bool FireDamagePreview(
  XComGameState_Ability AbilityState,
  StateObjectReference TargetRef,
  out WeaponDamageValue MinDamagePreview,
  out WeaponDamageValue MaxDamagePreview,
  out int AllowsShield
) {
  local XComGameState_Item WeaponState;
  local X2AbilityTemplate AbilityTemplate;
  local SmallUnitTacticsWeaponProfile WeaponProfile;
  local eSUTFireMode FireMode;
  local int ShotCount;

  WeaponState = XComGameState_Item(
    `XCOMHISTORY.GetGameStateForObjectID(AbilityState.SourceWeapon.ObjectID)
  );
  AbilityTemplate = AbilityState.GetMyTemplate();
  FireMode = SmallUnitTactics_AbilityCost_BurstAmmoCost(
    AbilityTemplate.AbilityCosts[0]
  ).FireMode;

  WeaponProfile = class'SmallUnitTactics_WeaponManager'.static.GetWeaponProfile(
    WeaponState.GetMyTemplateName()
  );
  ShotCount = class'SmallUnitTactics_WeaponManager'.static.GetShotCount(
    WeaponState.GetMyTemplateName(), FireMode
  );

  MinDamagePreview.Damage = WeaponProfile.BulletProfile.Damage - WeaponProfile.BulletProfile.Spread;
  MinDamagePreview.Pierce = WeaponProfile.BulletProfile.Pierce;
  MinDamagePreview.Shred = WeaponProfile.BulletProfile.Shred;
  MaxDamagePreview.Damage = ShotCount * (WeaponProfile.BulletProfile.Damage + WeaponProfile.BulletProfile.Spread);
  MaxDamagePreview.Pierce = ShotCount * (WeaponProfile.BulletProfile.Pierce);
  MaxDamagePreview.Shred = ShotCount * (WeaponProfile.BulletProfile.Shred);

	return true;
}
