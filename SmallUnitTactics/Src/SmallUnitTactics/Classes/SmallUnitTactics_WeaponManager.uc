class SmallUnitTactics_WeaponManager extends Object config(SmallUnitTactics);

enum eSUTFireMode
{
  eSUTFireMode_Aimed,
  eSUTFireMode_Snap,
  eSUTFireMode_Burst,
  eSUTFireMode_Automatic,
};

struct SmallUnitTacticsGrazeProfile
{
  var int High;
  var int Low;
  var int Open; // used for units that don't take cover
  var int Flanked;

  structdefaultproperties
  {
    High = -1;
    Low = -1;
    Open = -1;
    Flanked = -1;
  }
};

struct SmallUnitTacticsShotProfile
{
  var int ShotCount;
  var int SuppressionPenalty;
  var int AimModifier;
  var int CritModifier;
  var SmallUnitTacticsGrazeProfile GrazeModifier;
};

struct SmallUnitTacticsWeaponProfile
{
  var name WeaponName;
  var int iClipSize;
  var WeaponDamageValue BulletProfile;
  var eSUTFireMode OverwatchFireMode;
  var SmallUnitTacticsGrazeProfile DefaultGrazeModifier;
  var SmallUnitTacticsShotProfile Aimed;
  var SmallUnitTacticsShotProfile Snap;
  var SmallUnitTacticsShotProfile Burst;
  var SmallUnitTacticsShotProfile Automatic;
};

var config array<SmallUnitTacticsWeaponProfile>   arrWeaponProfiles;
var config array<name>                            arrTimedGrenades;

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

  switch (FireMode)
  {
    case eSUTFireMode_Snap:
    return WeaponProfile.Snap.ShotCount;

    case eSUTFireMode_Aimed:
    return WeaponProfile.Aimed.ShotCount;

    case eSUTFireMode_Burst:
    return WeaponProfile.Burst.ShotCount;
    
    case eSUTFireMode_Automatic:
    return WeaponProfile.Automatic.ShotCount;
  }
  return 0;
}

static function int GetAimModifier(name WeaponName, eSUTFireMode FireMode)
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;

  WeaponProfile = GetWeaponProfile(WeaponName);

  switch (FireMode)
  {
    case eSUTFireMode_Snap:
    return WeaponProfile.Snap.AimModifier;

    case eSUTFireMode_Aimed:
    return WeaponProfile.Aimed.AimModifier;

    case eSUTFireMode_Burst:
    return WeaponProfile.Burst.AimModifier;
    
    case eSUTFireMode_Automatic:
    return WeaponProfile.Automatic.AimModifier;
  }
  return 0;
}

static function int GetCritModifier(name WeaponName, eSUTFireMode FireMode)
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;

  WeaponProfile = GetWeaponProfile(WeaponName);

  switch (FireMode)
  {
    case eSUTFireMode_Snap:
    return WeaponProfile.Snap.CritModifier;

    case eSUTFireMode_Aimed:
    return WeaponProfile.Aimed.CritModifier;

    case eSUTFireMode_Burst:
    return WeaponProfile.Burst.CritModifier;
    
    case eSUTFireMode_Automatic:
    return WeaponProfile.Automatic.CritModifier;
  }
  return 0;
}

static function int GetSuppressionPenalty(name WeaponName, eSUTFireMode FireMode)
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;

  WeaponProfile = GetWeaponProfile(WeaponName);

  switch (FireMode)
  {
    case eSUTFireMode_Snap:
    return WeaponProfile.Snap.SuppressionPenalty;

    case eSUTFireMode_Aimed:
    return WeaponProfile.Aimed.SuppressionPenalty;

    case eSUTFireMode_Burst:
    return WeaponProfile.Burst.SuppressionPenalty;
    
    case eSUTFireMode_Automatic:
    return WeaponProfile.Automatic.SuppressionPenalty;
  }
  return 0;
}

static function SmallUnitTacticsGrazeProfile GetGrazeProfile(
  name WeaponName, name AbilityName
)
{
  local SmallUnitTacticsWeaponProfile WeaponProfile;
  local SmallUnitTacticsGrazeProfile IdealGrazeProfile;

  WeaponProfile = GetWeaponProfile(WeaponName);

  switch (AbilityName)
  {
    case 'SUT_SnapShot':
    IdealGrazeProfile = WeaponProfile.Snap.GrazeModifier;
    break;

    case 'SUT_AimedShot':
    IdealGrazeProfile = WeaponProfile.Aimed.GrazeModifier;
    break;

    case 'SUT_BurstShot':
    case 'SUT_BurstFollowShot':
    IdealGrazeProfile = WeaponProfile.Burst.GrazeModifier;
    break;
    
    case 'SUT_AutoShot':
    case 'SUT_AutoFollowShot':
    IdealGrazeProfile = WeaponProfile.Automatic.GrazeModifier;
    break;
  }

  if (IdealGrazeProfile.High == -1)
  {
    return WeaponProfile.DefaultGrazeModifier;
  }
  else
  {
    return IdealGrazeProfile;
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
      WeaponTemplate.iClipSize = WeaponProfile.iClipSize;

      WeaponTemplate.Abilities.RemoveItem('StandardShot');
      WeaponTemplate.Abilities.RemoveItem('SniperStandardFire');
      WeaponTemplate.Abilities.AddItem('SUT_AmbientSuppressionCancel');
      WeaponTemplate.Abilities.AddItem('SUT_FinaliseAnimation');

      WeaponTemplate.Abilities.RemoveItem('Overwatch');
      WeaponTemplate.Abilities.RemoveItem('OverwatchShot');
      WeaponTemplate.Abilities.RemoveItem('SniperOverwatch');
      WeaponTemplate.Abilities.RemoveItem('SniperOverwatchShot');

      if (WeaponProfile.OverwatchFireMode == eSUTFireMode_Snap)
      {
        WeaponTemplate.Abilities.AddItem('SUT_OverwatchSnap');
        WeaponTemplate.Abilities.AddItem('SUT_OverwatchSnapShot');
      }
      else
      {
        WeaponTemplate.Abilities.AddItem('SUT_OverwatchBurst');
        WeaponTemplate.Abilities.AddItem('SUT_OverwatchBurstShot');
        WeaponTemplate.Abilities.AddItem('SUT_OverwatchBurstFollowShot');
      }

      if (WeaponProfile.DefaultGrazeModifier.High != -1)
      {
        WeaponTemplate.Abilities.AddItem('SUT_WeaponConditionalGraze');
      }

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


static function LoadGrenadeProfiles ()
{
  local array<X2DataTemplate> ItemTemplates;
  local X2DataTemplate ItemTemplate;
  local X2GrenadeTemplate GrenadeTemplate;
  local X2ItemTemplateManager Manager;
  local name GrenadeName, AbilityName;

  Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

  foreach default.arrTimedGrenades(GrenadeName)
  {
    ItemTemplates.Length = 0;
    Manager.FindDataTemplateAllDifficulties(GrenadeName, ItemTemplates);
    foreach ItemTemplates(ItemTemplate)
    {
      GrenadeTemplate = X2GrenadeTemplate(ItemTemplate);
      GrenadeTemplate.Abilities.RemoveItem('ThrowGrenade');
      GrenadeTemplate.Abilities.AddItem('SUT_ThrowGrenade');
      GrenadeTemplate.Abilities.AddItem('SUT_PrimeGrenade');
      GrenadeTemplate.Abilities.AddItem('SUT_ThrowPrimedGrenade');
      if (GrenadeTemplate.AbilityIconOverrides.Length > 0)
      {
        GrenadeTemplate.AddAbilityIconOverride(
          'SUT_ThrowGrenade',
          GrenadeTemplate.AbilityIconOverrides[0].OverrideIcon
        );
        GrenadeTemplate.AddAbilityIconOverride(
          'SUT_ThrowPrimedGrenade',
          GrenadeTemplate.AbilityIconOverrides[0].OverrideIcon
        );
        GrenadeTemplate.AddAbilityIconOverride(
          'SUT_LaunchGrenade',
          GrenadeTemplate.AbilityIconOverrides[0].OverrideIcon
        );
      }
      GrenadeTemplate.Abilities.AddItem(
        class'SmallUnitTactics_X2Ability_Grenades'.default.DetonateGrenadeAbilityName
      );
      GrenadeTemplate.Abilities.AddItem(
        class'SmallUnitTactics_X2Ability_Grenades'.default.DetonateLaunchedGrenadeAbilityName
      );
    }
  }
}


static function LockdownAbilitiesWhenPrimedGrenadeHeld ()
{
  local array<X2DataTemplate> DataTemplates;
  local X2DataTemplate DataTemplate;
  local X2AbilityTemplate AbilityTemplate;
  local X2AbilityTemplateManager Manager;
  local array<name> AbilityNames;
  local name AbilityName;
  local X2Condition_UnitEffects           ExcludeEffects;
  local int Index;
  local bool bInputAbility;

  Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
  Manager.GetTemplateNames(AbilityNames);

  foreach AbilityNames(AbilityName)
  {
    if (
      AbilityName == 'SUT_ThrowPrimedGrenade' ||
      AbilityName == 'SUT_DetonateGrenade' ||
      AbilityName == 'SUT_DetonateLaunchedGrenade'
    )
    {
      continue;
    }
    DataTemplates.Length = 0;
    Manager.FindDataTemplateAllDifficulties(AbilityName, DataTemplates);
    foreach DataTemplates(DataTemplate)
    {
      AbilityTemplate = X2AbilityTemplate(DataTemplate);

      for( Index = 0; Index < AbilityTemplate.AbilityTriggers.Length && !bInputAbility; ++Index )
      {
        bInputAbility = AbilityTemplate.AbilityTriggers[Index].IsA('X2AbilityTrigger_PlayerInput');
      }

      if (bInputAbility)
      {
        ExcludeEffects = new class'X2Condition_UnitEffects';
        ExcludeEffects.AddExcludeEffect(class'SmallUnitTactics_Effect_PrimedGrenade'.default.EffectName, 'AA_HoldingPrimedGrenade');
        AbilityTemplate.AbilityShooterConditions.AddItem(ExcludeEffects);
      }
    }
  }
}
