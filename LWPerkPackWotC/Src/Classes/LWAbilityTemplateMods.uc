//---------------------------------------------------------------------------------------
//  FILE:    LWAbilityTemplateMods (adapted from LWTemplateMods)
//  AUTHOR:  tracktwo / Pavonis Interactive
//
//  PURPOSE: Mods to base XCOM2 templates
//---------------------------------------------------------------------------------------

//`include(LW_Overhaul\Src\LW_Overhaul.uci)

class LWAbilityTemplateMods extends X2StrategyElement config(LW_SoldierSkills);

var config int HAIL_OF_BULLETS_AMMO_COST;
var config int SATURATION_FIRE_AMMO_COST;
var config int DEMOLITION_AMMO_COST;
var config int THROW_GRENADE_COOLDOWN;
var config int AID_PROTOCOL_COOLDOWN;
var config int FUSE_COOLDOWN;
var config int INSANITY_MIND_CONTROL_DURATION;
var config bool INSANITY_ENDS_TURN;
var config int RUPTURE_CRIT_BONUS;
var config int FACEOFF_CHARGES;
var config int CONCEAL_ACTION_POINTS;
var config bool CONCEAL_ENDS_TURN;
var config int SERIAL_CRIT_MALUS_PER_KILL;
var config int SERIAL_AIM_MALUS_PER_KILL;
var config bool SERIAL_DAMAGE_FALLOFF;

var config array<Name> DoubleTapAbilities;

static function array<X2DataTemplate> CreateTemplates()
{
  local array<X2DataTemplate> Templates;

  //Vanilla Perks that need adjustment
  Templates.AddItem(CreateModifyAbilitiesGeneralTemplate());
  return Templates;
}

// various small changes to vanilla abilities
static function X2LWTemplateModTemplate CreateModifyAbilitiesGeneralTemplate()
{
  local X2LWTemplateModTemplate Template;

  `CREATE_X2TEMPLATE(class'X2LWTemplateModTemplate', Template, 'ModifyAbilitiesGeneral');
  Template.AbilityTemplateModFn = ModifyAbilitiesGeneral;
  return Template;
}

function ModifyAbilitiesGeneral(X2AbilityTemplate Template, int Difficulty)
{
  local X2Condition_UnitEffects			UnitEffects;
  local X2AbilityToHitCalc_StandardAim	StandardAim;
  local X2AbilityCharges_RevivalProtocol	RPCharges;
  local X2Condition_UnitInventory			InventoryCondition, InventoryCondition2;
  local X2Condition_UnitEffects			SuppressedCondition, UnitEffectsCondition, NotHaywiredCondition;
  local int								k;
  local X2AbilityCost_Ammo				AmmoCost;
  local X2AbilityCost_ActionPoints		ActionPointCost;
  local X2EFfect_HuntersInstinctDamage_LW	DamageModifier;
  local X2AbilityCooldown					Cooldown;
  local X2AbilityCost_QuickdrawActionPoints_LW	QuickdrawActionPointCost;
  local X2Effect_Squadsight				Squadsight;
  local X2Effect_ToHitModifier			ToHitModifier;
  local X2Effect_Persistent				PersistentEffect, HaywiredEffect;
  local X2Effect_VolatileMix				MixEffect;
  local X2Effect_ModifyReactionFire		ReactionFire;
  local X2Effect_HunkerDown_LW			HunkerDownEffect;
  local X2Effect_CancelLongRangePenalty	DFAEffect;
  local X2Condition_Visibility			TargetVisibilityCondition;
  local X2Condition_UnitProperty			UnitPropertyCondition;
  //local X2AbilityTarget_Single			PrimaryTarget;
  //local X2AbilityMultiTarget_Radius		RadiusMultiTarget;
  local X2Effect_SerialCritReduction		SerialCritReduction;
  local X2AbilityCharges					Charges;
  local X2AbilityCost_Charges				ChargeCost;
  //local X2Effect_SoulSteal_LW			StealEffect;
  local X2Effect_Guardian_LW				GuardianEffect;
  local X2Effect							ShotEffect;
  local X2Effect_MaybeApplyDirectionalWorldDamage WorldDamage;
  local X2Effect_DeathFromAbove_LW		DeathEffect;
  local X2Effect_ApplyWeaponDamage		WeaponDamageEffect;

  if (Template.DataName == 'HailofBullets')
  {
    InventoryCondition = new class'X2Condition_UnitInventory';
    InventoryCondition.RelevantSlot=eInvSlot_PrimaryWeapon;
    InventoryCondition.ExcludeWeaponCategory = 'shotgun';
    Template.AbilityShooterConditions.AddItem(InventoryCondition);

    InventoryCondition2 = new class'X2Condition_UnitInventory';
    InventoryCondition2.RelevantSlot=eInvSlot_PrimaryWeapon;
    InventoryCondition2.ExcludeWeaponCategory = 'sniper_rifle';
    Template.AbilityShooterConditions.AddItem(InventoryCondition2);

    for (k = 0; k < Template.AbilityCosts.length; k++)
    {
      AmmoCost = X2AbilityCost_Ammo(Template.AbilityCosts[k]);
      if (AmmoCost != none)
      {
        X2AbilityCost_Ammo(Template.AbilityCosts[k]).iAmmo = default.HAIL_OF_BULLETS_AMMO_COST;
      }
    }
  }

  if (Template.DataName == 'Demolition')
  {
    for (k = 0; k < Template.AbilityCosts.length; k++)
    {
      AmmoCost = X2AbilityCost_Ammo(Template.AbilityCosts[k]);
      if (AmmoCost != none)
      {
        X2AbilityCost_Ammo(Template.AbilityCosts[k]).iAmmo = default.DEMOLITION_AMMO_COST;
      }
    }
  }

  if (Template.DataName == 'InTheZone')
  {
    SerialCritReduction = new class 'X2Effect_SerialCritReduction';
    SerialCritReduction.BuildPersistentEffect(1, false, true, false, 8);
    SerialCritReduction.CritReductionPerKill = default.SERIAL_CRIT_MALUS_PER_KILL;
    SerialCritReduction.AimReductionPerKill = default.SERIAL_AIM_MALUS_PER_KILL;
    SerialCritReduction.Damage_Falloff = default.SERIAL_DAMAGE_FALLOFF;
    SerialCritReduction.SetDisplayInfo (ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,, Template.AbilitySourceName);
    Template.AddTargetEffect(SerialCritReduction);
  }

  // Use alternate DFA effect so it's compatible with Double Tap 2, and add additional ability of canceling long-range sniper rifle penalty
  if (Template.DataName == 'DeathFromAbove')
  {
    Template.AbilityTargetEffects.Length = 0;
    DFAEffect = New class'X2Effect_CancelLongRangePenalty';
    DFAEffect.BuildPersistentEffect (1, true, false);
    DFAEffect.SetDisplayInfo (0, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, false,, Template.AbilitySourceName);
    Template.AddTargetEffect(DFAEffect);
    DeathEffect = new class'X2Effect_DeathFromAbove_LW';
    DeathEffect.BuildPersistentEffect(1, true, false, false);
    DeathEffect.SetDisplayInfo(0, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
    Template.AddTargetEffect(DeathEffect);
  }

  if (Template.DataName == 'Insanity')
  {
    for (k = 0; k < Template.AbilityTargetEffects.length; k++)
    {
      if (Template.AbilityTargetEffects[k].IsA ('X2Effect_MindControl'))
      {
        X2Effect_MindControl(Template.AbilityTargetEffects[k]).iNumTurns = default.INSANITY_MIND_CONTROL_DURATION;
      }
    }
    for (k = 0; k < Template.AbilityCosts.length; k++)
    {
      ActionPointCost = X2AbilityCost_ActionPoints(Template.AbilityCosts[k]);
      if (ActionPointCost != none)
      {
        X2AbilityCost_ActionPoints(Template.AbilityCosts[k]).bConsumeAllPoints = default.INSANITY_ENDS_TURN;
      }
    }
  }

  if (Template.DataName == 'Fuse')
  {
    Template.PrerequisiteAbilities.AddItem ('Fortress');
  }

  if (Template.DataName == 'StasisShield')
  {
    Template.PrerequisiteAbilities.AddItem ('Fortress');
  }

  if (Template.DataName == 'Domination')
  {
    Template.PrerequisiteAbilities.AddItem ('Solace_LW');
    Template.PrerequisiteAbilities.AddItem ('Stasis');
  }

  if (Template.DataName == 'VoidRift')
  {
    Template.PrerequisiteAbilities.AddItem ('Fortress');
    Template.PrerequisiteAbilities.AddItem ('Solace_LW');
  }

  if (Template.DataName == 'NullLance')
  {
    Template.PrerequisiteAbilities.AddItem ('Stasis');
  }

  // should allow covering fire at micromissiles and ADVENT rockets
  if (Template.DataName == 'MicroMissiles' || Template.DataName == 'RocketLauncher')
  {
    Template.BuildInterruptGameStateFn = class'X2Ability'.static.TypicalAbility_BuildInterruptGameState;
  }

  if (Template.DataName == 'Stealth' && default.CONCEAL_ACTION_POINTS > 0)
  {
    for (k = 0; k < Template.AbilityCosts.length; k++)
    {
      ActionPointCost = X2AbilityCost_ActionPoints(Template.AbilityCosts[k]);
      if (ActionPointCost != none)
      {
        X2AbilityCost_ActionPoints(Template.AbilityCosts[k]).iNumPoints = default.CONCEAL_ACTION_POINTS;
        X2AbilityCost_ActionPoints(Template.AbilityCosts[k]).bConsumeAllPoints = default.CONCEAL_ENDS_TURN;
        X2AbilityCost_ActionPoints(Template.AbilityCosts[k]).bFreeCost = false;
      }
    }
  }

  // bugfix for Flashbangs doing damage
  if (Template.DataName == 'HuntersInstinct')
  {
    Template.AbilityTargetEffects.length = 0;
    DamageModifier = new class'X2Effect_HuntersInstinctDamage_LW';
    DamageModifier.BonusDamage = class'X2Ability_RangerAbilitySet'.default.INSTINCT_DMG;
    DamageModifier.BonusCritChance = class'X2Ability_RangerAbilitySet'.default.INSTINCT_CRIT;
    DamageModifier.BuildPersistentEffect(1, true, false, true);
    DamageModifier.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,, Template.AbilitySourceName);
    Template.AddTargetEffect(DamageModifier);
  }

  // bugfix for several vanilla perks being lost after bleeding out/revive
  if (Template.DataName == 'Squadsight')
  {
    Template.AbilityTargetEffects.length = 0;
    Squadsight = new class'X2Effect_Squadsight';
    Squadsight.BuildPersistentEffect(1, true, false, true);
    Squadsight.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,, Template.AbilitySourceName);
    Template.AddTargetEffect(Squadsight);
  }

  if (Template.DataName == 'HitWhereItHurts')
  {
    Template.AbilityTargetEffects.length = 0;
    ToHitModifier = new class'X2Effect_ToHitModifier';
    ToHitModifier.BuildPersistentEffect(1, true, false, true);
    ToHitModifier.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,, Template.AbilitySourceName);
    ToHitModifier.AddEffectHitModifier(1, class'X2Ability_SharpshooterAbilitySet'.default.HITWHEREITHURTS_CRIT, Template.LocFriendlyName,, false, true, true, true);
    Template.AddTargetEffect(ToHitModifier);
  }

  if (Template.DataName == 'HoloTargeting')
  {
    Template.AbilityTargetEffects.length = 0;
    PersistentEffect = new class'X2Effect_Persistent';
    PersistentEffect.BuildPersistentEffect(1, true, false);
    PersistentEffect.SetDisplayInfo(0, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
    Template.AddTargetEffect(PersistentEffect);
  }

  if (Template.DataName == 'VolatileMix')
  {
    Template.AbilityTargetEffects.length = 0;
    MixEffect = new class'X2Effect_VolatileMix';
    MixEffect.BuildPersistentEffect(1, true, false, true);
    MixEffect.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,, Template.AbilitySourceName);
    MixEffect.BonusDamage = class'X2Ability_GrenadierAbilitySet'.default.VOLATILE_DAMAGE;
    Template.AddTargetEffect(MixEffect);
  }

  if (Template.DataName == 'CoolUnderPressure')
  {
    Template.AbilityTargetEffects.length = 0;
    ReactionFire = new class'X2Effect_ModifyReactionFire';
    ReactionFire.bAllowCrit = true;
    ReactionFire.ReactionModifier = class'X2Ability_SpecialistAbilitySet'.default.UNDER_PRESSURE_BONUS;
    ReactionFire.BuildPersistentEffect(1, true, false, true);
    ReactionFire.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,, Template.AbilitySourceName);
    Template.AddTargetEffect(ReactionFire);
  }

  if (Template.DataName == 'BulletShred')
  {
    StandardAim = new class'X2AbilityToHitCalc_StandardAim';
    StandardAim.bHitsAreCrits = false;
    StandardAim.BuiltInCritMod = default.RUPTURE_CRIT_BONUS;
    Template.AbilityToHitCalc = StandardAim;
    Template.AbilityToHitOwnerOnMissCalc = StandardAim;

    for (k = 0; k < Template.AbilityTargetConditions.Length; k++)
    {
      TargetVisibilityCondition = X2Condition_Visibility(Template.AbilityTargetConditions[k]);
      if (TargetVisibilityCondition != none)
      {
        // Allow rupture to work from SS
        TargetVisibilityCondition = new class'X2Condition_Visibility';
        TargetVisibilityCondition.bRequireGameplayVisible  = true;
        TargetVisibilityCondition.bAllowSquadsight = true;
        Template.AbilityTargetConditions[k] = TargetVisibilityCondition;
      }
    }
  }

  // Bump up skulljack damage, the default 20 will fail to kill advanced units
  // and glitches out the animations.
  if (Template.DataName == 'FinalizeSKULLJACK')
  {
    for (k = 0; k < Template.AbilityTargetEffects.Length; ++k)
    {
      WeaponDamageEffect = X2Effect_ApplyWeaponDamage(Template.AbilityTargetEffects[k]);
      if (WeaponDamageEffect != none)
      {
        WeaponDamageEffect.EffectDamageValue.Pierce = 99;
        WeaponDamageEffect.EffectDamageValue.Damage = 99;
      }
    }
  }

  // Removes Threat Assessment increase
  if (Template.DataName == 'AidProtocol')
  {
    Cooldown = new class'X2AbilityCooldown';
    Cooldown.iNumTurns = default.AID_PROTOCOL_COOLDOWN;
    Template.AbilityCooldown = Cooldown;
  }

  if (Template.DataName == 'KillZone' || Template.DataName == 'Deadeye' || Template.DataName == 'BulletShred')
  {
    for (k = 0; k < Template.AbilityCosts.length; k++)
    {
      ActionPointCost = X2AbilityCost_ActionPoints(Template.AbilityCosts[k]);
      if (ActionPointCost != none)
      {
        X2AbilityCost_ActionPoints(Template.AbilityCosts[k]).iNumPoints = 0;
        X2AbilityCost_ActionPoints(Template.AbilityCosts[k]).bAddWeaponTypicalCost = true;
      }
    }
  }

  // lets RP gain charges from gremlin tech
  if (Template.DataName == 'RevivalProtocol')
  {
    RPCharges = new class 'X2AbilityCharges_RevivalProtocol';
    RPCharges.InitialCharges = class'X2Ability_SpecialistAbilitySet'.default.REVIVAL_PROTOCOL_CHARGES;
    Template.AbilityCharges = RPCharges;
  }

  // adds config to ammo cost and fixes vanilla bug in which
  if (Template.DataName == 'SaturationFire')
  {
    for (k = 0; k < Template.AbilityCosts.length; k++)
    {
      AmmoCost = X2AbilityCost_Ammo(Template.AbilityCosts[k]);
      if (AmmoCost != none)
      {
        X2AbilityCost_Ammo(Template.AbilityCosts[k]).iAmmo = default.SATURATION_FIRE_AMMO_COST;
      }
    }
    Template.AbilityMultiTargetEffects.length = 0;
    Template.AddMultiTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
    WorldDamage = new class'X2Effect_MaybeApplyDirectionalWorldDamage';
    WorldDamage.bUseWeaponDamageType = true;
    WorldDamage.bUseWeaponEnvironmentalDamage = false;
    WorldDamage.EnvironmentalDamageAmount = 30;
    WorldDamage.bApplyOnHit = true;
    WorldDamage.bApplyOnMiss = true;
    WorldDamage.bApplyToWorldOnHit = true;
    WorldDamage.bApplyToWorldOnMiss = true;
    WorldDamage.bHitAdjacentDestructibles = true;
    WorldDamage.PlusNumZTiles = 1;
    WorldDamage.bHitTargetTile = true;
    WorldDamage.ApplyChance = class'X2Ability_GrenadierAbilitySet'.default.SATURATION_DESTRUCTION_CHANCE;
    Template.AddMultiTargetEffect(WorldDamage);
  }

  // can't shoot when on FIRE

  if (class'X2Ability_PerkPackAbilitySet'.default.NO_STANDARD_ATTACKS_WHEN_ON_FIRE)
  {
    switch (Template.DataName)
    {
      case 'StandardShot':
      case 'PistolStandardShot':
      case 'SniperStandardFire':
      case 'Shadowfall':
        // Light Em Up and Snap Shot are handled in the template
        UnitEffects = new class'X2Condition_UnitEffects';
        UnitEffects.AddExcludeEffect(class'X2StatusEffects'.default.BurningName, 'AA_UnitIsBurning');
        Template.AbilityShooterConditions.AddItem(UnitEffects);
        break;
      default:
        break;
    }
  }
  if (class'X2Ability_PerkPackAbilitySet'.default.NO_MELEE_ATTACKS_WHEN_ON_FIRE)
  {
    if (Template.IsMelee())
    {
      UnitEffects = new class'X2Condition_UnitEffects';
      UnitEffects.AddExcludeEffect(class'X2StatusEffects'.default.BurningName, 'AA_UnitIsBurning');
      Template.AbilityShooterConditions.AddItem(UnitEffects);
    }
  }

  // centralizing suppression rules. first batch is new vanilla abilities restricted by suppress.
  // second batch is abilities affected by vanilla suppression that need area suppression change
  // Third batch are vanilla abilities that need suppression limits AND general shooter effect exclusions
  // Mod abilities have restrictions in template defintions
  switch (Template.DataName)
  {
    case 'ThrowGrenade':
    case 'LaunchGrenade':
    case 'MicroMissiles':
    case 'RocketLauncher':
    case 'PoisonSpit':
    case 'GetOverHere':
    case 'Bind':
    case 'AcidBlob':
    case 'BlazingPinionsStage1':
    case 'HailOfBullets':
    case 'SaturationFire':
    case 'Demolition':
    case 'PlasmaBlaster':
    case 'ShredderGun':
    case 'ShredstormCannon':
    case 'BladestormAttack':
    case 'Grapple':
    case 'GrapplePowered':
    case 'IntheZone':
    case 'Reaper':
    case 'Suppression':
      SuppressedCondition = new class'X2Condition_UnitEffects';
      SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
      SuppressedCondition.AddExcludeEffect(class'X2Effect_AreaSuppression'.default.EffectName, 'AA_UnitIsSuppressed');
      Template.AbilityShooterConditions.AddItem(SuppressedCondition);
      break;
    case 'Overwatch':
    case 'PistolOverwatch':
    case 'SniperRifleOverwatch':
    case 'LongWatch':
    case 'Killzone':
      SuppressedCondition = new class'X2Condition_UnitEffects';
      SuppressedCondition.AddExcludeEffect(class'X2Effect_AreaSuppression'.default.EffectName, 'AA_UnitIsSuppressed');
      Template.AbilityShooterConditions.AddItem(SuppressedCondition);
      break;
    case 'MarkTarget':
    case 'EnergyShield':
    case 'EnergyShieldMk3':
    case 'BulletShred':
    case 'Stealth':
      Template.AddShooterEffectExclusions();
      SuppressedCondition = new class'X2Condition_UnitEffects';
      SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
      SuppressedCondition.AddExcludeEffect(class'X2Effect_AreaSuppression'.default.EffectName, 'AA_UnitIsSuppressed');
      Template.AbilityShooterConditions.AddItem(SuppressedCondition);
      break;
    default:
      break;
  }

  if (Template.DataName == 'Shadowfall')
  {
    StandardAim = X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc);
    if (StandardAim != none)
    {
      StandardAim.bGuaranteedHit = false;
      StandardAim.bAllowCrit = true;
      Template.AbilityToHitCalc = StandardAim;
      Template.AbilityToHitOwnerOnMissCalc = StandardAim;
    }
  }

  if (Template.DataName == class'X2Ability_Viper'.default.BindAbilityName)
  {
    SuppressedCondition = new class'X2Condition_UnitEffects';
    SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
    SuppressedCondition.AddExcludeEffect(class'X2Effect_AreaSuppression'.default.EffectName, 'AA_UnitIsSuppressed');
    SuppressedCondition.AddExcludeEffect(class'X2AbilityTemplateManager'.default.StunnedName, 'AA_UnitIsStunned');
    Template.AbilityTargetConditions.AddItem(SuppressedCondition);
  }

  if (Template.DataName == 'Mindspin' || Template.DataName == 'Domination' || Template.DataName == class'X2Ability_PsiWitch'.default.MindControlAbilityName)
  {
    UnitEffectsCondition = new class'X2Condition_UnitEffects';
    UnitEffectsCondition.AddExcludeEffect(class'X2AbilityTemplateManager'.default.StunnedName, 'AA_UnitIsStunned');
    Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);
  }

  if (Template.DataName == 'ThrowGrenade')
  {
    Cooldown = new class'X2AbilityCooldown_AllInstances';
    Cooldown.iNumTurns = default.THROW_GRENADE_COOLDOWN;
    Template.AbilityCooldown = Cooldown;
    X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc).bGuaranteedHit = true;
  }

  if (Template.DataName == 'PistolStandardShot')
  {
    Template.AbilityCosts.length = 0;
    QuickdrawActionPointCost = new class'X2AbilityCost_QuickdrawActionPoints_LW';
    QuickdrawActionPointCost.iNumPoints = 1;
    QuickdrawActionPointCost.bConsumeAllPoints = true;
    Template.AbilityCosts.AddItem(QuickdrawActionPointCost);
    AmmoCost = new class'X2AbilityCost_Ammo';
    AmmoCost.iAmmo = 1;
    Template.AbilityCosts.AddItem(AmmoCost);
  }

  if (Template.DataName == 'Faceoff')
  {
    //Template.AbilityCooldown = none;
    if (default.FACEOFF_CHARGES > 0)
    {
      Charges = new class'X2AbilityCharges';
      Charges.InitialCharges = default.FACEOFF_CHARGES;
      Template.AbilityCharges = Charges;
      ChargeCost = new class'X2AbilityCost_Charges';
      ChargeCost.NumCharges = 1;
      Template.AbilityCosts.AddItem(ChargeCost);
    }
    UnitPropertyCondition=new class'X2Condition_UnitProperty';
    UnitPropertyCondition.ExcludeConcealed = true;
    Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);
  }

  if (Template.DataName == 'HunkerDown')
  {
    Template.AbilityTargetEffects.length = 0;
    HunkerDownEffect = new class 'X2Effect_HunkerDown_LW';
    HunkerDownEffect.EffectName = 'HunkerDown';
    HunkerDownEffect.DuplicateResponse = eDupe_Refresh;
    HunkerDownEFfect.BuildPersistentEffect (1,,,, 7);
    HunkerDownEffect.SetDisplayInfo (ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage);
    Template.AddTargetEffect(HunkerDownEffect);
    Template.AddTargetEffect(class'X2Ability_SharpshooterAbilitySet'.static.SharpshooterAimEffect());
  }

  if (Template.DataName == 'Fuse' && default.FUSE_COOLDOWN > 0)
  {
    Cooldown = new class 'X2AbilityCooldown';
    Cooldown.iNumTurns = default.FUSE_COOLDOWN;
    Template.AbilityCooldown = Cooldown;
  }

  // Sets to one shot per target a turn
  if (Template.DataName == 'Sentinel')
  {
    Template.AbilityTargetEffects.length = 0;
    GuardianEffect = new class'X2Effect_Guardian_LW';
    GuardianEffect.BuildPersistentEffect(1, true, false);
    GuardianEffect.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,, Template.AbilitySourceName);
    GuardianEffect.ProcChance = class'X2Ability_SpecialistAbilitySet'.default.GUARDIAN_PROC;
    Template.AddTargetEffect(GuardianEffect);
  }

  // Adds shieldHP bonus
  if (Template.DataName == 'SoulSteal')
  {
    Template.AdditionalAbilities.AddItem('SoulStealTriggered2');
  }

  // When completeing a control robot hack remove any previous disorient effects as is done for dominate.
  if (Template.DataName == 'HackRewardControlRobot' || Template.DataName == 'HackRewardControlRobotWithStatBoost')
  {
    `Log("Adding disorient removal to " $ Template.DataName);
    Template.AddTargetEffect(class'X2StatusEffects'.static.CreateMindControlRemoveEffects());
    Template.AddTargetEffect(class'X2StatusEffects'.static.CreateStunRecoverEffect());
  }

  if (Template.DataName == 'FinalizeHaywire')
  {
    HaywiredEffect = new class'X2Effect_Persistent';
    HaywiredEffect.EffectName = 'Haywired';
    HaywiredEffect.BuildPersistentEffect(1, true, false);
    HaywiredEffect.bDisplayInUI = false;
    HaywiredEffect.bApplyOnMiss = true;
    Template.AddTargetEffect(HaywiredEffect);
  }

  if (Template.DataName == 'HaywireProtocol')
  {
    NotHaywiredCondition = new class 'X2Condition_UnitEffects';
    NotHaywiredCondition.AddExcludeEffect ('Haywired', 'AA_NoTargets');
    Template.AbilityTargetConditions.AddItem(NotHaywiredCondition);
  }

  switch (Template.DataName)
  {
    case 'OverwatchShot':
    case 'LongWatchShot':
    case 'GunslingerShot':
    case 'KillZoneShot':
    case 'PistolOverwatchShot':
    case 'SuppressionShot_LW':
    case 'SuppressionShot':
    case 'AreaSuppressionShot_LW':
    case 'CloseCombatSpecialistAttack':
      ShotEffect = class'X2Ability_PerkPackAbilitySet'.static.CoveringFireMalusEffect();
      ShotEffect.TargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());
      Template.AddTargetEffect(ShotEffect);
  }

  if (DoubleTapAbilities.Find(Template.DataName) >= 0)
  {
    `LOG ("Adding Double Tap to" @ Template.DataName);
    AddDoubleTapActionPoint (Template, class'X2Ability_LW_SharpshooterAbilitySet'.default.DoubleTapActionPoint);
  }
}

function AddDoubleTapActionPoint(X2AbilityTemplate Template, Name ActionPointName)
{
  local X2AbilityCost_ActionPoints        ActionPointCost;
  local X2AbilityCost                     Cost;

  foreach Template.AbilityCosts(Cost)
  {
    ActionPointCost = X2AbilityCost_ActionPoints(Cost);
    if (ActionPointCost != none)
    {
      ActionPointCost.AllowedTypes.AddItem(ActionPointName);
    }
  }
}
