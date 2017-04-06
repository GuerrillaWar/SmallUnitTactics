class SmallUnitTactics_CharacterManager extends Object config(SmallUnitTactics);


var config int BaseHPMultiplier;

static function UpdateCharacterProfiles ()
{
  local array<X2DataTemplate> CharTemplates;
  local X2DataTemplate CharTemplate;
  local X2CharacterTemplate CharacterTemplate;
  local X2CharacterTemplateManager Manager;
  local array<name> CharacterNames;
  local name CharacterName;

  Manager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
  Manager.GetTemplateNames(CharacterNames);

  foreach CharacterNames(CharacterName)
  {
    CharTemplates.Length = 0;
    Manager.FindDataTemplateAllDifficulties(CharacterName, CharTemplates);
    foreach CharTemplates(CharTemplate)
    {
      CharacterTemplate = X2CharacterTemplate(CharTemplate);
      CharacterTemplate.CharacterBaseStats[eStat_HP] = (
        CharacterTemplate.CharacterBaseStats[eStat_HP] * default.BaseHPMultiplier
      );
    }
  }
}
