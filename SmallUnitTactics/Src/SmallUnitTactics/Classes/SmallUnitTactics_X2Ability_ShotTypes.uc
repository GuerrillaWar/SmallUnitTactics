class SmallUnitTactics_X2Ability_ShotTypes extends X2Ability;



var localized string SuppressionTargetEffectName;
var localized string SuppressionTargetEffectDesc;

static function array<X2DataTemplate> CreateTemplates()
{
  local array<X2DataTemplate> Templates;

  Templates.AddItem(AddShotType('SUT_AimedShot', 2, eSUTFireMode_Aimed));
  Templates.AddItem(AddShotType('SUT_SnapShot', 1, eSUTFireMode_Snap));
  Templates.AddItem(AddShotType('SUT_BurstShot', 1, eSUTFireMode_Burst));
  Templates.AddItem(AddShotType('SUT_AutoShot', 2, eSUTFireMode_Automatic));
  Templates.AddItem(AmbientSuppressionCancel());

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
  local SmallUnitTactics_Effect_AmbientSuppression SuppressionEffect;
  local X2Condition_Visibility            VisibilityCondition;
  local SmallUnitTactics_X2AbilityMultiTarget_Burst BurstMultiTarget;
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

  SuppressionEffect = new class'SmallUnitTactics_Effect_AmbientSuppression';
  SuppressionEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
  SuppressionEffect.bRemoveWhenTargetDies = true;
  SuppressionEffect.FireMode = FireMode;
  SuppressionEffect.bApplyOnMiss = true;
  SuppressionEffect.bApplyOnHit = true;
  SuppressionEffect.bRemoveWhenSourceDamaged = false;
  SuppressionEffect.bBringRemoveVisualizationForward = true;
  SuppressionEffect.SetDisplayInfo(ePerkBuff_Penalty, default.SuppressionTargetEffectName, default.SuppressionTargetEffectDesc, Template.IconImage);
  /* SuppressionEffect.SetSourceDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, default.SuppressionSourceEffectDesc, Template.IconImage); */
  Template.AddTargetEffect(SuppressionEffect);

  if (FireMode == eSUTFireMode_Burst || FireMode == eSUTFireMode_Automatic)
  {
    Template.AddMultiTargetEffect(WeaponDamageEffect);
  }

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;
  Template.bIsASuppressionEffect = true;

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



static function X2AbilityTemplate AmbientSuppressionCancel() {
  local X2AbilityTemplate                 Template;	
  local array<name>                       SkipExclusions;
  local X2Condition_Visibility            VisibilityCondition;

	local X2AbilityTrigger_Event	        Trigger;

	local X2Condition_UnitEffectsWithAbilitySource TargetEffectCondition;
	local X2Effect_RemoveEffects            RemoveSuppression;

  // Macro to do localisation and stuffs
  `CREATE_X2ABILITY_TEMPLATE(Template, 'SUT_AmbientSuppressionCancel');

  // Icon Properties
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_supression";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

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


	//Trigger on movement - interrupt the move
	Trigger = new class'X2AbilityTrigger_Event';
	Trigger.EventObserverClass = class'X2TacticalGameRuleset_MovementObserver';
	Trigger.MethodName = 'InterruptGameState';
	Template.AbilityTriggers.AddItem(Trigger);

	TargetEffectCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	TargetEffectCondition.AddRequireEffect(class'SmallUnitTactics_Effect_AmbientSuppression'.default.EffectName, 'AA_UnitIsNotSuppressed');
	Template.AbilityTargetConditions.AddItem(TargetEffectCondition);

	RemoveSuppression = new class'X2Effect_RemoveEffects';
	RemoveSuppression.EffectNamesToRemove.AddItem(class'SmallUnitTactics_Effect_AmbientSuppression'.default.EffectName);
	RemoveSuppression.bCheckSource = true;
	RemoveSuppression.SetupEffectOnShotContextResult(true, true);
	Template.AddShooterEffect(RemoveSuppression);

  // MAKE IT LIVE!
  Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  Template.BuildVisualizationFn = NoOpVisualisation;
  Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

  Template.bDisplayInUITooltip = false;
  Template.bDisplayInUITacticalText = false;

  return Template;	
}

simulated function NoOpVisualisation(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
}
