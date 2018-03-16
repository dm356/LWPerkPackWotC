//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Effect_Savior.uc
//  AUTHOR:  Amineri (Pavonis Interactive)
//  PURPOSE: This is an effect component extension listening for medikit heals to grant extra health to the healed unit
//---------------------------------------------------------------------------------------

class XComGameState_Effect_Savior extends XComGameState_BaseObject;

//`include(..\..\XComGame\Mods\LW_Overhaul\Src\LW_PerkPack_Integrated\LW_PerkPack.uci)

function XComGameState_Effect_Savior InitComponent()
{
  return self;
}

function XComGameState_Effect GetOwningEffect()
{
  return XComGameState_Effect(`XCOMHISTORY.GetGameStateForObjectID(OwningObjectId));
}

//This is triggered by a Medikit heal
simulated function EventListenerReturn OnMedikitHeal(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
  local XComGameState_Unit SourceUnit, TargetUnit;
  local XpEventData XpEvent;
  local XComGameStateHistory History;
  local XComGameState_Effect EffectState;

  `Log("PerkPack(Savior): Event XpHealDamage Triggered");
  History = `XCOMHISTORY;
  XpEvent = XpEventData(EventData);
  if(XpEvent == none)
  {
    `REDSCREEN("Savior : XpHealDamage Event with invalid event data.");
    return ELR_NoInterrupt;
  }
  EffectState = GetOwningEffect();
  if (EffectState == none || EffectState.bReadOnly)  // this indicates that this is a stale effect from a previous battle
    return ELR_NoInterrupt;


  `Log("PerkPack(Savior): Retrieving Source Unit");
  SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(XpEvent.XpEarner.ObjectID));
  if(SourceUnit == none || SourceUnit != XComGameState_Unit(History.GetGameStateForObjectID(GetOwningEffect().ApplyEffectParameters.TargetStateObjectRef.ObjectID)))
    return ELR_NoInterrupt;

  `Log("PerkPack(Savior): Retrieving Target Unit");
  TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(XpEvent.EventTarget.ObjectID));
  if(TargetUnit == none)
    return ELR_NoInterrupt;

  `Log("PerkPack(Savior): Activating extra healing on Target Unit.");
  TargetUnit.ModifyCurrentStat(eStat_HP, class'X2Effect_Savior'.default.SaviorBonusHealAmount);

  //visualization function
  GameState.GetContext().PostBuildVisualizationFn.AddItem(Savior_BuildVisualization);

  return ELR_NoInterrupt;
}

function Savior_BuildVisualization(XComGameState VisualizeGameState)
{
  local XComGameStateHistory				History;
  local XComGameStateContext_Ability		Context;
  local VisualizationActionMetadata				EmptyTrack, ActionMetadata;
  local XComGameState_Unit				UnitState;
  local X2Action_PlayWorldMessage			MessageAction;
  local XGParamTag						kTag;
  local string							WorldMessage;

  History = `XCOMHISTORY;
  Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

  `Log ("SAVIOR: Building Collector Track");
  ActionMetadata = EmptyTrack;
  UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
  `Log ("SAVIOR: VisSoureUnit=" @ UnitState.GetFullName());
  ActionMetadata.StateObject_NewState = UnitState;
  ActionMetadata.StateObject_OldState = UnitState;
  ActionMetadata.VisualizeActor = UnitState.GetVisualizer();
  MessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

  kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
  if (kTag != none)
  {
    kTag.IntValue0 = class'X2Effect_Savior'.default.SaviorBonusHealAmount;
    WorldMessage = `XEXPAND.ExpandString(class'X2Effect_Savior'.default.strSavior_WorldMessage);
  } else {
    WorldMessage = "Placeholder Savior bonus (no XGParamTag)";
  }
  MessageAction.AddWorldMessage(WorldMessage);
}
