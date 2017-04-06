class X2DownloadableContentInfo_SmallUnitTactics extends X2DownloadableContentInfo Config(Game);

static event OnPostTemplatesCreated()
{
  `log("SmallUnitTactics :: Present And Correct");

  class'SmallUnitTactics_WeaponManager'.static.LoadWeaponProfiles();
  class'SmallUnitTactics_CharacterManager'.static.UpdateCharacterProfiles();
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
