//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_LWListenerManager.uc
//  AUTHOR:  Amineri / Pavonis Interactive
//  PURPOSE: This singleton object manages general persistent listeners that should live for both strategy and tactical play
//---------------------------------------------------------------------------------------
class XComGameState_LWListenerManager extends XComGameState_BaseObject;

//`include(..\..\XComGame\Mods\DeviantClassPack\Src\LW_PerkPack_Integrated\LW_PerkPack.uci)

static function XComGameState_LWListenerManager GetListenerManager(optional bool AllowNULL = false)
{
	return XComGameState_LWListenerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LWListenerManager', AllowNULL));
}

static function CreateListenerManager(optional XComGameState StartState)
{
	local XComGameState_LWListenerManager ListenerMgr;
	local XComGameState NewGameState;

	//first check that there isn't already a singleton instance of the listener manager
	if(GetListenerManager(true) != none)
		return;

	if(StartState != none)
	{
		ListenerMgr = XComGameState_LWListenerManager(StartState.CreateStateObject(class'XComGameState_LWListenerManager'));
		StartState.AddStateObject(ListenerMgr);
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Creating LW Listener Manager Singleton");
		ListenerMgr = XComGameState_LWListenerManager(NewGameState.CreateStateObject(class'XComGameState_LWListenerManager'));
		NewGameState.AddStateObject(ListenerMgr);
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}

	ListenerMgr.InitListeners();
}

static function RefreshListeners()
{
	local XComGameState_LWListenerManager ListenerMgr;

	ListenerMgr = GetListenerManager(true);
	if(ListenerMgr == none)
		CreateListenerManager();
	else
		ListenerMgr.InitListeners();
}

function InitListeners()
{
	local X2EventManager EventMgr;
	local Object ThisObj;

	`Log("Init Listeners Firing!");

	ThisObj = self;
	EventMgr = `XEVENTMGR;
	EventMgr.UnregisterFromAllEvents(ThisObj); // clear all old listeners to clear out old stuff before re-registering

	// Attempt to tame Serial
	EventMgr.RegisterForEvent(ThisObj, 'SerialKiller', OnSerialKill, ELD_OnStateSubmitted);

}

// NOTE: WotC requires `Object CallbackData' for all Events now
function EventListenerReturn OnSerialKill(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData)
{
	local XComGameState_Unit ShooterState;
    local UnitValue UnitVal;

	ShooterState = XComGameState_Unit (EventSource);
	If (ShooterState == none)
	{
		return ELR_NoInterrupt;
	}
	ShooterState.GetUnitValue ('SerialKills', UnitVal);
	ShooterState.SetUnitFloatValue ('SerialKills', UnitVal.fValue + 1.0, eCleanup_BeginTurn);
	return ELR_NoInterrupt;
}

