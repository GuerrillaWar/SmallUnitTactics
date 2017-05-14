class X2DownloadableContentInfo_SmallUnitTactics extends X2DownloadableContentInfo Config(Game);

static event OnPostTemplatesCreated()
{
  `log("SmallUnitTactics :: Present And Correct");

  class'SmallUnitTactics_WeaponManager'.static.LoadWeaponProfiles();
  class'SmallUnitTactics_WeaponManager'.static.LoadGrenadeProfiles();
  class'SmallUnitTactics_CharacterManager'.static.UpdateCharacterProfiles();
  class'SmallUnitTactics_CharacterManager'.static.AddSoldierAbilities();
  class'SmallUnitTactics_CharacterManager'.static.SetDetectionRadius();
  class'SmallUnitTactics_WeaponManager'.static.LockdownAbilitiesWhenPrimedGrenadeHeld();
  ChainAbilityTag();
}


static event OnLoadedSavedGame()
{
  class'SmallUnitTactics_GameState_ListenerManager'.static.CreateListenerManager();
}

static event OnLoadedSavedGameToStrategy()
{
  class'SmallUnitTactics_GameState_ListenerManager'.static.RefreshListeners();
}

static event InstallNewCampaign(XComGameState StartState)
{
  class'SmallUnitTactics_GameState_ListenerManager'.static.CreateListenerManager(StartState);
}

/// </summary>
static event OnPostMission()
{
  class'SmallUnitTactics_GameState_ListenerManager'.static.RefreshListeners();
}

exec function ToggleIASMText()
{
	class'UIDebugStateMachines'.static.GetThisScreen().ToggleVisible();
}


static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local int i;
	local AbilitySetupData NewData;
	i = SetupData.Find('TemplateName', 'SUT_SnapShot');
	if (i == INDEX_NONE) { i = SetupData.Find('TemplateName', 'SUT_BurstShot'); }
	if (i == INDEX_NONE) { i = SetupData.Find('TemplateName', 'SUT_AutoShot'); }
	if (i == INDEX_NONE) { i = SetupData.Find('TemplateName', 'SUT_AimedShot'); }
	if (i == INDEX_NONE) return;
	NewData.TemplateName = 'SmallUnitTactics_IdleSuppression_DONTUSE';
	NewData.Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('SmallUnitTactics_IdleSuppression_DONTUSE');
	NewData.SourceWeaponRef = SetupData[i].SourceWeaponRef;
	SetupData.AddItem(NewData);
}


static function ChainAbilityTag()
{
  local XComEngine Engine;
  local SmallUnitTactics_X2AbilityTag AbilityTag;
  local X2AbilityTag OldAbilityTag;
  local int idx;

  Engine = `XENGINE;

  OldAbilityTag = Engine.AbilityTag;

  AbilityTag = new class'SmallUnitTactics_X2AbilityTag';
  AbilityTag.WrappedTag = OldAbilityTag;

  idx = Engine.LocalizeContext.LocalizeTags.Find(Engine.AbilityTag);
  Engine.AbilityTag = AbilityTag;
  Engine.LocalizeContext.LocalizeTags[idx] = AbilityTag;
}
