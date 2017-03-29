class X2DownloadableContentInfo_SmallUnitTactics extends X2DownloadableContentInfo Config(Game);

static event OnPostTemplatesCreated()
{
  `log("SmallUnitTactics :: Present And Correct");

  class'SmallUnitTactics_WeaponManager'.static.LoadWeaponProfiles();
}
