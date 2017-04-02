class SmallUnitTactics_WeaponManager extends Object config(SmallUnitTactics);

struct SmallUnitTacticsShotProfile
{
  var int ShotCount;
};

struct SmallUnitTacticsWeaponProfile
{
  var name WeaponName;
  var SmallUnitTacticsShotProfile Burst;
  var SmallUnitTacticsShotProfile Automatic;
};

var config array<SmallUnitTacticsWeaponProfile>   arrWeaponProfiles;

static function SmallUnitTacticsWeaponProfile GetWeaponProfile(
  name WeaponName
)
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;

  foreach default.arrWeaponProfiles(WeaponProfile)
  {
    if (WeaponProfile.WeaponName == WeaponName)
    {
      return WeaponProfile;
    }
  }
}

static function LoadWeaponProfiles ()
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;
  local array<X2DataTemplate> ItemTemplates;
  local X2DataTemplate ItemTemplate;
  local X2WeaponTemplate WeaponTemplate;
  local X2ItemTemplateManager Manager;

  Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

  foreach default.arrWeaponProfiles(WeaponProfile)
  {
    ItemTemplates.Length = 0;
    Manager.FindDataTemplateAllDifficulties(WeaponProfile.WeaponName, ItemTemplates);
    foreach ItemTemplates(ItemTemplate)
    {
      WeaponTemplate = X2WeaponTemplate(ItemTemplate);

      WeaponTemplate.Abilities.RemoveItem('StandardShot');
      WeaponTemplate.Abilities.AddItem('SUT_AimedShot');
      WeaponTemplate.Abilities.AddItem('SUT_SnapShot');
      WeaponTemplate.Abilities.AddItem('SUT_BurstShot');
      WeaponTemplate.Abilities.AddItem('SUT_AutoShot');
    }
  }
}
