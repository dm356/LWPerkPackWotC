//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ApplyDenseSmokeGrenadeToWorld.uc
//  AUTHOR:  Amineri (Pavonis Interactive)
//  PURPOSE: This applies a special dense smoke effect to the world, which stacks with the regular smoke effect
//---------------------------------------------------------------------------------------
class X2Effect_ApplyDenseSmokeGrenadeToWorld extends X2Effect_World config(LW_SoldierSkills);

var config string SmokeParticleSystemFill_Name;
var config int Duration;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
}

event array<X2Effect> GetTileEnteredEffects()
{
	local array<X2Effect> TileEnteredEffects;
	TileEnteredEffects.AddItem(class'X2Item_DenseSmokeGrenade'.static.DenseSmokeGrenadeEffect());
	return TileEnteredEffects;
}

event array<ParticleSystem> GetParticleSystem_Fill()
{
	local array<ParticleSystem> ParticleSystems;
	ParticleSystems.AddItem(none);
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(SmokeParticleSystemFill_Name, class'ParticleSystem')));
	return ParticleSystems;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_UpdateWorldEffects_Smoke AddSmokeAction;
	if( ActionMetadata.StateObject_NewState.IsA('XComGameState_WorldEffectTileData') )
	{
		AddSmokeAction = X2Action_UpdateWorldEffects_Smoke(class'X2Action_UpdateWorldEffects_Smoke'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		AddSmokeAction.bCenterTile = bCenterTile;
		AddSmokeAction.SetParticleSystems(GetParticleSystem_Fill());
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
}

//static simulated function bool FillRequiresLOSToTargetLocation( ) { return !class'Helpers_LW'.default.bWorldSmokeGrenadeShouldDisableExtraLOSCheck; }
// Switched to using default in WotC, looks like LW set this as a flag
static simulated function bool FillRequiresLOSToTargetLocation( ) { return true; }

static simulated function int GetTileDataNumTurns()
{
	return default.Duration;
}

defaultproperties
{
	bCenterTile = true;
}
