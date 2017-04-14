class SmallUnitTactics_WeaponManager extends Object config(SmallUnitTactics);

enum eSUTFireMode
{
  eSUTFireMode_Aimed,
  eSUTFireMode_Snap,
  eSUTFireMode_Burst,
  eSUTFireMode_Automatic,
};

struct SmallUnitTacticsShotProfile
{
  var int ShotCount;
  var int SuppressionPenalty;
  var int AimModifier;
  var int CritModifier;
};

struct SmallUnitTacticsWeaponProfile
{
  var name WeaponName;
  var int iClipSize;
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

static function int GetShotCount(name WeaponName, eSUTFireMode FireMode)
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;

  WeaponProfile = GetWeaponProfile(WeaponName);

  if (FireMode == eSUTFireMode_Snap)
  {
    return WeaponProfile.Snap.ShotCount;
  }
  else if (FireMode == eSUTFireMode_Aimed)
  {
    return WeaponProfile.Aimed.ShotCount;
  }
  else if (FireMode == eSUTFireMode_Burst)
  {
    return WeaponProfile.Burst.ShotCount;
  }
  else if (FireMode == eSUTFireMode_Automatic)
  {
    return WeaponProfile.Automatic.ShotCount;
  }
  return 0;
}

static function int GetAimModifier(name WeaponName, eSUTFireMode FireMode)
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;

  WeaponProfile = GetWeaponProfile(WeaponName);

  if (FireMode == eSUTFireMode_Snap)
  {
    return WeaponProfile.Snap.AimModifier;
  }
  else if (FireMode == eSUTFireMode_Aimed)
  {
    return WeaponProfile.Aimed.AimModifier;
  }
  else if (FireMode == eSUTFireMode_Burst)
  {
    return WeaponProfile.Burst.AimModifier;
  }
  else if (FireMode == eSUTFireMode_Automatic)
  {
    return WeaponProfile.Automatic.AimModifier;
  }
  return 0;
}

static function int GetCritModifier(name WeaponName, eSUTFireMode FireMode)
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;

  WeaponProfile = GetWeaponProfile(WeaponName);

  if (FireMode == eSUTFireMode_Snap)
  {
    return WeaponProfile.Snap.CritModifier;
  }
  else if (FireMode == eSUTFireMode_Aimed)
  {
    return WeaponProfile.Aimed.CritModifier;
  }
  else if (FireMode == eSUTFireMode_Burst)
  {
    return WeaponProfile.Burst.CritModifier;
  }
  else if (FireMode == eSUTFireMode_Automatic)
  {
    return WeaponProfile.Automatic.CritModifier;
  }
  return 0;
}

static function int GetSuppressionPenalty(name WeaponName, eSUTFireMode FireMode)
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;

  WeaponProfile = GetWeaponProfile(WeaponName);

  if (FireMode == eSUTFireMode_Snap)
  {
    return WeaponProfile.Snap.SuppressionPenalty;
  }
  else if (FireMode == eSUTFireMode_Aimed)
  {
    return WeaponProfile.Aimed.SuppressionPenalty;
  }
  else if (FireMode == eSUTFireMode_Burst)
  {
    return WeaponProfile.Burst.SuppressionPenalty;
  }
  else if (FireMode == eSUTFireMode_Automatic)
  {
    return WeaponProfile.Automatic.SuppressionPenalty;
  }
  return 0;
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
      WeaponTemplate.iClipSize = WeaponProfile.iClipSize;

      WeaponTemplate.Abilities.RemoveItem('StandardShot');
      WeaponTemplate.Abilities.AddItem('SUT_AmbientSuppressionCancel');
      WeaponTemplate.Abilities.AddItem('SUT_FinaliseAnimation');
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
        WeaponTemplate.Abilities.AddItem('SUT_BurstFollowShot');
      }

      if (WeaponProfile.Automatic.ShotCount > 0)
      {
        WeaponTemplate.Abilities.AddItem('SUT_AutoShot');
        WeaponTemplate.Abilities.AddItem('SUT_AutoFollowShot');
      }
    }
  }
}
