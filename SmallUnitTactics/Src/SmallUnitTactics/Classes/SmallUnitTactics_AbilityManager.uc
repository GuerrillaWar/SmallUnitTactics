// the AbilityManager exists on top of the WeaponManager and is used by the Ability Game Rules to determine the follow-up behavior
// theoretically (untested!), this allows completely different abilities to share the same shot profiles
// the usefulness is questionable, the code style gets bonus points
class SmallUnitTactics_AbilityManager extends Object;

// stores the relation of trigger abilities and follow up shots
// in a way that's easy to handle for the game rules
// and allows generic helper functions
struct AbilityRelation
{
  var name TriggerAbility;
  var name FollowUpAbility;
  var eSUTFireMode FireMode;
  var bool bOverwatch;
};

var array<AbilityRelation> arrAbilityConfigs;


// registers ability info. use when creating templates
static function RegisterAbilityPair(
  name TriggerName, name FollowUpName,
  eSUTFireMode FireMode, bool bOverwatch
)
{
  local SmallUnitTactics_AbilityManager CDO;
  local AbilityRelation NewRelation;
  // the class default object (cdo) is the owner of static functions
  // modifying stuff on it affects "default." contexts, and affect the static functions below
  CDO = SmallUnitTactics_AbilityManager(class'Engine'.static.FindClassDefaultObject(default.Class.GetPackageName()$"."$default.Class));

  NewRelation.TriggerAbility = TriggerName;
  NewRelation.FollowUpAbility = FollowUpName;
  NewRelation.FireMode = FireMode;
  NewRelation.bOverwatch = bOverwatch;
  CDO.arrAbilityConfigs.AddItem(NewRelation);
}

// param ActivatedContext: an activated ability context part of a shot-follow-up chain
// out param out_iCurrentShot: the index of this shot in the whole chain. attn: don't fall for off-by-one
// out param out_iMaxShots: the potential maximum number of shots permitted by weapon and ability
// out param out_iNumShots: the actual number of taken shots. -1 if not applicable due to event chain not done (no finalize found)
// returns true if info successfully found, false if not. if the function returns false, out parameters shouldn't be trusted
// reasons for returning false can be an unsupported ability context, no trigger shot in the history etc.
static function bool GetEventChainInfo(const XComGameStateContext_Ability AbilityContext, out int out_iCurrentShot, out int out_iMaxShots, out int out_iNumShots, out AbilityRelation out_AbilityRelation)
{
  local XComGameStateContext_Ability HistoryAbilityContext;
  local XComGameStateHistory History;
  local XComGameState_Item SourceWeaponState;
  local int ShotHistoryIndex;
  local bool bEndFound;

  History = `XCOMHISTORY;
 
  if (AbilityContext == none || !FindRelation(AbilityContext.InputContext.AbilityTemplateName, out_AbilityRelation))
  {
    // if the context isn't an ability context or the ability is not part of a burst sequence
    return false;
  }

  SourceWeaponState = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
  if (SourceWeaponState == none)
  {
    return false;
  }

  out_iMaxShots = class'SmallUnitTactics_WeaponManager'.static.GetShotCount(SourceWeaponState.GetMyTemplateName(), out_AbilityRelation.FireMode);
  if (out_iMaxShots <= 0)
  {
     return false;
  }


  ShotHistoryIndex = AbilityContext.AssociatedState.HistoryIndex;
  // clear to prevent bad handling
  out_iNumShots = 0;

  // we now do two things: first, we iterate into the past, find the shot, and find out what has happened before the passed in shot
  // we use this to fill out out_iCurrentShot

  foreach History.IterateContextsByClassType(class'XComGameStateContext_Ability', HistoryAbilityContext)
  {
    // in the first loop, we *explicitely* use <= so we count the passed AbilityContext too
	if (HistoryAbilityContext.AssociatedState.HistoryIndex <= ShotHistoryIndex)
    {
      // same unit, not interrupt
      // the last condition prevents an interrupted shot (enemy covering fire) from counting as two shots, as there are two contexts for it 
      if (HistoryAbilityContext.InputContext.SourceObject == AbilityContext.InputContext.SourceObject
            && HistoryAbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
      {
        if (HistoryAbilityContext.InputContext.AbilityTemplateName == out_AbilityRelation.FollowUpAbility)
        {
  	      out_iNumShots++;
        }
        else if (HistoryAbilityContext.InputContext.AbilityTemplateName == out_AbilityRelation.TriggerAbility)
        {
	      out_iNumShots++;
          // we hit the start of the chain. break
          break;
        }
        else
        {
          // this can be desired or unavoidable behavior. simple modifications to the unit can be triggered as abilities
          `warn("Warning:" @ HistoryAbilityContext.InputContext.AbilityTemplateName @ "has been triggered within a shot sequence. Allowed?");
        }
      }
    }
  }
  out_iCurrentShot = out_iNumShots - 1;

  // after that, we iterate into the future, find that shot to find out what has happened after the passed in shot
  // fills out out_iNumShots. primarily, this can be used to determine if this is the last shot that occured, for visualization purposes
  // this is invalid if the sequence isn't done

  bEndFound = false;
  foreach History.IterateContextsByClassType(class'XComGameStateContext_Ability', HistoryAbilityContext, , false)
  {
    // in the second loop, we *explicitely* use > so we don't count the passed one twice
    if (HistoryAbilityContext.AssociatedState.HistoryIndex > ShotHistoryIndex)
    {
      // same unit, not interrupt
      // the last condition prevents an interrupted shot (enemy covering fire) from counting as two shots, as there are two contexts for it 
      if (HistoryAbilityContext.InputContext.SourceObject == AbilityContext.InputContext.SourceObject
            && HistoryAbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
      {
        if (HistoryAbilityContext.InputContext.AbilityTemplateName == out_AbilityRelation.FollowUpAbility)
        {
  	      out_iNumShots++;
        }
		// hardcoded finalise name
        else if (HistoryAbilityContext.InputContext.AbilityTemplateName == 'SUT_FinaliseAnimation')
        {
          // we hit the end of the chain. break
          bEndFound = true;
          break;
        }
        else
        {
          // this can be desired or unavoidable behavior. simple modifications to the unit can be triggered as abilities
          `warn("Warning:" @ HistoryAbilityContext.InputContext.AbilityTemplateName @ "has been triggered within a shot sequence. Allowed?");
        }
      }
    }
  }

  if (!bEndFound)
  {
    out_iNumShots = -1;
  }

  // these are all the parameters.
  return true;
}

// given an ability name, finds the relation and whether it's a follow-up shot or a trigger shot
static function bool FindRelation(name AbilityName, out AbilityRelation out_AbilityRelation, optional out int bIsFollowUp)
{
	local int i;
	i = default.arrAbilityConfigs.Find('FollowUpAbility', AbilityName);
	bIsFollowUp = -1;
	if (i > INDEX_NONE)
	{
		bIsFollowUp = 1;
	}
	else
	{
		i = default.arrAbilityConfigs.Find('TriggerAbility', AbilityName);
		if (i > INDEX_NONE)
		{
			bIsFollowUp = 0;
		}
		else
		{
			return false;
		}
	}
	out_AbilityRelation = default.arrAbilityConfigs[i];
	return true;
}
