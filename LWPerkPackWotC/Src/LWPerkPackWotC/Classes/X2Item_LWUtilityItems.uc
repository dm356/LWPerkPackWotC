class X2Item_LWUtilityItems extends X2Item;

static function array<X2DataTemplate> CreateTemplates()
{
  local array<X2DataTemplate> Items;

  Items.AddItem(CreateGhostGrenade());

  return Items;
}

// Dummy item to fire for VanishingAct;
static function X2GrenadeTemplate CreateGhostGrenade()
{
  local X2GrenadeTemplate Template;

  `CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'GhostGrenade');

  Template.WeaponCat = 'Utility';
  Template.ItemCat = 'Utility';

  Template.iRange = class'X2Item_DefaultGrenades'.default.SMOKEGRENADE_RANGE;
  Template.iRadius = 0.75;
  Template.iSoundRange = class'X2Item_DefaultGrenades'.default.SMOKEGRENADE_ISOUNDRANGE;
  Template.iEnvironmentDamage = class'X2Item_DefaultGrenades'.default.SMOKEGRENADE_IENVIRONMENTDAMAGE;
  Template.iClipSize = 0;
  Template.Tier = 2;

  //Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_ghost");
  //Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_ghost");

  //Template.Abilities.AddItem('ThrowGrenade');
  Template.Abilities.AddItem('VanishingAct');

  //WeaponEffect = new class'X2Effect_ApplySmokeGrenadeToWorld';
  //Template.AddTargetEffect (WeaponEffect);

  //SmokeEffect = new class'X2Effect_SmokeGrenade';
  //SmokeEffect.BuildPersistentEffect(class'X2Effect_ApplySmokeGrenadeToWorld'.default.Duration + 1, false, false, false, eGameRule_PlayerTurnBegin);
  //SmokeEffect.SetDisplayInfo(1, class'X2Item_DefaultGrenades'.default.SmokeGrenadeEffectDisplayName, class'X2Item_DefaultGrenades'.default.SmokeGrenadeEffectDisplayDesc, "img:///UILibrary_PerkIcons.UIPerk_grenade_smoke");
  //SmokeEffect.HitMod = class'X2Item_DefaultGrenades'.default.SMOKEGRENADE_HITMOD;
  //SmokeEffect.DuplicateResponse = 1;
  //Template.AddTargetEffect (SmokeEffect);

  //StealthEffect = new class'X2Effect_RangerStealth';
  //StealthEffect.BuildPersistentEffect(1, true, true, false, 8);
  //StealthEffect.SetDisplayInfo(1, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
  //StealthEffect.bRemoveWhenTargetConcealmentBroken = true;
  //Template.AddTargetEffect(StealthEffect);
  //Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

  //Template.bFriendlyFireWarning = false;

  Template.GameArchetype = "WP_Grenade_Smoke.WP_Grenade_Smoke";
  Template.OnThrowBarkSoundCue = 'SmokeGrenade';

  Template.CanBeBuilt = false;

  return Template;
}

