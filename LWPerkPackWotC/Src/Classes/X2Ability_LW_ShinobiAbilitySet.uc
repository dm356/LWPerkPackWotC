//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_LW_ShinobiAbilitySet.uc
//  AUTHOR:  Amineri (Pavonis Interactive)
//  PURPOSE: Defines all Long War Shinobi-specific abilities
//---------------------------------------------------------------------------------------

class X2Ability_LW_ShinobiAbilitySet extends X2Ability
	dependson (XComGameStateContext_Ability) config(LW_SoldierSkills);

var config int WHIRLWIND_COOLDOWN;
var config int COUP_DE_GRACE_COOLDOWN;
var config int COUP_DE_GRACE_DISORIENTED_CHANCE;
var config int COUP_DE_GRACE_STUNNED_CHANCE;
var config int COUP_DE_GRACE_UNCONSCIOUS_CHANCE;
var config int TARGET_DAMAGE_CHANCE_MULTIPLIER;

var config int COUP_DE_GRACE_2_HIT_BONUS;
var config int COUP_DE_GRACE_2_CRIT_BONUS;
var config int COUP_DE_GRACE_2_DAMAGE_BONUS;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AddWhirlwind());
	Templates.AddItem(AddWhirlwindSlash());
	Templates.AddItem(AddCoupDeGraceAbility());
	Templates.AddItem(AddCoupDeGracePassive());
	Templates.AddItem(AddCoupDeGrace2Ability());
	Templates.AddItem(PurePassive('Tradecraft', "img:///UILibrary_LW_Overhaul.LW_AbilityTradecraft", true));
	Templates.AddItem(AddWhirlwind2());
	return Templates;
}


static function X2AbilityTemplate AddCoupDeGrace2Ability()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_CoupdeGrace2				CoupDeGraceEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CoupDeGrace2');
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_LW_Overhaul.LW_AbilityCoupDeGrace";
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.bDisplayInUITooltip = true;
    Template.bDisplayInUITacticalText = true;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	CoupDeGraceEffect = new class'X2Effect_CoupDeGrace2';
	CoupDeGraceEffect.To_Hit_Modifier=default.COUP_DE_GRACE_2_HIT_BONUS;
	CoupDeGraceEffect.Crit_Modifier=default.COUP_DE_GRACE_2_CRIT_BONUS;
	CoupDeGraceEffect.Damage_Bonus=default.COUP_DE_GRACE_2_DAMAGE_BONUS;
	CoupDeGraceEffect.Half_for_Disoriented=true;
	CoupDeGraceEffect.BuildPersistentEffect (1, true, false);
	CoupDeGraceEffect.SetDisplayInfo (ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(CoupDeGraceEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

//based on Slash_LW and Kubikuri
static function X2AbilityTemplate AddCoupDeGraceAbility()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityToHitCalc_StandardMelee  StandardMelee;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2Condition_UnitProperty			UnitCondition;
	local X2AbilityCooldown                 Cooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CoupDeGrace');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_LW_Overhaul.LW_AbilityCoupDeGrace";
	Template.bHideOnClassUnlock = false;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;
	Template.AbilityConfirmSound = "TacticalUI_SwordConfirm";
	Template.bCrossClassEligible = false;
	Template.bDisplayInUITooltip = true;
    Template.bDisplayInUITacticalText = true;
    Template.DisplayTargetHitChance = true;
	Template.bShowActivation = true;
	Template.bSkipFireAction = false;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	StandardMelee = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityToHitCalc = StandardMelee;

    Template.AbilityTargetStyle = default.SimpleSingleMeleeTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.COUP_DE_GRACE_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);
	UnitCondition = new class'X2Condition_UnitProperty';
	UnitCondition.RequireWithinRange = true;
	UnitCondition.WithinRange = 144; //1.5 tiles in Unreal units, allows attacks on the diag
	UnitCondition.ExcludeRobotic = true;
	Template.AbilityTargetConditions.AddItem(UnitCondition);
	Template.AbilityTargetConditions.AddItem(new class'X2Condition_CoupDeGrace'); // add condition that requires target to be disoriented, stunned or unconscious

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Damage Effect
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	Template.AddTargetEffect(WeaponDamageEffect);
	Template.bAllowBonusWeaponEffects = true;

	// VGamepliz matters

	Template.ActivationSpeech = 'CoupDeGrace';
	Template.SourceMissSpeech = 'SwordMiss';

	Template.AdditionalAbilities.AddItem('CoupDeGracePassive');

	Template.CinescriptCameraType = "Ranger_Reaper";
    Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate AddCoupDeGracePassive()
{
	local X2AbilityTemplate						Template;
	local X2Effect_CoupDeGrace				CoupDeGraceEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CoupDeGracePassive');
	Template.IconImage = "img:///UILibrary_LW_Overhaul.LW_AbilityCoupDeGrace";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	//Template.bIsPassive = true;

	// Coup de Grace effect
	CoupDeGraceEffect = new class'X2Effect_CoupDeGrace';
	CoupDeGraceEffect.DisorientedChance = default.COUP_DE_GRACE_DISORIENTED_CHANCE;
	CoupDeGraceEffect.StunnedChance = default.COUP_DE_GRACE_STUNNED_CHANCE;
	CoupDeGraceEffect.UnconsciousChance = default.COUP_DE_GRACE_UNCONSCIOUS_CHANCE;
	CoupDeGraceEffect.TargetDamageChanceMultiplier = default.TARGET_DAMAGE_CHANCE_MULTIPLIER;
	CoupDeGraceEffect.BuildPersistentEffect (1, true, false);
	Template.AddTargetEffect(CoupDeGraceEffect);

	Template.bCrossClassEligible = false;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate AddWhirlwind2()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_Whirlwind2				WhirlwindEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Whirlwind2');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_riposte";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	WhirlwindEffect = new class'X2Effect_Whirlwind2';
    WhirlwindEffect.BuildPersistentEffect(1, true, false, false);
    WhirlwindEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,, Template.AbilitySourceName);
    WhirlwindEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(WhirlwindEffect);

	Template.bCrossClassEligible = false;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// No visualization function

	return Template;
}


//Based on Implacable and Bladestorm
//whirlwind is deprecated ability (couldn't get visualization to work)
// gamestate code works, but visualization is glitchy-looking
static function X2AbilityTemplate AddWhirlwind()
{

	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local array<name>                       SkipExclusions;
	local X2AbilityCooldown					Cooldown;
	local X2Effect_Whirlwind				WhirlwindEffect;

	// Macro to do localisation and stuffs
	`CREATE_X2ABILITY_TEMPLATE(Template, 'Whirlwind');

	// Icon Properties
	Template.IconImage = "img:///UILibrary_LW_PerkPack.LW_AbilityWhirlwind";
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_PISTOL_SHOT_PRIORITY;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.bCrossClassEligible = false;

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.WHIRLWIND_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	// *** VALIDITY CHECKS *** //
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Action Point -- requires all points to activate -- refunds a move action in the effect
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1; // requires a full action
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	WhirlwindEffect = new class 'X2Effect_Whirlwind';
	WhirlwindEffect.BuildPersistentEffect (1, false, true);
	WhirlwindEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (WhirlwindEffect);

	Template.AdditionalAbilities.AddItem('WhirlwindSlash');

	// MAKE IT LIVE!
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
  //Template.BuildVisualizationFn = Whirlwind_BuildVisualization;

	return Template;
}

// this is the free attack action, only triggerable by the listener set up by Whirlwind
//whirlwind was deprecated because we couldn't get a visualization to work
static function X2AbilityTemplate AddWhirlwindSlash()
{
	local X2AbilityTemplate                 Template;
	local array<name>                       SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'WhirlwindSlash');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_LW_PerkPack.LW_AbilityWhirlwind";
	Template.CinescriptCameraType = "Ranger_Reaper";

	//free standard damage melee attack
	Template.AbilityCosts.AddItem(default.FreeActionCost);
	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityTargetStyle = default.SimpleSingleMeleeTarget;

	//Triggered by persistent effect from Whirlwind only
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);

	// Shooter Conditions -- re-add these in case something gets applied via reaction
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Damage Effect
	Template.AddTargetEffect(new class'X2Effect_ApplyWeaponDamage');

	Template.bAllowBonusWeaponEffects = true;
	//Template.bSkipMoveStop = true;

	// Voice events
	//
	Template.SourceMissSpeech = 'SwordMiss';

	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	//Template.BuildVisualizationFn = WhirlwindSlash_BuildVisualization;

	return Template;
}

