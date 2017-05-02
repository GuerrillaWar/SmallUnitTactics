class X2DownloadableContentInfo_SmallUnitTactics extends X2DownloadableContentInfo Config(Game);

static event OnPostTemplatesCreated()
{
  `log("SmallUnitTactics :: Present And Correct");

  class'SmallUnitTactics_WeaponManager'.static.LoadWeaponProfiles();
  class'SmallUnitTactics_WeaponManager'.static.LoadGrenadeProfiles();
  class'SmallUnitTactics_CharacterManager'.static.UpdateCharacterProfiles();
  class'SmallUnitTactics_CharacterManager'.static.AddSoldierAbilities();
  class'SmallUnitTactics_CharacterManager'.static.SetDetectionRadius();
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
