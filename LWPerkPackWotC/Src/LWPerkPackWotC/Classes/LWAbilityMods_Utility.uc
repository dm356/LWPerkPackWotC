//---------------------------------------------------------------------------------------
//  FILE:    LWAbilityMods_Utility (adapted from LWTemplateMods_Utilities)
//  AUTHOR:  tracktwo and Amineri / Pavonis Interactive
//
//  PURPOSE: Early game hook to allow template modifications.
//---------------------------------------------------------------------------------------

class LWAbilityMods_Utility extends Object;

//`include(LW_Overhaul\Src\LW_Overhaul.uci)

static function UpdateTemplates()
{
  local X2StrategyElementTemplateManager		StrategyTemplateMgr;
  local X2AbilityTemplateManager				AbilityTemplateMgr;

  local array<X2StrategyElementTemplate>		TemplateMods;
  local X2LWTemplateModTemplate				ModTemplate;
  local int idx;

  //retrieve all needed template managers
  StrategyTemplateMgr		= class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
  AbilityTemplateMgr		= class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

  TemplateMods = StrategyTemplateMgr.GetAllTemplatesOfClass(class'X2LWTemplateModTemplate');
  for (idx = 0; idx < TemplateMods.Length; ++idx)
  {
    ModTemplate = X2LWTemplateModTemplate(TemplateMods[idx]);
    if (ModTemplate.AbilityTemplateModFn != none)
    {
      `Log("Template Mods: Updating Ability Templates for " $ ModTemplate.DataName);
      PerformAbilityTemplateMod(ModTemplate, AbilityTemplateMgr);
    }
  }
}

static function PerformAbilityTemplateMod(X2LWTemplateModTemplate Template, X2DataTemplateManager TemplateManager)
{
  local X2AbilityTemplate AbilityTemplate;
  local array<Name> TemplateNames;
  local Name TemplateName;
  local array<X2DataTemplate> DataTemplates;
  local X2DataTemplate DataTemplate;
  local int Difficulty;

  TemplateManager.GetTemplateNames(TemplateNames);

  foreach TemplateNames(TemplateName)
  {
    TemplateManager.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    foreach DataTemplates(DataTemplate)
    {
      AbilityTemplate = X2AbilityTemplate(DataTemplate);
      if(AbilityTemplate != none)
      {
        Difficulty = GetDifficultyFromTemplateName(TemplateName);
        Template.AbilityTemplateModFn(AbilityTemplate, Difficulty);
      }
    }
  }
}

//=================================================================================
//================= UTILITY CLASSES ===============================================
//=================================================================================

static function int GetDifficultyFromTemplateName(name TemplateName)
{
  return int(GetRightMost(string(TemplateName)));
}


