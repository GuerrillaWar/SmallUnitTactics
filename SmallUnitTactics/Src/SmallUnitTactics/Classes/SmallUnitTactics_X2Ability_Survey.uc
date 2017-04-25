class SmallUnitTactics_X2Ability_Survey extends X2Ability config(SmallUnitTactics);

var config int SurveySightRadiusBoost;

var localized string SurveyEffectName;
var localized string SurveyEffectDescription;

static function array<X2DataTemplate> CreateTemplates()
{
  local array<X2DataTemplate> Templates;

  Templates.AddItem(AddSurvey());

  return Templates;
}


static function X2AbilityTemplate AddSurvey() {
  local X2AbilityTemplate                 Template;	
  local X2AbilityCost_ActionPoints        ActionPointCost;
  local X2Effect_PersistentStatChange     StatChange;

  // Macro to do localisation and stuffs
  `CREATE_X2ABILITY_TEMPLATE(Template, 'SUT_Survey');

  // Icon Properties
  Template.bDontDisplayInAbilitySummary = true;
  Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standard";
  Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_SHOT_PRIORITY;
  Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
  Template.DisplayTargetHitChance = true;
  Template.AbilitySourceName = 'eAbilitySource_Standard';    // color of the icon
  // Activated by a button press; additionally, tells the AI this is an activatable
  Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
  Template.Hostility = eHostility_Neutral;

  Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
  // Only at single targets that are in range.
	Template.AbilityToHitCalc = default.DeadEye;
  Template.AbilityTargetStyle = default.SelfTarget;

  // Action Point
  ActionPointCost = new class'X2AbilityCost_ActionPoints';
  ActionPointCost.iNumPoints = 2;
  ActionPointCost.bConsumeAllPoints = true;
  Template.AbilityCosts.AddItem(ActionPointCost);	

  `log("SmallUnitTactics.SurveySightRadiusBoost:" @ default.SurveySightRadiusBoost);

  StatChange = new class'X2Effect_PersistentStatChange';
  StatChange.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
  StatChange.AddPersistentStatChange(eStat_SightRadius, default.SurveySightRadiusBoost);
  StatChange.bRemoveWhenTargetDies = true;
  StatChange.bRemoveWhenSourceDamaged = true;
  StatChange.SetSourceDisplayInfo(ePerkBuff_Bonus, default.SurveyEffectName, default.SurveyEffectDescription, Template.IconImage);
  Template.AddShooterEffect(StatChange);

  // Targeting Method
  Template.TargetingMethod = class'X2TargetingMethod_TopDown';

  // MAKE IT LIVE!
  Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
  Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

  Template.bDisplayInUITooltip = false;
  Template.bDisplayInUITacticalText = false;

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bSkipPerkActivationActions = true;

  return Template;	
}

