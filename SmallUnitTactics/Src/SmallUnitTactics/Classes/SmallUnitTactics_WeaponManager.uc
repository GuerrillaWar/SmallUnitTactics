class SmallUnitTactics_WeaponManager extends Object config(SmallUnitTactics);

struct SmallUnitTacticsShotProfile
{
  var int ShotCount;
};

struct SmallUnitTacticsWeaponProfile
{
  var name WeaponName;
  var WeaponDamageValue BulletProfile;
  var SmallUnitTacticsShotProfile Aimed;
  var SmallUnitTacticsShotProfile Snap;
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
      WeaponTemplate.BaseDamage = WeaponProfile.BulletProfile;

      WeaponTemplate.Abilities.RemoveItem('StandardShot');
      if (WeaponProfile.Aimed.ShotCount > 0)
      {
        WeaponTemplate.Abilities.AddItem('SUT_AimedShot');
      }

      if (WeaponProfile.Snap.ShotCount > 0)
      {
        WeaponTemplate.Abilities.AddItem('SUT_SnapShot');
      }

      if (WeaponProfile.Burst.ShotCount > 0)
      {
        WeaponTemplate.Abilities.AddItem('SUT_BurstShot');
      }

      if (WeaponProfile.Automatic.ShotCount > 0)
      {
        WeaponTemplate.Abilities.AddItem('SUT_AutoShot');
      }
    }
  }
}
