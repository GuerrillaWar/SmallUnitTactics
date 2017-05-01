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
  Templates.AddItem(AddFollowShot('SUT_BurstFollowShot', eSUTFireMode_Burst));
  Templates.AddItem(AddFollowShot('SUT_AutoFollowShot', eSUTFireMode_Automatic));
  Templates.AddItem(AddAnimationAbility());

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
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
  local X2Condition_Visibility            VisibilityCondition;
	local SmallUnitTactics_AbilityToHitCalc_StandardAim    ToHitCalc;

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
	Template.AddTargetEffect(default.WeaponUpgradeMissDamage);

	// Damage Effect
	/* WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage'; */
	/* Template.AddTargetEffect(WeaponDamageEffect); */

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

	ToHitCalc = new class'SmallUnitTactics_AbilityToHitCalc_StandardAim';
  ToHitCalc.FireMode = FireMode;
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;
  Template.bIsASuppressionEffect = true;

  // Targeting Method
  Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
  Template.bUsesFiringCamera = true;
  Template.CinescriptCameraType = "StandardGunFiring";	

  Template.AssociatedPassives.AddItem('HoloTargeting');

  // MAKE IT LIVE!
  Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  Template.BuildVisualizationFn = FirstShot_BuildVisualization;
  Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

  Template.bDisplayInUITooltip = false;
  Template.bDisplayInUITacticalText = false;

  KnockbackEffect = new class'X2Effect_Knockback';
  KnockbackEffect.KnockbackDistance = 2;
  KnockbackEffect.bUseTargetLocation = true;
  Template.AddTargetEffect(KnockbackEffect);
  Template.DamagePreviewFn = FireDamagePreview;

  Template.PostActivationEvents.AddItem('StandardShotActivated');

  if (FireMode == eSUTFireMode_Burst)
  {
    Template.PostActivationEvents.AddItem('SUT_BurstFollowShot');
  }
  else if (FireMode == eSUTFireMode_Automatic)
  {
    Template.PostActivationEvents.AddItem('SUT_AutoFollowShot');
  }
  else
  {
    Template.PostActivationEvents.AddItem('SUT_FinaliseAnimation');
  }

  return Template;	
}


simulated function FirstShot_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateContext Context;
	local XComGameStateContext_Ability TestAbilityContext;
	local int EventChainIndex, TrackIndex, ActionIndex;
	local XComGameStateHistory History;
	local X2Action_EnterCover EnterCoverAction;
	local X2Action_EndCinescriptCamera EndCinescriptCameraAction;
  local SmallUnitTactics_X2Action_ManualPermitNextVisualizationBlockToRun ManualRunAction;

	// Build the first shot of Rapid Fire's visualization
	TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);

	Context = VisualizeGameState.GetContext();
	AbilityContext = XComGameStateContext_Ability(Context);

  for( TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; ++TrackIndex )
  {
    if( OutVisualizationTracks[TrackIndex].StateObject_NewState.ObjectID == AbilityContext.InputContext.SourceObject.ObjectID)
    {
      // Found the Source track
      break;
    }
  }

  for( ActionIndex = OutVisualizationTracks[TrackIndex].TrackActions.Length - 1; ActionIndex >= 0; --ActionIndex )
  {
    EnterCoverAction = X2Action_EnterCover(OutVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
    EndCinescriptCameraAction = X2Action_EndCinescriptCamera(OutVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
    if (
      (EnterCoverAction != none) ||
      (EndCinescriptCameraAction != none)
    )
    {
      OutVisualizationTracks[TrackIndex].TrackActions.Remove(ActionIndex, 1);
    }
  }
  ManualRunAction = SmallUnitTactics_X2Action_ManualPermitNextVisualizationBlockToRun(
    class'SmallUnitTactics_X2Action_ManualPermitNextVisualizationBlockToRun'.static.CreateVisualizationAction(
      Context, OutVisualizationTracks[TrackIndex].TrackActor
    )
  );
  OutVisualizationTracks[TrackIndex].TrackActions.AddItem(ManualRunAction);
}



static function EventListenerReturn MultiShotListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext, HistoryAbilityContext;
  local XComGameState_Unit Shooter, Target;
  local XComGameState_Item Weapon;
	local XComGameState_Ability Ability, ShotAbility, HistoryAbility;
  local XComGameStateHistory History;
  local eSUTFireMode FireMode;
  local name FireTemplate, TemplateName;
  local int ShotMax, ShotsFired;

  `log("MULTI SHOT LISTENER");
  History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none)
	{
    Ability = XComGameState_Ability(
      `XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID)
    );
    Target = XComGameState_Unit(
      `XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID)
    );
    TemplateName = Ability.GetMyTemplateName();
    ShotsFired++;

    if (
      TemplateName != 'SUT_AutoFollowShot' &&
      TemplateName != 'SUT_BurstFollowShot'
    )
    {
      FireTemplate = Ability.GetMyTemplateName();
      Shooter = XComGameState_Unit(
        `XCOMHISTORY.GetGameStateForObjectID(Ability.OwnerStateObject.ObjectID)
      );
      Weapon = XComGameState_Item(
        `XCOMHISTORY.GetGameStateForObjectID(Ability.SourceWeapon.ObjectID)
      );
    }
    else
    {
      foreach History.IterateContextsByClassType(
        class'XComGameStateContext_Ability', HistoryAbilityContext
      )
      {
        HistoryAbility = XComGameState_Ability(
          `XCOMHISTORY.GetGameStateForObjectID(HistoryAbilityContext.InputContext.AbilityRef.ObjectID)
        );
        TemplateName = HistoryAbility.GetMyTemplateName();
        if (
          TemplateName == 'SUT_AutoFollowShot' ||
          TemplateName == 'SUT_BurstFollowShot'
        )
        {
          `log("ShotsFired Increment");
          ShotsFired++;
        }
        else if (
          TemplateName == 'SUT_AutoShot' || TemplateName == 'SUT_BurstShot' ||
          TemplateName == 'SUT_AimedShot' || TemplateName == 'SUT_SnapShot'
        )
        {
          FireTemplate = HistoryAbility.GetMyTemplateName();
          `log("Logged ability" @ FireTemplate);
          Shooter = XComGameState_Unit(
            `XCOMHISTORY.GetGameStateForObjectID(HistoryAbility.OwnerStateObject.ObjectID)
          );
          Weapon = XComGameState_Item(
            `XCOMHISTORY.GetGameStateForObjectID(HistoryAbility.SourceWeapon.ObjectID)
          );
          break;
        }
      }
    }

    switch (FireTemplate)
    {
      case 'SUT_AutoShot': FireMode = eSUTFireMode_Automatic; break;
      case 'SUT_BurstShot': FireMode = eSUTFireMode_Burst; break;
      case 'SUT_SnapShot': FireMode = eSUTFireMode_Snap; break;
      case 'SUT_AimedShot': FireMode = eSUTFireMode_Aimed; break;
    }

    ShotMax = class'SmallUnitTactics_WeaponManager'.static.GetShotCount(
      Weapon.GetMyTemplateName(), FireMode
    );

    `log("ShotsMax Found" @ ShotMax);
    if (ShotsFired >= ShotMax || Target.IsDead())
    {
      ShotAbility = XComGameState_Ability(
        `XCOMHISTORY.GetGameStateForObjectID(Shooter.FindAbility('SUT_FinaliseAnimation').ObjectID)
      );
      `log("Shooting done, getting ready to call:" @ ShotAbility.ObjectID);
    }
    else if (FireMode == eSUTFireMode_Burst)
    {
      `log("Fired another burst shot");
      ShotAbility = XComGameState_Ability(
        `XCOMHISTORY.GetGameStateForObjectID(Shooter.FindAbility('SUT_BurstFollowShot').ObjectID)
      );
    }
    else if (FireMode == eSUTFireMode_Automatic)
    {
      `log("Fired another auto shot");
      ShotAbility = XComGameState_Ability(
        `XCOMHISTORY.GetGameStateForObjectID(Shooter.FindAbility('SUT_AutoFollowShot').ObjectID)
      );
    }

    ShotAbility.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false);
	}
	return ELR_NoInterrupt;
}


static function X2AbilityTemplate AddFollowShot(
  name AbilityName,
  eSUTFireMode FireMode=eSUTFireMode_Aimed
)
{
  local X2AbilityTemplate                 Template;	
  local array<name>                       SkipExclusions;
  local X2Effect_Knockback				KnockbackEffect;
  local X2Condition_Visibility            VisibilityCondition;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
  local X2AbilityTrigger_EventListener  Trigger;
	local SmallUnitTactics_AbilityToHitCalc_StandardAim    ToHitCalc;

  // Macro to do localisation and stuffs
  `CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

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
  // Can't shoot while dead
  Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
  // Only at single targets that are in range.
  Template.AbilityTargetStyle = default.SimpleSingleTarget;

  Template.bAllowAmmoEffects = true;
  Template.bAllowBonusWeaponEffects = true;
  Template.bAllowFreeFireWeaponUpgrade = true;                        // Flag that permits action to become 'free action' via 'Hair Trigger' or similar upgrade / effects

  //  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
  // Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
  //  Various Soldier ability specific effects - effects check for the ability before applying
  Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.AddTargetEffect(default.WeaponUpgradeMissDamage);

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = AbilityName;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = MultiShotListener;
	Template.AbilityTriggers.AddItem(Trigger);

	ToHitCalc = new class'SmallUnitTactics_AbilityToHitCalc_StandardAim';
  ToHitCalc.FireMode = FireMode;
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;
  Template.bIsASuppressionEffect = true;

  /* Template.AssociatedPassives.AddItem('HoloTargeting'); */

  // MAKE IT LIVE!
  Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  Template.BuildVisualizationFn = FollowShot_BuildVisualization;
  Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

  Template.bDisplayInUITooltip = false;
  Template.bDisplayInUITacticalText = false;

  Template.bUsesFiringCamera = true;
  Template.CinescriptCameraType = "StandardGunFiring";	

  KnockbackEffect = new class'X2Effect_Knockback';
  KnockbackEffect.KnockbackDistance = 2;
  KnockbackEffect.bUseTargetLocation = true;
  Template.AddTargetEffect(KnockbackEffect);
  Template.DamagePreviewFn = FireDamagePreview;
  Template.PostActivationEvents.AddItem(AbilityName);

  return Template;	
}



simulated function FollowShot_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext Context;
	local XComGameStateContext_Ability AbilityContext;
	local int TrackIndex, ActionIndex;
	local X2Action_ExitCover ExitCoverAction;
	local X2Action_EnterCover EnterCoverAction;
	local X2Action_StartCinescriptCamera StartCinescriptCameraAction;
	local X2Action_EndCinescriptCamera EndCinescriptCameraAction;
  local SmallUnitTactics_X2Action_ManualPermitNextVisualizationBlockToRun ManualRunAction;

	// Build the first shot of Rapid Fire's visualization
	TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);

	Context = VisualizeGameState.GetContext();
	AbilityContext = XComGameStateContext_Ability(Context);

	for( TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; ++TrackIndex )
	{
		if( OutVisualizationTracks[TrackIndex].StateObject_NewState.ObjectID == AbilityContext.InputContext.SourceObject.ObjectID)
		{
			// Found the Source track
			break;
		}
	}

	for( ActionIndex = OutVisualizationTracks[TrackIndex].TrackActions.Length - 1; ActionIndex >= 0; --ActionIndex )
	{
		ExitCoverAction = X2Action_ExitCover(OutVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
		EnterCoverAction = X2Action_EnterCover(OutVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
		StartCinescriptCameraAction = X2Action_StartCinescriptCamera(OutVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
    EndCinescriptCameraAction = X2Action_EndCinescriptCamera(OutVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
		if (
      (ExitCoverAction != none) ||
      (StartCinescriptCameraAction != none) ||
      (EndCinescriptCameraAction != none) ||
      (EnterCoverAction != none)
    )
		{
			OutVisualizationTracks[TrackIndex].TrackActions.Remove(ActionIndex, 1);
		}
	}

  ManualRunAction = SmallUnitTactics_X2Action_ManualPermitNextVisualizationBlockToRun(
    class'SmallUnitTactics_X2Action_ManualPermitNextVisualizationBlockToRun'.static.CreateVisualizationAction(
      Context, OutVisualizationTracks[TrackIndex].TrackActor
    )
  );
  OutVisualizationTracks[TrackIndex].TrackActions.AddItem(ManualRunAction);
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
  local SmallUnitTactics_AbilityCost_BurstAmmoCost BurstAmmoCost;
  local X2AbilityCost AbilityCost;
  local eSUTFireMode FireMode;
  local int ShotCount;

  WeaponState = XComGameState_Item(
    `XCOMHISTORY.GetGameStateForObjectID(AbilityState.SourceWeapon.ObjectID)
  );
  AbilityTemplate = AbilityState.GetMyTemplate();
  foreach AbilityTemplate.AbilityCosts(AbilityCost)
  {
    BurstAmmoCost = SmallUnitTactics_AbilityCost_BurstAmmoCost(AbilityCost);
    if (BurstAmmoCost != none)
    {
      FireMode = BurstAmmoCost.FireMode;
    }
  }

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


static function EventListenerReturn SingleShotListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;
  local XComGameState_Unit Shooter;
	local XComGameState_Ability Ability, ShotAbility;
  local XComGameStateHistory History;

  History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none)
	{
    Ability = XComGameState_Ability(
      History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID)
    );
    Shooter = XComGameState_Unit(
      History.GetGameStateForObjectID(Ability.OwnerStateObject.ObjectID)
    );
    ShotAbility = XComGameState_Ability(
      History.GetGameStateForObjectID(Shooter.FindAbility('SUT_FinaliseAnimation').ObjectID)
    );

    ShotAbility.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false);
	}
	return ELR_NoInterrupt;
}


static function X2AbilityTemplate AddAnimationAbility()
{
  local X2AbilityTemplate                 Template;	
  local X2Condition_Visibility            VisibilityCondition;
  local X2AbilityTrigger_EventListener  Trigger;

  // Macro to do localisation and stuffs
  `CREATE_X2ABILITY_TEMPLATE(Template, 'SUT_FinaliseAnimation');

  // Icon Properties
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_supression";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

  /* SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName); */
  /* SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName); */
  /* Template.AddShooterEffectExclusions(SkipExclusions); */

  // Targeting Details
  // Can only shoot visible enemies
  VisibilityCondition = new class'X2Condition_Visibility';
  VisibilityCondition.bRequireGameplayVisible = true;
  VisibilityCondition.bAllowSquadsight = true;
  Template.AbilityTargetConditions.AddItem(VisibilityCondition);
  // Can't shoot while dead
  Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
  // Only at single targets that are in range.
  Template.AbilityTargetStyle = default.SimpleSingleTarget;

  Template.bAllowAmmoEffects = true;
  Template.bAllowBonusWeaponEffects = true;
  Template.bAllowFreeFireWeaponUpgrade = true;                        // Flag that permits action to become 'free action' via 'Hair Trigger' or similar upgrade / effects

  //  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
  // Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
  //  Various Soldier ability specific effects - effects check for the ability before applying	
  // Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'SUT_FinaliseAnimation';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = SingleShotListener;
	Template.AbilityTriggers.AddItem(Trigger);

	// Damage Effect

  // MAKE IT LIVE!
  Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  Template.BuildVisualizationFn = Finalize_BuildVisualization;
  Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

  Template.bDisplayInUITooltip = false;
  Template.bDisplayInUITacticalText = false;

  Template.bUsesFiringCamera = true;
  Template.CinescriptCameraType = "StandardGunFiring";	

  return Template;	
}


simulated function Finalize_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory      History;
	local XComGameStateContext_Ability  Context;
  local XComGameState             ShotGameState;

	local AbilityInputContext           AbilityContext;
	local Array<XComGameStateContext_Ability>  ShotContexts, HitContexts, MissContexts;
	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;
	local VisualizationTrack        SourceTrack, TargetTrack;
	local X2Action_Fire                 FireAction;

	local X2AmmoTemplate                AmmoTemplate;
	local X2WeaponTemplate              WeaponTemplate;

  local name TemplateName;
	local StateObjectReference          ShootingUnitRef;	
	local Actor                     TargetVisualizer, ShooterVisualizer;
	local X2VisualizerInterface     TargetVisualizerInterface, ShooterVisualizerInterface;

	local XComGameStateContext_Ability HistoryAbilityContext, ShotContext;
  local XComGameState_Item SourceWeapon;
  local XComGameState_Unit TargetStartState, TargetEndState;
	local XComGameState_Ability ShotAbility, HistoryAbility, AbilityState;
	local X2AbilityTemplate ShotAbilityTemplate;
  local bool AnyHits;
	local XComGameState_BaseObject      TargetStateObject;
	local array<X2Effect>               MultiTargetEffects;

	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local XComGameState_WorldEffectTileData WorldDataUpdate;

	/* local X2Action_PlaySoundAndFlyOver SoundAndFlyover; */
  local X2Action_ApplyWeaponDamageToUnit ApplyWeaponDamageToUnit;
	local name         ApplyResult;

	local X2Action_StartCinescriptCamera CinescriptStartAction;
	local X2Action_EndCinescriptCamera   CinescriptEndAction;
	local X2Camera_Cinescript            CinescriptCamera;
  local int EffectIndex, FirstHistoryIndex;

	History = `XCOMHISTORY;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityContext = Context.InputContext;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.AbilityRef.ObjectID));

	ShootingUnitRef = Context.InputContext.SourceObject;

	ShooterVisualizer = History.GetVisualizer(ShootingUnitRef.ObjectID);
	ShooterVisualizerInterface = X2VisualizerInterface(ShooterVisualizer);

	SourceTrack = EmptyTrack;
	SourceTrack.StateObject_OldState = History.GetGameStateForObjectID(ShootingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	SourceTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(ShootingUnitRef.ObjectID);
	if (SourceTrack.StateObject_NewState == none)
		SourceTrack.StateObject_NewState = SourceTrack.StateObject_OldState;
	SourceTrack.TrackActor = ShooterVisualizer;

	SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.ItemObject.ObjectID));
	if (SourceWeapon != None)
	{
		WeaponTemplate = X2WeaponTemplate(SourceWeapon.GetMyTemplate());
		AmmoTemplate = X2AmmoTemplate(SourceWeapon.GetLoadedAmmoTemplate(AbilityState));
	}

	class'X2Action_EnterCover'.static.AddToVisualizationTrack(SourceTrack, Context);
	// Add an action to pop the last CinescriptCamera off the camera stack.
	CinescriptEndAction = X2Action_EndCinescriptCamera( class'X2Action_EndCinescriptCamera'.static.AddToVisualizationTrack( SourceTrack, Context ) );
	CinescriptEndAction.CinescriptCamera = CinescriptCamera;

	OutVisualizationTracks.AddItem(SourceTrack);
}
