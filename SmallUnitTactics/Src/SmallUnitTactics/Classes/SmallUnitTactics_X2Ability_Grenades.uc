class SmallUnitTactics_X2Ability_Grenades extends X2Ability config(SmallUnitTactics);

var name DetonateGrenadeAbilityName;

var config string DetonateGrenadeExplosion;       //  Particle effect for explosion

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(ThrowGrenade());
	Templates.AddItem(LaunchGrenade());
	Templates.AddItem(DetonateGrenade());

	return Templates;
}

static function X2AbilityTemplate ThrowGrenade()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2AbilityTarget_Cursor            CursorTarget;
	local X2AbilityMultiTarget_Radius       RadiusMultiTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_UnitInventory         UnitInventoryCondition;
	local X2Condition_AbilitySourceWeapon   GrenadeCondition, ProximityMineCondition;
	local X2Effect_ProximityMine            ProximityMineEffect;
  local SmallUnitTactics_Effect_TickingGrenade TickingGrenadeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SUT_ThrowGrenade');	
	
	Template.bDontDisplayInAbilitySummary = true;
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('Salvo');
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIndirectFire = true;
	StandardAim.bAllowCrit = false;
	Template.AbilityToHitCalc = StandardAim;
	
	Template.bUseThrownGrenadeEffects = false;
	Template.bHideWeaponDuringFire = true;
	
	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	UnitInventoryCondition = new class'X2Condition_UnitInventory';
	UnitInventoryCondition.RelevantSlot = eInvSlot_SecondaryWeapon;
	UnitInventoryCondition.ExcludeWeaponCategory = 'grenade_launcher';
	Template.AbilityShooterConditions.AddItem(UnitInventoryCondition);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = false; //The grenade can affect interactive objects, others
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	GrenadeCondition = new class'X2Condition_AbilitySourceWeapon';
	GrenadeCondition.CheckGrenadeFriendlyFire = true;
	Template.AbilityMultiTargetConditions.AddItem(GrenadeCondition);

	Template.AddShooterEffectExclusions();

	Template.bRecordValidTiles = true;

	/* ProximityMineEffect = new class'X2Effect_ProximityMine'; */
	/* ProximityMineEffect.BuildPersistentEffect(1, true, false, false); */
	/* ProximityMineCondition = new class'X2Condition_AbilitySourceWeapon'; */
	/* ProximityMineCondition.MatchGrenadeType = 'ProximityMine'; */
	/* ProximityMineEffect.TargetConditions.AddItem(ProximityMineCondition); */
	/* Template.AddShooterEffect(ProximityMineEffect); */

	TickingGrenadeEffect = new class'SmallUnitTactics_Effect_TickingGrenade';
	TickingGrenadeEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddShooterEffect(TickingGrenadeEffect);

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_WeaponIncompatible');
	Template.HideErrors.AddItem('AA_CannotAfford_AmmoCost');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_fraggrenade";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;
	Template.bUseAmmoAsChargesForHUD = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
  Template.ActionFireClass = class'SmallUnitTactics_X2Action_FireNoExplode';

	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.DamagePreviewFn = GrenadeDamagePreview;
	Template.TargetingMethod = class'X2TargetingMethod_Grenade';
	Template.CinescriptCameraType = "StandardGrenadeFiring";

	// This action is considered 'hostile' and can be interrupted!
	Template.Hostility = eHostility_Offensive;
  Template.ConcealmentRule = eConceal_Always;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	return Template;	
}

static function X2DataTemplate LaunchGrenade()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2AbilityTarget_Cursor            CursorTarget;
	local X2AbilityMultiTarget_Radius       RadiusMultiTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_AbilitySourceWeapon   GrenadeCondition, ProximityMineCondition;
	local X2Effect_ProximityMine            ProximityMineEffect;
  local SmallUnitTactics_Effect_TickingGrenade TickingGrenadeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SUT_LaunchGrenade');

	Template.SoldierAbilityPurchasedFn = class'X2Ability_GrenadierAbilitySet'.static.GrenadePocketPurchased;
	
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;
	AmmoCost.UseLoadedAmmo = true;
	Template.AbilityCosts.AddItem(AmmoCost);
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('Salvo');
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIndirectFire = true;
	StandardAim.bAllowCrit = false;
	Template.AbilityToHitCalc = StandardAim;
	
	Template.bUseLaunchedGrenadeEffects = true;
	Template.bHideAmmoWeaponDuringFire = true; // hide the grenade
	
	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	GrenadeCondition = new class'X2Condition_AbilitySourceWeapon';
	GrenadeCondition.CheckGrenadeFriendlyFire = true;
	Template.AbilityMultiTargetConditions.AddItem(GrenadeCondition);

	Template.AddShooterEffectExclusions();

	Template.bRecordValidTiles = true;

	/* ProximityMineEffect = new class'X2Effect_ProximityMine'; */
	/* ProximityMineEffect.BuildPersistentEffect(1, true, false, false); */
	/* ProximityMineCondition = new class'X2Condition_AbilitySourceWeapon'; */
	/* ProximityMineCondition.MatchGrenadeType = 'ProximityMine'; */
	/* ProximityMineEffect.TargetConditions.AddItem(ProximityMineCondition); */
	/* Template.AddShooterEffect(ProximityMineEffect); */

	TickingGrenadeEffect = new class'SmallUnitTactics_Effect_TickingGrenade';
	TickingGrenadeEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddShooterEffect(TickingGrenadeEffect);

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_CannotAfford_AmmoCost');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_grenade_launcher";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;
	Template.bUseAmmoAsChargesForHUD = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

	// Scott W says a Launcher VO cue doesn't exist, so I should use this one.  mdomowicz 2015_08_24
	Template.ActivationSpeech = 'ThrowGrenade';
  Template.ActionFireClass = class'SmallUnitTactics_X2Action_FireNoExplode';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.DamagePreviewFn = GrenadeDamagePreview;
	Template.TargetingMethod = class'X2TargetingMethod_Grenade';
	Template.CinescriptCameraType = "Grenadier_GrenadeLauncher";

	// This action is considered 'hostile' and can be interrupted!
	Template.Hostility = eHostility_Offensive;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;	

	return Template;
}

static function X2AbilityTemplate DetonateGrenade()
{
	local X2AbilityTemplate							Template;
	local X2AbilityToHitCalc_StandardAim			ToHit;
	local X2Condition_UnitProperty					UnitPropertyCondition;
	local X2Condition_AbilitySourceWeapon			GrenadeCondition;
	local X2AbilityTarget_Cursor					CursorTarget;
	local X2AbilityMultiTarget_Radius	            RadiusMultiTarget;
	local X2Effect_ApplyWeaponDamage				WeaponDamage;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.DetonateGrenadeAbilityName);

	ToHit = new class'X2AbilityToHitCalc_StandardAim';
	ToHit.bIndirectFire = true;
	Template.AbilityToHitCalc = ToHit;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.IncreaseWeaponRange = 2;
	Template.AbilityTargetStyle = CursorTarget;

	Template.AddShooterEffect(new class'X2Effect_BreakUnitConcealment');
	Template.bUseThrownGrenadeEffects = true;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = false; //The grenade can affect interactive objects, others
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	GrenadeCondition = new class'X2Condition_AbilitySourceWeapon';
	GrenadeCondition.CheckGrenadeFriendlyFire = true;
	Template.AbilityMultiTargetConditions.AddItem(GrenadeCondition);

	WeaponDamage = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamage.bExplosiveDamage = true;
	Template.AddMultiTargetEffect(WeaponDamage);

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');      //  ability is activated by effect detecting movement in range of mine

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_grenade_proximitymine";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;
	Template.bUseAmmoAsChargesForHUD = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

	Template.FrameAbilityCameraType = eCameraFraming_Never;
  Template.ConcealmentRule = eConceal_Never;

	Template.ActivationSpeech = 'Explosion';
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = DetonateGrenade_BuildVisualization;
	//  cannot interrupt this explosion

	return Template;
}

function DetonateGrenade_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext_Ability AbilityContext;
	local int ShooterID, ShooterTrackIdx, LoopIdx;
	local VisualizationTrack VisTrack;
	local X2Action_PlayEffect EffectAction;
	local X2Action_SendInterTrackMessage MessageAction;
	local X2Action_WaitForAbilityEffect WaitAction;
	local X2Action_CameraLookAt LookAtAction;
	local X2Action_Delay DelayAction;
	local X2Action_StartStopSound SoundAction;

	ShooterTrackIdx = INDEX_NONE;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	ShooterID = AbilityContext.InputContext.SourceObject.ObjectID;
	TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);

	//Find and grab the "shooter" track - the unit who threw the proximity mine initially
	for (LoopIdx = 0; LoopIdx < OutVisualizationTracks.Length; ++LoopIdx)
	{
		VisTrack = OutVisualizationTracks[LoopIdx];
		if (ShooterID == VisTrack.StateObject_NewState.ObjectID)
		{
			ShooterTrackIdx = LoopIdx;
			break;
		}
	}
	`assert(ShooterTrackIdx != INDEX_NONE);

	//Clear the track and use it for the camera and detonation
	OutVisualizationTracks[ShooterTrackIdx].TrackActions.Length = 0;

	//Camera comes first
	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.CreateVisualizationAction(AbilityContext));
	LookAtAction.LookAtLocation = AbilityContext.InputContext.TargetLocations[0];
	LookAtAction.BlockUntilFinished = true;
	LookAtAction.LookAtDuration = 2.0f;
	OutVisualizationTracks[ShooterTrackIdx].TrackActions.AddItem(LookAtAction);
	
	//Do the detonation
	/* EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.CreateVisualizationAction(AbilityContext)); */
	/* EffectAction.EffectName = default.DetonateGrenadeExplosion; */
	/* EffectAction.EffectLocation = AbilityContext.InputContext.TargetLocations[0]; */
	/* EffectAction.EffectRotation = Rotator(vect(0, 0, 1)); */
	/* EffectAction.bWaitForCompletion = false; */
	/* EffectAction.bWaitForCameraCompletion = false; */
	/* OutVisualizationTracks[ShooterTrackIdx].TrackActions.AddItem(EffectAction); */

	/* SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.CreateVisualizationAction(AbilityContext)); */
	/* SoundAction.Sound = new class'SoundCue'; */
	/* SoundAction.Sound.AkEventOverride = AkEvent'SoundX2CharacterFX.Proximity_Mine_Explosion'; */
	/* SoundAction.bIsPositional = true; */
	/* SoundAction.vWorldPosition = AbilityContext.InputContext.TargetLocations[0]; */
	/* OutVisualizationTracks[ShooterTrackIdx].TrackActions.AddItem(SoundAction); */

	//Make everyone else wait for the detonation
	for (LoopIdx = 0; LoopIdx < OutVisualizationTracks.Length; ++LoopIdx)
	{
		if (LoopIdx == ShooterTrackIdx)
			continue;

		WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.CreateVisualizationAction(AbilityContext));
		OutVisualizationTracks[LoopIdx].TrackActions.InsertItem(0, WaitAction);

		MessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.CreateVisualizationAction(AbilityContext));
		MessageAction.SendTrackMessageToRef = OutVisualizationTracks[LoopIdx].StateObject_NewState.GetReference();
		OutVisualizationTracks[ShooterTrackIdx].TrackActions.AddItem(MessageAction);
	}
	
	//Keep the camera there after things blow up
	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.CreateVisualizationAction(AbilityContext));
	DelayAction.Duration = 0.5;
	OutVisualizationTracks[ShooterTrackIdx].TrackActions.AddItem(DelayAction);

}

//  Special handling for proximity mine damage as they do not deal damage until they explode and therefore don't have damage effects for throw/launch
function bool GrenadeDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local XComGameState_Item ItemState;
	local X2GrenadeTemplate GrenadeTemplate;
	local XComGameState_Ability DetonationAbility;
	local XComGameState_Unit SourceUnit;
	local XComGameStateHistory History;
	local StateObjectReference AbilityRef;

	ItemState = AbilityState.GetSourceAmmo();
	if (ItemState == none)
		ItemState = AbilityState.GetSourceWeapon();

	if (ItemState == none)
		return false;

	GrenadeTemplate = X2GrenadeTemplate(ItemState.GetMyTemplate());
	if (GrenadeTemplate == none)
		return false;

	if (GrenadeTemplate.DataName != 'ProximityMine')
		return false;

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	AbilityRef = SourceUnit.FindAbility(default.DetonateGrenadeAbilityName);
	DetonationAbility = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (DetonationAbility == none)
		return false;

	DetonationAbility.GetDamagePreview(TargetRef, MinDamagePreview, MaxDamagePreview, AllowsShield);
	return true;
}

DefaultProperties
{
	DetonateGrenadeAbilityName = "SUT_DetonateGrenade"
}
