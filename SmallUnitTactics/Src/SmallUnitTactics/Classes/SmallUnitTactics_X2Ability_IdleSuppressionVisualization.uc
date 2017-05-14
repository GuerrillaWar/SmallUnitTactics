// we need an ability template to serve as a dummy for the projectile system
// it needs flags like bIsASuppressionEffect
class SmallUnitTactics_X2Ability_IdleSuppressionVisualization extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(IdleSuppressionDummy());

	return Templates;
}


static function X2AbilityTemplate IdleSuppressionDummy()
{
	local X2AbilityTemplate Template;	

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SmallUnitTactics_IdleSuppression_DONTUSE');
	// really the only required flag, but important
	Template.bIsASuppressionEffect = true;
	// don't activate. really, please don't
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');
	// need one AbilityTargetEffect, without one X2Ability.UpdateTargetLocationsFromContext refuses to build target locations
	Template.AddTargetEffect(none);
	// required for validation
	Template.AbilityTargetStyle = default.SelfTarget;
	// don't show.
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	
	Template.BuildNewGameStateFn = CrashTheGame_BuildGameState;

	return Template;
}

static simulated function XComGameState CrashTheGame_BuildGameState(XComGameStateContext Context)
{
	`log("SmallUnitTactics_Suppression: Used Dummy Ability. Bad. \n" @ GetScriptTrace());
	`assert(false);
	return none;
}
