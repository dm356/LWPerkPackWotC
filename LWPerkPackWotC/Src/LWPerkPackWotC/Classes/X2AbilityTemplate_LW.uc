//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTemplate_LW.uc
//  AUTHOR:  Amineri (Pavonis Interactive)
//	
//  PURPOSE: Overrides localization strings so that we can do value replacements for new abilities
//           
//	Create templates of this type using :
//	`CREATE_X2TEMPLATE(class'X2AbilityTemplate_LW', Template, 'MyTemplateName');
//---------------------------------------------------------------------------------------
class X2AbilityTemplate_LW extends X2AbilityTemplate;

var delegate<MyHelpText> MyHelpTextFn;
var delegate<MyLongDescription> MyLongDescriptionFn;
var delegate<ExpandedPromotionPopupText> ExpandedPromotionPopupTextFn;

delegate string MyHelpText(optional XComGameState_Ability AbilityState, optional XComGameState_Unit UnitState, optional XComGameState CheckGameState);
delegate string MyLongDescription(optional XComGameState_Ability AbilityState, optional XComGameState_Unit UnitState, optional XComGameState CheckGameState);
delegate string ExpandedPromotionPopupText(XComGameState_Unit StrategyUnitState);

simulated function string GetMyHelpText(optional XComGameState_Ability AbilityState, optional XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return MyHelpTextFn(AbilityState, UnitState, CheckGameState);
}

simulated function string GetMyLongDescription(optional XComGameState_Ability AbilityState, optional XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return MyLongDescriptionFn(AbilityState, UnitState, CheckGameState);
}

simulated function string GetExpandedPromotionPopupText(XComGameState_Unit StrategyUnitState)
{
	return ExpandedPromotionPopupTextFn(StrategyUnitState);
}