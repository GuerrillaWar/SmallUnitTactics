class SmallUnitTactics_X2Ability_ShotTypes extends X2Ability;

var localized string SuppressionTargetEffectName;
var localized string SuppressionTargetEffectDesc;

static function array<X2DataTemplate> CreateTemplates()
{
  local array<X2DataTemplate> Templates;

  // Aimed and Snap shot are implemented exactly like burst and auto
  // the finalize is normally triggered by follow ups determining that they shouldn't trigger
  // this leaves us with two choices -- trigger the finalize in the first step (currently done)
  // or add follow ups for every ability, that don't ever trigger
  // this makes two more abilities, so that's not ideal
  AddShotPair(Templates, 'SUT_AimedShot', '', 2, eSUTFireMode_Aimed);
  AddShotPair(Templates, 'SUT_SnapShot', '', 1, eSUTFireMode_Snap);
  AddShotPair(Templates, 'SUT_BurstShot', 'SUT_BurstFollowShot', 1, eSUTFireMode_Burst);
  AddShotPair(Templates, 'SUT_AutoShot', 'SUT_AutoFollowShot', 2, eSUTFireMode_Automatic);

  Templates.AddItem(AmbientSuppressionCancel());
  Templates.AddItem(AddAnimationAbility());

  return Templates;
}

// we use a wrapper function instead of checking FireMode in each individual function
static function AddShotPair(out array<X2DataTemplate> Templates, name TriggerAbilityName, name FollowUpAbilityName, int AbilityCost, eSUTFireMode FireMode)
{
  local X2AbilityTemplate Template;
  class'SmallUnitTactics_AbilityManager'.static.RegisterAbilityPair(
    TriggerAbilityName, FollowUpAbilityName, FireMode
  );

  Template = AddShotType(TriggerAbilityName, AbilityCost, FireMode);
  if (FollowUpAbilityName != '')
  {
	Template.PostActivationEvents.AddItem(FollowUpAbilityName);
  }
  else
  {
    Template.PostActivationEvents.AddItem('SUT_FinaliseAnimation');
  }
  Templates.AddItem(Template);

  if (FollowUpAbilityName != '')
  {
	Template = AddFollowShot(FollowUpAbilityName, FireMode);
	Templates.AddItem(Template);
  }
}

static function X2AbilityTemplate AddShotType(
  name AbilityName,
  int AbilityCost,
  eSUTFireMode FireMode
)
{
  local X2AbilityTemplate                 Template;	
  local SmallUnitTactics_AbilityCost_BurstAmmoCost  AmmoCost;
  local X2AbilityCost_ActionPoints        ActionPointCost;
  local array<name>                       SkipExclusions;
  local X2Effect_Knockback				KnockbackEffect;
  local SmallUnitTactics_Effect_AmbientSuppression SuppressionEffect;
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
  // this was wrong -- only used for visualization
  // Template.bIsASuppressionEffect = true;

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

  return Template;	
}


simulated function FirstShot_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateContext Context;
	local int TrackIndex, ActionIndex;
	local X2Action_EnterCover EnterCoverAction;
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
    if (EnterCoverAction != none)
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
  local XComGameStateContext_Ability AbilityContext;
  local int iMaxShots, iShotIndex, iTakenShots, iDummyTotalShots;
  local AbilityRelation Relation;
  local XComGameStateHistory History;
  local XComGameState_Ability ShotAbility;
  local XComGameState_Unit Shooter;

  AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

  if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
  {
    return ELR_NoInterrupt;
  }

  if (!class'SmallUnitTactics_AbilityManager'.static.GetEventChainInfo(AbilityContext, iShotIndex, iMaxShots, iDummyTotalShots, Relation))
  {
    // failsafe if the ability is not in a follow-up chain. shouldn't happen, but you never know...
    return ELR_NoInterrupt;
  }

  History = `XCOMHISTORY;
  Shooter = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

  iTakenShots = iShotIndex + 1;
  if (iTakenShots < iMaxShots)
  {
    ShotAbility = XComGameState_Ability(
        History.GetGameStateForObjectID(Shooter.FindAbility(Relation.FollowUpAbility).ObjectID)
    );
  }
  if (ShotAbility == none
        || !ShotAbility.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false))
  {
    // if we don't want a follow up shot or it failed (target dead), enter cover now (i.e. finalise)
    ShotAbility = XComGameState_Ability(
        History.GetGameStateForObjectID(Shooter.FindAbility('SUT_FinaliseAnimation').ObjectID)
    );
    ShotAbility.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false);
  }
}


static function X2AbilityTemplate AddFollowShot(
  name AbilityName,
  eSUTFireMode FireMode
)
{
  local X2AbilityTemplate                 Template;	
  local array<name>                       SkipExclusions;
  local X2Effect_Knockback				KnockbackEffect;
  local X2Condition_Visibility            VisibilityCondition;
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

  // MAKE IT LIVE!
  Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  Template.BuildVisualizationFn = FollowShot_BuildVisualization;
  Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

  Template.bDisplayInUITooltip = false;
  Template.bDisplayInUITacticalText = false;

/* follow up shots don't use cinescript
   this may sound like a bad limitation, but is a reasonable (tm) compromise
   cinescript doesn't even survive multiple blocks, and using no cinescript here prevents hastic camera movement
  Template.bUsesFiringCamera = true;
  Template.CinescriptCameraType = "StandardGunFiring";	
*/

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
  local X2Action_Fire FireAction;
	local X2Action_EnterCover EnterCoverAction;
  local X2Action_WaitForAbilityEffect WaitAction;
	local SmallUnitTactics_X2Action_ManualPermitNextVisualizationBlockToRun ManualRunAction;

	// Build the first shot of Rapid Fire's visualization
	TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);

	Context = VisualizeGameState.GetContext();
	AbilityContext = XComGameStateContext_Ability(Context);

  // SOURCE TRACK EDITS
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
		FireAction = X2Action_Fire(OutVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
		EnterCoverAction = X2Action_EnterCover(OutVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
		if (
      (ExitCoverAction != none) ||
      (FireAction != none) ||
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



  // TARGET TRACK EDITS
	for( TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; ++TrackIndex )
	{
    for( ActionIndex = OutVisualizationTracks[TrackIndex].TrackActions.Length - 1; ActionIndex >= 0; --ActionIndex )
    {
      WaitAction = X2Action_WaitForAbilityEffect(OutVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
      if (
        (WaitAction != none)
      )
      {
        OutVisualizationTracks[TrackIndex].TrackActions.Remove(ActionIndex, 1);
      }
    }
	}
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
    // TODO: this skips one tile movements, since they don't have an interrupt step
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

// What is this? triggered against an enemy or self?
// also, enter cover needs either major changes or the triggering code needs to be adjusted
// since enter cover is responsible for speaking
static function X2AbilityTemplate AddAnimationAbility()
{
  local X2AbilityTemplate                 Template;	
  local X2Condition_Visibility            VisibilityCondition;
  local X2AbilityTrigger_EventListener Trigger;

  // Macro to do localisation and stuffs
  `CREATE_X2ABILITY_TEMPLATE(Template, 'SUT_FinaliseAnimation');

  // Icon Properties
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_supression";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

	// don't frame this -- entering cover isn't something exciting to look at 
	Template.FrameAbilityCameraType = eCameraFraming_Never;


  Trigger = new class'X2AbilityTrigger_EventListener';
  Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
  Trigger.ListenerData.EventID = 'SUT_FinaliseAnimation';
  Trigger.ListenerData.Filter = eFilter_Unit;
  Trigger.ListenerData.EventFn = SingleShotListener;
  Template.AbilityTriggers.AddItem(Trigger);

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

  Template.AbilityTriggers.AddItem(Trigger);

  // MAKE IT LIVE!
  Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  Template.BuildVisualizationFn = Finalize_BuildVisualization;
  // cannot be interrupted
//  Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

  Template.bDisplayInUITooltip = false;
  Template.bDisplayInUITacticalText = false;

  Template.bUsesFiringCamera = true;
  Template.CinescriptCameraType = "StandardGunFiring";	

  return Template;	
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


simulated function Finalize_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory      History;
	local XComGameStateContext_Ability  Context;

	local VisualizationTrack        EmptyTrack;

	local VisualizationTrack        SourceTrack;

	local StateObjectReference          ShootingUnitRef;	
	local Actor                     ShooterVisualizer;

	History = `XCOMHISTORY;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	ShootingUnitRef = Context.InputContext.SourceObject;

	ShooterVisualizer = History.GetVisualizer(ShootingUnitRef.ObjectID);

	SourceTrack = EmptyTrack;
	SourceTrack.StateObject_OldState = History.GetGameStateForObjectID(ShootingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	SourceTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(ShootingUnitRef.ObjectID);
	if (SourceTrack.StateObject_NewState == none)
		SourceTrack.StateObject_NewState = SourceTrack.StateObject_OldState;
	SourceTrack.TrackActor = ShooterVisualizer;


	class'X2Action_EnterCover'.static.AddToVisualizationTrack(SourceTrack, Context);

	OutVisualizationTracks.AddItem(SourceTrack);
}
