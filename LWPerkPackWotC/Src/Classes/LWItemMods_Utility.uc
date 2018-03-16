//---------------------------------------------------------------------------------------
//  FILE:    LWItemMods_Utility (adapted from LWTemplateMods_Utilities)
//  AUTHOR:  tracktwo and Amineri / Pavonis Interactive
//
//  PURPOSE: Early game hook to allow template modifications.
//---------------------------------------------------------------------------------------
class LWItemMods_Utility extends Object;

static function UpdateTemplates()
{
  local X2StrategyElementTemplateManager		StrategyTemplateMgr;
  local X2ItemTemplateManager				ItemTemplateMgr;

  local array<X2StrategyElementTemplate>		TemplateMods;
  local X2LWTemplateModTemplate				ModTemplate;
  local int idx;

  //retrieve all needed template managers
  StrategyTemplateMgr		= class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
  ItemTemplateMgr			= class'X2ItemTemplateManager'.static.GetItemTemplateManager();

  TemplateMods = StrategyTemplateMgr.GetAllTemplatesOfClass(class'X2LWTemplateModTemplate');
  for (idx = 0; idx < TemplateMods.Length; ++idx)
  {
    ModTemplate = X2LWTemplateModTemplate(TemplateMods[idx]);
    if (ModTemplate.ItemTemplateModFn != none)
    {
      `Log("Template Mods: Updating Item Templates for " $ ModTemplate.DataName);
      PerformItemTemplateMod(ModTemplate, ItemTemplateMgr);
    }
  }
}

static function PerformItemTemplateMod(X2LWTemplateModTemplate Template, X2DataTemplateManager TemplateManager)
{
  local X2ItemTemplate ItemTemplate;
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
      ItemTemplate = X2ItemTemplate(DataTemplate);
      if(ItemTemplate != none)
      {
        Difficulty = GetDifficultyFromTemplateName(TemplateName);
        Template.ItemTemplateModFn(ItemTemplate, Difficulty);
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

