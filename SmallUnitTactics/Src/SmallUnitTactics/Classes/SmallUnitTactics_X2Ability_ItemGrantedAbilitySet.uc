class SmallUnitTactics_X2Ability_ItemGrantedAbilitySet extends X2Ability
	dependson (XComGameStateContext_Ability) config(GameCore);

var config int KEVLAR_HEALTH_BONUS;
var config int KEVLAR_MITIGATION_CHANCE;
var config int KEVLAR_MITIGATION_AMOUNT;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(KevlarArmorStats());

	return Templates;
}


static function X2AbilityTemplate KevlarArmorStats()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'KevlarArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);
	
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
  if (default.KEVLAR_HEALTH_BONUS != 0)
  {
    PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.KEVLAR_HEALTH_BONUS);
  }
  if (default.KEVLAR_MITIGATION_CHANCE != 0)
  {
    PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, default.KEVLAR_MITIGATION_CHANCE);
  }
  if (default.KEVLAR_MITIGATION_AMOUNT != 0)
  {
    PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.KEVLAR_MITIGATION_AMOUNT);
  }
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}
