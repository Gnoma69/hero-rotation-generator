--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroLib
local HL     = HeroLib
local Cache  = HeroCache
local Unit   = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Pet    = Unit.Pet
local Spell  = HL.Spell
local Item   = HL.Item
-- HeroRotation
local HR     = HeroRotation

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Spells
if not Spell.DemonHunter then Spell.DemonHunter = {} end
Spell.DemonHunter.Havoc = {
  MetamorphosisBuff                     = Spell(162264),
  Metamorphosis                         = Spell(191427),
  Demonic                               = Spell(213410),
  Nemesis                               = Spell(206491),
  NemesisDebuff                         = Spell(206491),
  DarkSlash                             = Spell(),
  BladeDance                            = Spell(188499),
  Annihilation                          = Spell(201427),
  DarkSlashDebuff                       = Spell(),
  ChaosStrike                           = Spell(162794),
  FelBarrage                            = Spell(211053),
  DeathSweep                            = Spell(210152),
  EyeBeam                               = Spell(198013),
  ImmolationAura                        = Spell(178740),
  Felblade                              = Spell(232893),
  BlindFury                             = Spell(203550),
  FelRush                               = Spell(195072),
  DemonBlades                           = Spell(203555),
  DemonsBite                            = Spell(162243),
  ThrowGlaive                           = Spell(185123),
  OutofRangeBuff                        = Spell(),
  VengefulRetreat                       = Spell(198793),
  Momentum                              = Spell(206476),
  PreparedBuff                          = Spell(203650),
  FelMastery                            = Spell(192939),
  FirstBlood                            = Spell(206416),
  TrailofRuin                           = Spell(),
  MomentumBuff                          = Spell(208628),
  Disrupt                               = Spell(),
  PickUpFragment                        = Spell()
};
local S = Spell.DemonHunter.Havoc;

-- Items
if not Item.DemonHunter then Item.DemonHunter = {} end
Item.DemonHunter.Havoc = {
  ProlongedPower                   = Item(142117)
};
local I = Item.DemonHunter.Havoc;

-- Rotation Var
local ShouldReturn; -- Used to get the return string

-- GUI Settings
local Everyone = HR.Commons.Everyone;
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.DemonHunter.Commons,
  Havoc = HR.GUISettings.APL.DemonHunter.Havoc
};

-- Variables
local VarPoolingForMeta = 0;
local VarWaitingForNemesis = 0;
local VarBladeDance = 0;
local VarPoolingForBladeDance = 0;
local VarWaitingForMomentum = 0;
local VarWaitingForDarkSlash = 0;

local EnemyRanges = {8, 20, 30, 40}
local function UpdateRanges()
  for _, i in ipairs(EnemyRanges) do
    HL.GetEnemies(i);
  end
end

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

local function IsInMeleeRange()
  if S.Felblade:TimeSinceLastCast() <= Player:GCD() then
    return true
  elseif S.VengefulRetreat:TimeSinceLastCast() < 1.0 then
    return false
  end
  return Target:IsInRange("Melee")
end

local function IsMetaExtendedByDemonic()
  if not Player:BuffP(S.MetamorphosisBuff) then
    return false;
  elseif(S.EyeBeam:TimeSinceLastCast() < S.MetamorphosisImpact:TimeSinceLastCast()) then
    return true;
  end

  return false;
end

local function MetamorphosisCooldownAdjusted()
  -- TODO: Make this better by sampling the Fury expenses over time instead of approximating
  if I.ConvergenceofFates:IsEquipped() and I.DelusionsOfGrandeur:IsEquipped() then
    return S.Metamorphosis:CooldownRemainsP() * 0.56;
  elseif I.ConvergenceofFates:IsEquipped() then
    return S.Metamorphosis:CooldownRemainsP() * 0.78;
  elseif I.DelusionsOfGrandeur:IsEquipped() then
    return S.Metamorphosis:CooldownRemainsP() * 0.67;
  end
  return S.Metamorphosis:CooldownRemainsP()
end

--- ======= ACTION LISTS =======
local function APL()
  local Precombat, Cooldown, DarkSlash, Demonic, Normal
  UpdateRanges()
  Everyone.AoEToggleEnemiesUpdate()
  Precombat = function()
    -- flask
    -- augmentation
    -- food
    -- snapshot_stats
    -- potion
    if I.ProlongedPower:IsReady() and Settings.Commons.UsePotions then
      if HR.CastSuggested(I.ProlongedPower) then return ""; end
    end
    -- metamorphosis
    if S.Metamorphosis:IsCastableP() and Player:BuffDownP(S.MetamorphosisBuff) then
      if HR.Cast(S.Metamorphosis) then return ""; end
    end
  end
  Cooldown = function()
    -- metamorphosis,if=!(talent.demonic.enabled|variable.pooling_for_meta|variable.waiting_for_nemesis)|target.time_to_die<25
    if S.Metamorphosis:IsCastableP() and (not (S.Demonic:IsAvailable() or bool(VarPoolingForMeta) or bool(VarWaitingForNemesis)) or Target:TimeToDie() < 25) then
      if HR.Cast(S.Metamorphosis) then return ""; end
    end
    -- metamorphosis,if=talent.demonic.enabled&buff.metamorphosis.up
    if S.Metamorphosis:IsCastableP() and (S.Demonic:IsAvailable() and Player:BuffP(S.MetamorphosisBuff)) then
      if HR.Cast(S.Metamorphosis) then return ""; end
    end
    -- nemesis,target_if=min:target.time_to_die,if=raid_event.adds.exists&debuff.nemesis.down&(active_enemies>desired_targets|raid_event.adds.in>60)
    if S.Nemesis:IsCastableP() and (bool(min:target.time_to_die)) and (false and Target:DebuffDownP(S.NemesisDebuff) and (Cache.EnemiesCount[40] > 1 or 10000000000 > 60)) then
      if HR.Cast(S.Nemesis) then return ""; end
    end
    -- nemesis,if=!raid_event.adds.exists
    if S.Nemesis:IsCastableP() and (not false) then
      if HR.Cast(S.Nemesis) then return ""; end
    end
    -- potion,if=buff.metamorphosis.remains>25|target.time_to_die<60
    if I.ProlongedPower:IsReady() and Settings.Commons.UsePotions and (Player:BuffRemainsP(S.MetamorphosisBuff) > 25 or Target:TimeToDie() < 60) then
      if HR.CastSuggested(I.ProlongedPower) then return ""; end
    end
  end
  DarkSlash = function()
    -- dark_slash,if=fury>=80&(!variable.blade_dance|!cooldown.blade_dance.ready)
    if S.DarkSlash:IsCastableP() and (Player:Fury() >= 80 and (not bool(VarBladeDance) or not S.BladeDance:CooldownUpP())) then
      if HR.Cast(S.DarkSlash) then return ""; end
    end
    -- annihilation,if=debuff.dark_slash.up
    if S.Annihilation:IsCastableP() and IsInMeleeRange() and (Target:DebuffP(S.DarkSlashDebuff)) then
      if HR.Cast(S.Annihilation) then return ""; end
    end
    -- chaos_strike,if=debuff.dark_slash.up
    if S.ChaosStrike:IsCastableP() and IsInMeleeRange() and (Target:DebuffP(S.DarkSlashDebuff)) then
      if HR.Cast(S.ChaosStrike) then return ""; end
    end
  end
  Demonic = function()
    -- fel_barrage,if=active_enemies>desired_targets|raid_event.adds.in>30
    if S.FelBarrage:IsCastableP() and (Cache.EnemiesCount[30] > 1 or 10000000000 > 30) then
      if HR.Cast(S.FelBarrage) then return ""; end
    end
    -- death_sweep,if=variable.blade_dance
    if S.DeathSweep:IsCastableP() and (bool(VarBladeDance)) then
      if HR.Cast(S.DeathSweep) then return ""; end
    end
    -- blade_dance,if=variable.blade_dance&cooldown.eye_beam.remains>5&!cooldown.metamorphosis.ready
    if S.BladeDance:IsCastableP() and (bool(VarBladeDance) and S.EyeBeam:CooldownRemainsP() > 5 and not S.Metamorphosis:CooldownUpP()) then
      if HR.Cast(S.BladeDance) then return ""; end
    end
    -- immolation_aura
    if S.ImmolationAura:IsCastableP() then
      if HR.Cast(S.ImmolationAura) then return ""; end
    end
    -- felblade,if=fury<40|(buff.metamorphosis.down&fury.deficit>=40)
    if S.Felblade:IsCastableP() and (Player:Fury() < 40 or (Player:BuffDownP(S.MetamorphosisBuff) and Player:FuryDeficit() >= 40)) then
      if HR.Cast(S.Felblade) then return ""; end
    end
    -- eye_beam,if=(!talent.blind_fury.enabled|fury.deficit>=70)&(!buff.metamorphosis.extended_by_demonic|(set_bonus.tier21_4pc&buff.metamorphosis.remains>16))
    if S.EyeBeam:IsCastableP() and ((not S.BlindFury:IsAvailable() or Player:FuryDeficit() >= 70) and (not IsMetaExtendedByDemonic() or (HL.Tier21_4Pc and Player:BuffRemainsP(S.MetamorphosisBuff) > 16))) then
      if HR.Cast(S.EyeBeam) then return ""; end
    end
    -- annihilation,if=(talent.blind_fury.enabled|fury.deficit<30|buff.metamorphosis.remains<5)&!variable.pooling_for_blade_dance
    if S.Annihilation:IsCastableP() and IsInMeleeRange() and ((S.BlindFury:IsAvailable() or Player:FuryDeficit() < 30 or Player:BuffRemainsP(S.MetamorphosisBuff) < 5) and not bool(VarPoolingForBladeDance)) then
      if HR.Cast(S.Annihilation) then return ""; end
    end
    -- chaos_strike,if=(talent.blind_fury.enabled|fury.deficit<30)&!variable.pooling_for_meta&!variable.pooling_for_blade_dance
    if S.ChaosStrike:IsCastableP() and IsInMeleeRange() and ((S.BlindFury:IsAvailable() or Player:FuryDeficit() < 30) and not bool(VarPoolingForMeta) and not bool(VarPoolingForBladeDance)) then
      if HR.Cast(S.ChaosStrike) then return ""; end
    end
    -- fel_rush,if=talent.demon_blades.enabled&!cooldown.eye_beam.ready&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
    if S.FelRush:IsCastableP() and (S.DemonBlades:IsAvailable() and not S.EyeBeam:CooldownUpP() and (S.FelRush:ChargesP() == 2 or (10000000000 > 10 and 10000000000 > 10))) then
      if HR.Cast(S.FelRush) then return ""; end
    end
    -- demons_bite
    if S.DemonsBite:IsCastableP() and IsInMeleeRange() then
      if HR.Cast(S.DemonsBite) then return ""; end
    end
    -- throw_glaive,if=buff.out_of_range.up
    if S.ThrowGlaive:IsCastableP() and (Player:BuffP(S.OutofRangeBuff)) then
      if HR.Cast(S.ThrowGlaive) then return ""; end
    end
    -- fel_rush,if=movement.distance>15|buff.out_of_range.up
    if S.FelRush:IsCastableP() and (movement.distance > 15 or Player:BuffP(S.OutofRangeBuff)) then
      if HR.Cast(S.FelRush) then return ""; end
    end
    -- vengeful_retreat,if=movement.distance>15
    if S.VengefulRetreat:IsCastableP() and (movement.distance > 15) then
      if HR.Cast(S.VengefulRetreat) then return ""; end
    end
    -- throw_glaive,if=talent.demon_blades.enabled
    if S.ThrowGlaive:IsCastableP() and (S.DemonBlades:IsAvailable()) then
      if HR.Cast(S.ThrowGlaive) then return ""; end
    end
  end
  Normal = function()
    -- vengeful_retreat,if=talent.momentum.enabled&buff.prepared.down
    if S.VengefulRetreat:IsCastableP() and (S.Momentum:IsAvailable() and Player:BuffDownP(S.PreparedBuff)) then
      if HR.Cast(S.VengefulRetreat) then return ""; end
    end
    -- fel_rush,if=(variable.waiting_for_momentum|talent.fel_mastery.enabled)&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
    if S.FelRush:IsCastableP() and ((bool(VarWaitingForMomentum) or S.FelMastery:IsAvailable()) and (S.FelRush:ChargesP() == 2 or (10000000000 > 10 and 10000000000 > 10))) then
      if HR.Cast(S.FelRush) then return ""; end
    end
    -- fel_barrage,if=!variable.waiting_for_momentum&(active_enemies>desired_targets|raid_event.adds.in>30)
    if S.FelBarrage:IsCastableP() and (not bool(VarWaitingForMomentum) and (Cache.EnemiesCount[30] > 1 or 10000000000 > 30)) then
      if HR.Cast(S.FelBarrage) then return ""; end
    end
    -- immolation_aura
    if S.ImmolationAura:IsCastableP() then
      if HR.Cast(S.ImmolationAura) then return ""; end
    end
    -- eye_beam,if=active_enemies>1&(!raid_event.adds.exists|raid_event.adds.up)&!variable.waiting_for_momentum
    if S.EyeBeam:IsCastableP() and (Cache.EnemiesCount[20] > 1 and (not false or false) and not bool(VarWaitingForMomentum)) then
      if HR.Cast(S.EyeBeam) then return ""; end
    end
    -- death_sweep,if=variable.blade_dance
    if S.DeathSweep:IsCastableP() and (bool(VarBladeDance)) then
      if HR.Cast(S.DeathSweep) then return ""; end
    end
    -- blade_dance,if=variable.blade_dance
    if S.BladeDance:IsCastableP() and (bool(VarBladeDance)) then
      if HR.Cast(S.BladeDance) then return ""; end
    end
    -- felblade,if=fury.deficit>=40
    if S.Felblade:IsCastableP() and (Player:FuryDeficit() >= 40) then
      if HR.Cast(S.Felblade) then return ""; end
    end
    -- eye_beam,if=!talent.blind_fury.enabled&!variable.waiting_for_dark_slash&raid_event.adds.in>cooldown
    if S.EyeBeam:IsCastableP() and (not S.BlindFury:IsAvailable() and not bool(VarWaitingForDarkSlash) and 10000000000 > S.EyeBeam:Cooldown()) then
      if HR.Cast(S.EyeBeam) then return ""; end
    end
    -- annihilation,if=(talent.demon_blades.enabled|!variable.waiting_for_momentum|fury.deficit<30|buff.metamorphosis.remains<5)&!variable.pooling_for_blade_dance&!variable.waiting_for_dark_slash
    if S.Annihilation:IsCastableP() and IsInMeleeRange() and ((S.DemonBlades:IsAvailable() or not bool(VarWaitingForMomentum) or Player:FuryDeficit() < 30 or Player:BuffRemainsP(S.MetamorphosisBuff) < 5) and not bool(VarPoolingForBladeDance) and not bool(VarWaitingForDarkSlash)) then
      if HR.Cast(S.Annihilation) then return ""; end
    end
    -- chaos_strike,if=(talent.demon_blades.enabled|!variable.waiting_for_momentum|fury.deficit<30)&!variable.pooling_for_meta&!variable.pooling_for_blade_dance&!variable.waiting_for_dark_slash
    if S.ChaosStrike:IsCastableP() and IsInMeleeRange() and ((S.DemonBlades:IsAvailable() or not bool(VarWaitingForMomentum) or Player:FuryDeficit() < 30) and not bool(VarPoolingForMeta) and not bool(VarPoolingForBladeDance) and not bool(VarWaitingForDarkSlash)) then
      if HR.Cast(S.ChaosStrike) then return ""; end
    end
    -- eye_beam,if=talent.blind_fury.enabled&raid_event.adds.in>cooldown
    if S.EyeBeam:IsCastableP() and (S.BlindFury:IsAvailable() and 10000000000 > S.EyeBeam:Cooldown()) then
      if HR.Cast(S.EyeBeam) then return ""; end
    end
    -- demons_bite
    if S.DemonsBite:IsCastableP() and IsInMeleeRange() then
      if HR.Cast(S.DemonsBite) then return ""; end
    end
    -- fel_rush,if=!talent.momentum.enabled&raid_event.movement.in>charges*10&talent.demon_blades.enabled
    if S.FelRush:IsCastableP() and (not S.Momentum:IsAvailable() and 10000000000 > S.FelRush:ChargesP() * 10 and S.DemonBlades:IsAvailable()) then
      if HR.Cast(S.FelRush) then return ""; end
    end
    -- felblade,if=movement.distance>15|buff.out_of_range.up
    if S.Felblade:IsCastableP() and (movement.distance > 15 or Player:BuffP(S.OutofRangeBuff)) then
      if HR.Cast(S.Felblade) then return ""; end
    end
    -- fel_rush,if=movement.distance>15|(buff.out_of_range.up&!talent.momentum.enabled)
    if S.FelRush:IsCastableP() and (movement.distance > 15 or (Player:BuffP(S.OutofRangeBuff) and not S.Momentum:IsAvailable())) then
      if HR.Cast(S.FelRush) then return ""; end
    end
    -- vengeful_retreat,if=movement.distance>15
    if S.VengefulRetreat:IsCastableP() and (movement.distance > 15) then
      if HR.Cast(S.VengefulRetreat) then return ""; end
    end
    -- throw_glaive,if=talent.demon_blades.enabled
    if S.ThrowGlaive:IsCastableP() and (S.DemonBlades:IsAvailable()) then
      if HR.Cast(S.ThrowGlaive) then return ""; end
    end
  end
  -- call precombat
  if not Player:AffectingCombat() then
    local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
  end
  -- auto_attack
  -- variable,name=blade_dance,value=talent.first_blood.enabled|set_bonus.tier20_4pc|spell_targets.blade_dance1>=(3-talent.trail_of_ruin.enabled)
  if (true) then
    VarBladeDance = num(S.FirstBlood:IsAvailable() or HL.Tier20_4Pc or Cache.EnemiesCount[8] >= (3 - num(S.TrailofRuin:IsAvailable())))
  end
  -- variable,name=waiting_for_nemesis,value=!(!talent.nemesis.enabled|cooldown.nemesis.ready|cooldown.nemesis.remains>target.time_to_die|cooldown.nemesis.remains>60)
  if (true) then
    VarWaitingForNemesis = num(not (not S.Nemesis:IsAvailable() or S.Nemesis:CooldownUpP() or S.Nemesis:CooldownRemainsP() > Target:TimeToDie() or S.Nemesis:CooldownRemainsP() > 60))
  end
  -- variable,name=pooling_for_meta,value=!talent.demonic.enabled&cooldown.metamorphosis.remains<6&fury.deficit>30&(!variable.waiting_for_nemesis|cooldown.nemesis.remains<10)
  if (true) then
    VarPoolingForMeta = num(not S.Demonic:IsAvailable() and S.Metamorphosis:CooldownRemainsP() < 6 and Player:FuryDeficit() > 30 and (not bool(VarWaitingForNemesis) or S.Nemesis:CooldownRemainsP() < 10))
  end
  -- variable,name=pooling_for_blade_dance,value=variable.blade_dance&(fury<75-talent.first_blood.enabled*20)
  if (true) then
    VarPoolingForBladeDance = num(bool(VarBladeDance) and (Player:Fury() < 75 - num(S.FirstBlood:IsAvailable()) * 20))
  end
  -- variable,name=waiting_for_dark_slash,value=talent.dark_slash.enabled&!variable.pooling_for_blade_dance&!variable.pooling_for_meta&cooldown.dark_slash.up
  if (true) then
    VarWaitingForDarkSlash = num(S.DarkSlash:IsAvailable() and not bool(VarPoolingForBladeDance) and not bool(VarPoolingForMeta) and S.DarkSlash:CooldownUpP())
  end
  -- variable,name=waiting_for_momentum,value=talent.momentum.enabled&!buff.momentum.up
  if (true) then
    VarWaitingForMomentum = num(S.Momentum:IsAvailable() and not Player:BuffP(S.MomentumBuff))
  end
  -- disrupt
  if S.Disrupt:IsCastableP() then
    if HR.Cast(S.Disrupt) then return ""; end
  end
  -- call_action_list,name=cooldown,if=gcd.remains=0
  if (Player:GCDRemains() == 0) then
    local ShouldReturn = Cooldown(); if ShouldReturn then return ShouldReturn; end
  end
  -- pick_up_fragment,if=fury.deficit>=35
  if S.PickUpFragment:IsCastableP() and (Player:FuryDeficit() >= 35) then
    if HR.Cast(S.PickUpFragment) then return ""; end
  end
  -- call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if (S.DarkSlash:IsAvailable() and (bool(VarWaitingForDarkSlash) or Target:DebuffP(S.DarkSlashDebuff))) then
    local ShouldReturn = DarkSlash(); if ShouldReturn then return ShouldReturn; end
  end
  -- run_action_list,name=demonic,if=talent.demonic.enabled
  if (S.Demonic:IsAvailable()) then
    return Demonic();
  end
  -- run_action_list,name=normal
  if (true) then
    return Normal();
  end
end

HR.SetAPL(577, APL)
