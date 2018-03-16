//---------------------------------------------------------------------------------------
//  FILE:    LWItemTemplateMods (adapted from LWTemplateMods)
//  AUTHOR:  tracktwo / Pavonis Interactive
//
//  PURPOSE: Mods to base XCOM2 templates
//---------------------------------------------------------------------------------------

class LWItemTemplateMods extends X2StrategyElement config(LW_SoldierSkills);

//`include(LW_Overhaul\Src\LW_Overhaul.uci)

struct FlashbangResistEntry
{
  var name UnitName;
  var int Chance;
};

var config array<FlashbangResistEntry> ENEMY_FLASHBANG_RESIST;

static function array<X2DataTemplate> CreateTemplates()
{
  local array<X2DataTemplate> Templates;

  //Update flashbangs
  Templates.AddItem(CreateModifyGrenadeEffects());
  return Templates;
}

static function X2LWTemplateModTemplate CreateModifyGrenadeEffects()
{
  local X2LWTemplateModTemplate Template;

  `CREATE_X2TEMPLATE(class'X2LWTemplateModTemplate', Template, 'ModifyGrenadeEffects');

  // We need to modify grenade items and ability templates
  Template.ItemTemplateModFn = ModifyGrenadeEffects;
  return Template;
}


delegate name ResistFlashbang(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
  local int k;
  local XComGameState_Unit Target;

  Target = XComGameState_Unit(kNewTargetState);
  if (Target != none)
  {
    for (k = 0; k < default.ENEMY_FLASHBANG_RESIST.length; k++)
    {
      if (default.ENEMY_FLASHBANG_RESIST[k].UnitName == Target.GetMyTemplateName())
      {
        if (`SYNC_RAND(100) < default.ENEMY_FLASHBANG_RESIST[k].Chance)
        {
          return 'AA_EffectChanceFailed';
        }
      }
    }
  }
  return 'AA_Success';
}

// Modify grenade effects:
// Flashbangs and sting grenades get blue screen bombs effects (if the ability is
// present).
// Flashbangs, sting grenades, and advent grenadier flashbangs are not valid for
// volatile mix damage bonus (note: this damage bonus was from the original volatile
// mix, the damage bonus is now only applied to boosted cores).

function ModifyGrenadeEffects(X2ItemTemplate Template, int Difficulty)
{
  local X2GrenadeTemplate								GrenadeTemplate;
  local int k;
  local X2Effect_Persistent							Effect;

  GrenadeTemplate = X2GrenadeTemplate(Template);
  if(GrenadeTemplate == none)
    return;
  switch(GrenadeTemplate.DataName)
  {
    case 'FlashbangGrenade':
    case 'StingGrenade':
      GrenadeTemplate.ThrownGrenadeEffects.AddItem(class'X2Ability_LW_GrenadierAbilitySet'.static.CreateBluescreenBombsHackReductionEffect());
      GrenadeTemplate.ThrownGrenadeEffects.AddItem(class'X2Ability_LW_GrenadierAbilitySet'.static.CreateBluescreenBombsDisorientEffect());
      GrenadeTemplate.LaunchedGrenadeEffects.AddItem(class'X2Ability_LW_GrenadierAbilitySet'.static.CreateBluescreenBombsHackReductionEffect());
      GrenadeTemplate.LaunchedGrenadeEffects.AddItem(class'X2Ability_LW_GrenadierAbilitySet'.static.CreateBluescreenBombsDisorientEffect());
      GrenadeTemplate.bAllowVolatileMix = false;

      for (k = 0; k < GrenadeTemplate.ThrownGrenadeEffects.Length; k++)
      {
        Effect = X2Effect_Persistent (GrenadeTemplate.ThrownGrenadeEffects[k]);
        if (Effect != none)
        {
          if (Effect.EffectName == class'X2AbilityTemplateManager'.default.DisorientedName)
          {
            GrenadeTemplate.ThrownGrenadeEffects[k].ApplyChanceFn = ResistFlashbang;
          }
        }
      }
      for (k = 0; k < GrenadeTemplate.LaunchedGrenadeEffects.Length; k++)
      {
        Effect = X2Effect_Persistent (GrenadeTemplate.LaunchedGrenadeEffects[k]);
        if (Effect != none)
        {
          if (Effect.EffectName == class'X2AbilityTemplateManager'.default.DisorientedName)
          {
            GrenadeTemplate.LaunchedGrenadeEffects[k].ApplyChanceFn = ResistFlashbang;
          }
        }
      }
      break;
    case 'AdvGrenadierFlashbangGrenade':
      for (k = 0; k < GrenadeTemplate.ThrownGrenadeEffects.Length; k++)
      {
        Effect = X2Effect_Persistent (GrenadeTemplate.ThrownGrenadeEffects[k]);
        if (Effect != none)
        {
          if (Effect.EffectName == class'X2AbilityTemplateManager'.default.DisorientedName)
          {
            GrenadeTemplate.ThrownGrenadeEffects[k].ApplyChanceFn = ResistFlashbang;
          }
        }
      }
      for (k = 0; k < GrenadeTemplate.LaunchedGrenadeEffects.Length; k++)
      {
        Effect = X2Effect_Persistent (GrenadeTemplate.LaunchedGrenadeEffects[k]);
        if (Effect != none)
        {
          if (Effect.EffectName == class'X2AbilityTemplateManager'.default.DisorientedName)
          {
            GrenadeTemplate.LaunchedGrenadeEffects[k].ApplyChanceFn = ResistFlashbang;
          }
        }
      }
      GrenadeTemplate.bAllowVolatileMix = false;
    default:
      break;
  }
}
