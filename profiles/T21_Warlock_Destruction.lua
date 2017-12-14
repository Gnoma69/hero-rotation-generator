--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- AethysCore
local AC     = AethysCore
local Cache  = AethysCache
local Unit   = AC.Unit
local Player = Unit.Player
local Target = Unit.Target
local Pet    = Unit.Pet
local Spell  = AC.Spell
local Item   = AC.Item
-- AethysRotation
local AR     = AethysRotation

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Spells
if not Spell.Warlock then Spell.Warlock = {} end
Spell.Warlock.Destruction = {
  SummonPet                             = Spell(),
  GrimoireofSupremacy                   = Spell(152107),
  GrimoireofSacrifice                   = Spell(),
  DemonicPowerBuff                      = Spell(),
  SummonInfernal                        = Spell(1122),
  LordofFlames                          = Spell(224103),
  SummonDoomguard                       = Spell(18540),
  LifeTap                               = Spell(1454),
  EmpoweredLifeTap                      = Spell(235157),
  EmpoweredLifeTapBuff                  = Spell(235156),
  ChaosBolt                             = Spell(116858),
  Immolate                              = Spell(348),
  RoaringBlaze                          = Spell(205184),
  Havoc                                 = Spell(80240),
  ImmolateDebuff                        = Spell(157736),
  ActiveHavocBuff                       = Spell(),
  WreakHavoc                            = Spell(196410),
  HavocDebuff                           = Spell(80240),
  DimensionalRift                       = Spell(196586),
  Cataclysm                             = Spell(152108),
  FireandBrimstone                      = Spell(196408),
  RoaringBlazeDebuff                    = Spell(205690),
  Conflagrate                           = Spell(17962),
  Berserking                            = Spell(26297),
  BloodFury                             = Spell(20572),
  UseItems                              = Spell(),
  SoulHarvestBuff                       = Spell(196098),
  Shadowburn                            = Spell(17877),
  ConflagrationofChaosBuff              = Spell(196546),
  BackdraftBuff                         = Spell(117828),
  LessonsofSpacetimeBuff                = Spell(236174),
  GrimoireofService                     = Spell(108501),
  ServicePet                            = Spell(),
  SoulHarvest                           = Spell(196098),
  LordofFlamesBuff                      = Spell(226802),
  SindoreiSpiteIcd                      = Spell(),
  ChannelDemonfire                      = Spell(196447),
  RainofFire                            = Spell(5740),
  Incinerate                            = Spell(29722)
};
local S = Spell.Warlock.Destruction;

-- Items
if not Item.Warlock then Item.Warlock = {} end
Item.Warlock.Destruction = {
  ProlongedPower                   = Item(142117),
  Item144369                       = Item(144369),
  Item132379                       = Item(132379)
};
local I = Item.Warlock.Destruction;

-- Rotation Var
local ShouldReturn; -- Used to get the return string

-- GUI Settings
local Everyone = AR.Commons.Everyone;
local Settings = {
  General = AR.GUISettings.General,
  Commons = AR.GUISettings.APL.Warlock.Commons,
  Destruction = AR.GUISettings.APL.Warlock.Destruction
};

-- Variables

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

--- ======= ACTION LISTS =======
local function Apl()
  local function Precombat()
    -- flask
    -- food
    -- augmentation
    -- summon_pet,if=!talent.grimoire_of_supremacy.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.demonic_power.down)
    if S.SummonPet:IsCastableP() and (not S.GrimoireofSupremacy:IsAvailable() and (not S.GrimoireofSacrifice:IsAvailable() or Player:BuffDownP(S.DemonicPowerBuff))) then
      if AR.Cast(S.SummonPet) then return ""; end
    end
    -- summon_infernal,if=talent.grimoire_of_supremacy.enabled&artifact.lord_of_flames.rank>0
    if S.SummonInfernal:IsCastableP() and (S.GrimoireofSupremacy:IsAvailable() and S.LordofFlames:ArtifactRank() > 0) then
      if AR.Cast(S.SummonInfernal) then return ""; end
    end
    -- summon_infernal,if=talent.grimoire_of_supremacy.enabled&active_enemies>1
    if S.SummonInfernal:IsCastableP() and (S.GrimoireofSupremacy:IsAvailable() and Cache.EnemiesCount[30] > 1) then
      if AR.Cast(S.SummonInfernal) then return ""; end
    end
    -- summon_doomguard,if=talent.grimoire_of_supremacy.enabled&active_enemies=1&artifact.lord_of_flames.rank=0
    if S.SummonDoomguard:IsCastableP() and (S.GrimoireofSupremacy:IsAvailable() and Cache.EnemiesCount[40] == 1 and S.LordofFlames:ArtifactRank() == 0) then
      if AR.Cast(S.SummonDoomguard) then return ""; end
    end
    -- snapshot_stats
    -- grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
    if S.GrimoireofSacrifice:IsCastableP() and (S.GrimoireofSacrifice:IsAvailable()) then
      if AR.Cast(S.GrimoireofSacrifice) then return ""; end
    end
    -- life_tap,if=talent.empowered_life_tap.enabled&!buff.empowered_life_tap.remains
    if S.LifeTap:IsCastableP() and (S.EmpoweredLifeTap:IsAvailable() and not bool(Player:BuffRemainsP(S.EmpoweredLifeTapBuff))) then
      if AR.Cast(S.LifeTap) then return ""; end
    end
    -- potion
    if I.ProlongedPower:IsReady() and Settings.Commons.UsePotions and (true) then
      if AR.CastSuggested(I.ProlongedPower) then return ""; end
    end
    -- chaos_bolt
    if S.ChaosBolt:IsCastableP() and (true) then
      if AR.Cast(S.ChaosBolt) then return ""; end
    end
  end
  -- call precombat
  if not Player:AffectingCombat() then
    local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
  end
  -- immolate,cycle_targets=1,if=active_enemies=2&talent.roaring_blaze.enabled&!cooldown.havoc.remains&dot.immolate.remains<=buff.active_havoc.duration
  if S.Immolate:IsCastableP() and (Cache.EnemiesCount[40] == 2 and S.RoaringBlaze:IsAvailable() and not bool(S.Havoc:CooldownRemainsP()) and Target:DebuffRemainsP(S.ImmolateDebuff) <= S.ActiveHavocBuff:BaseDuration()) then
    if AR.Cast(S.Immolate) then return ""; end
  end
  -- havoc,target=2,if=active_enemies>1&(active_enemies<4|talent.wreak_havoc.enabled&active_enemies<6)&!debuff.havoc.remains
  if S.Havoc:IsCastableP() and (Cache.EnemiesCount[40] > 1 and (Cache.EnemiesCount[40] < 4 or S.WreakHavoc:IsAvailable() and Cache.EnemiesCount[40] < 6) and not bool(Target:DebuffRemainsP(S.HavocDebuff))) then
    if AR.Cast(S.Havoc) then return ""; end
  end
  -- dimensional_rift,if=charges=3
  if S.DimensionalRift:IsCastableP() and (S.DimensionalRift:ChargesP() == 3) then
    if AR.Cast(S.DimensionalRift) then return ""; end
  end
  -- cataclysm,if=spell_targets.cataclysm>=3
  if S.Cataclysm:IsCastableP() and (Cache.EnemiesCount[40] >= 3) then
    if AR.Cast(S.Cataclysm) then return ""; end
  end
  -- immolate,if=(active_enemies<5|!talent.fire_and_brimstone.enabled)&remains<=tick_time
  if S.Immolate:IsCastableP() and ((Cache.EnemiesCount[40] < 5 or not S.FireandBrimstone:IsAvailable()) and Target:DebuffRemainsP(S.Immolate) <= S.Immolate:TickTime()) then
    if AR.Cast(S.Immolate) then return ""; end
  end
  -- immolate,cycle_targets=1,if=(active_enemies<5|!talent.fire_and_brimstone.enabled)&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>=action.immolate.cast_time*active_enemies)&active_enemies>1&remains<=tick_time&(!talent.roaring_blaze.enabled|(!debuff.roaring_blaze.remains&action.conflagrate.charges<2+set_bonus.tier19_4pc))
  if S.Immolate:IsCastableP() and ((Cache.EnemiesCount[40] < 5 or not S.FireandBrimstone:IsAvailable()) and (not S.Cataclysm:IsAvailable() or S.Cataclysm:CooldownRemainsP() >= S.Immolate:CastTime() * Cache.EnemiesCount[40]) and Cache.EnemiesCount[40] > 1 and Target:DebuffRemainsP(S.Immolate) <= S.Immolate:TickTime() and (not S.RoaringBlaze:IsAvailable() or (not bool(Target:DebuffRemainsP(S.RoaringBlazeDebuff)) and S.Conflagrate:ChargesP() < 2 + num(AC.Tier19_4Pc)))) then
    if AR.Cast(S.Immolate) then return ""; end
  end
  -- immolate,if=talent.roaring_blaze.enabled&remains<=duration&!debuff.roaring_blaze.remains&target.time_to_die>10&(action.conflagrate.charges=2+set_bonus.tier19_4pc|(action.conflagrate.charges>=1+set_bonus.tier19_4pc&action.conflagrate.recharge_time<cast_time+gcd)|target.time_to_die<24)
  if S.Immolate:IsCastableP() and (S.RoaringBlaze:IsAvailable() and Target:DebuffRemainsP(S.Immolate) <= S.Immolate:BaseDuration() and not bool(Target:DebuffRemainsP(S.RoaringBlazeDebuff)) and Target:TimeToDie() > 10 and (S.Conflagrate:ChargesP() == 2 + num(AC.Tier19_4Pc) or (S.Conflagrate:ChargesP() >= 1 + num(AC.Tier19_4Pc) and S.Conflagrate:RechargeP() < S.Immolate:CastTime() + Player:GCD()) or Target:TimeToDie() < 24)) then
    if AR.Cast(S.Immolate) then return ""; end
  end
  -- berserking
  if S.Berserking:IsCastableP() and AR.CDsON() and (true) then
    if AR.Cast(S.Berserking, Settings.Destruction.OffGCDasOffGCD.Berserking) then return ""; end
  end
  -- blood_fury
  if S.BloodFury:IsCastableP() and AR.CDsON() and (true) then
    if AR.Cast(S.BloodFury, Settings.Destruction.OffGCDasOffGCD.BloodFury) then return ""; end
  end
  -- use_items
  if S.UseItems:IsCastableP() and (true) then
    if AR.Cast(S.UseItems) then return ""; end
  end
  -- potion,name=deadly_grace,if=(buff.soul_harvest.remains|trinket.proc.any.react|target.time_to_die<=45)
  if I.ProlongedPower:IsReady() and Settings.Commons.UsePotions and ((bool(Player:BuffRemainsP(S.SoulHarvestBuff)) or bool(trinket.proc.any.react) or Target:TimeToDie() <= 45)) then
    if AR.CastSuggested(I.ProlongedPower) then return ""; end
  end
  -- shadowburn,if=soul_shard<4&buff.conflagration_of_chaos.remains<=action.chaos_bolt.cast_time
  if S.Shadowburn:IsCastableP() and (soul_shard < 4 and Player:BuffRemainsP(S.ConflagrationofChaosBuff) <= S.ChaosBolt:CastTime()) then
    if AR.Cast(S.Shadowburn) then return ""; end
  end
  -- shadowburn,if=(charges=1+set_bonus.tier19_4pc&recharge_time<action.chaos_bolt.cast_time|charges=2+set_bonus.tier19_4pc)&soul_shard<5
  if S.Shadowburn:IsCastableP() and ((S.Shadowburn:ChargesP() == 1 + num(AC.Tier19_4Pc) and S.Shadowburn:RechargeP() < S.ChaosBolt:CastTime() or S.Shadowburn:ChargesP() == 2 + num(AC.Tier19_4Pc)) and soul_shard < 5) then
    if AR.Cast(S.Shadowburn) then return ""; end
  end
  -- conflagrate,if=talent.roaring_blaze.enabled&(charges=2+set_bonus.tier19_4pc|(charges>=1+set_bonus.tier19_4pc&recharge_time<gcd)|target.time_to_die<24)
  if S.Conflagrate:IsCastableP() and (S.RoaringBlaze:IsAvailable() and (S.Conflagrate:ChargesP() == 2 + num(AC.Tier19_4Pc) or (S.Conflagrate:ChargesP() >= 1 + num(AC.Tier19_4Pc) and S.Conflagrate:RechargeP() < Player:GCD()) or Target:TimeToDie() < 24)) then
    if AR.Cast(S.Conflagrate) then return ""; end
  end
  -- conflagrate,if=talent.roaring_blaze.enabled&debuff.roaring_blaze.stack>0&dot.immolate.remains>dot.immolate.duration*0.3&(active_enemies=1|soul_shard<3)&soul_shard<5
  if S.Conflagrate:IsCastableP() and (S.RoaringBlaze:IsAvailable() and Target:DebuffStackP(S.RoaringBlazeDebuff) > 0 and Target:DebuffRemainsP(S.ImmolateDebuff) > S.ImmolateDebuff:BaseDuration() * 0.3 and (Cache.EnemiesCount[40] == 1 or soul_shard < 3) and soul_shard < 5) then
    if AR.Cast(S.Conflagrate) then return ""; end
  end
  -- conflagrate,if=!talent.roaring_blaze.enabled&buff.backdraft.stack<3&(charges=1+set_bonus.tier19_4pc&recharge_time<action.chaos_bolt.cast_time|charges=2+set_bonus.tier19_4pc)&soul_shard<5
  if S.Conflagrate:IsCastableP() and (not S.RoaringBlaze:IsAvailable() and Player:BuffStackP(S.BackdraftBuff) < 3 and (S.Conflagrate:ChargesP() == 1 + num(AC.Tier19_4Pc) and S.Conflagrate:RechargeP() < S.ChaosBolt:CastTime() or S.Conflagrate:ChargesP() == 2 + num(AC.Tier19_4Pc)) and soul_shard < 5) then
    if AR.Cast(S.Conflagrate) then return ""; end
  end
  -- life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<=gcd
  if S.LifeTap:IsCastableP() and (S.EmpoweredLifeTap:IsAvailable() and Player:BuffRemainsP(S.EmpoweredLifeTapBuff) <= Player:GCD()) then
    if AR.Cast(S.LifeTap) then return ""; end
  end
  -- dimensional_rift,if=equipped.144369&!buff.lessons_of_spacetime.remains&((!talent.grimoire_of_supremacy.enabled&!cooldown.summon_doomguard.remains)|(talent.grimoire_of_service.enabled&!cooldown.service_pet.remains)|(talent.soul_harvest.enabled&!cooldown.soul_harvest.remains))
  if S.DimensionalRift:IsCastableP() and (I.Item144369:IsEquipped() and not bool(Player:BuffRemainsP(S.LessonsofSpacetimeBuff)) and ((not S.GrimoireofSupremacy:IsAvailable() and not bool(S.SummonDoomguard:CooldownRemainsP())) or (S.GrimoireofService:IsAvailable() and not bool(S.ServicePet:CooldownRemainsP())) or (S.SoulHarvest:IsAvailable() and not bool(S.SoulHarvest:CooldownRemainsP())))) then
    if AR.Cast(S.DimensionalRift) then return ""; end
  end
  -- service_pet
  if S.ServicePet:IsCastableP() and (true) then
    if AR.Cast(S.ServicePet) then return ""; end
  end
  -- summon_infernal,if=artifact.lord_of_flames.rank>0&!buff.lord_of_flames.remains
  if S.SummonInfernal:IsCastableP() and (S.LordofFlames:ArtifactRank() > 0 and not bool(Player:BuffRemainsP(S.LordofFlamesBuff))) then
    if AR.Cast(S.SummonInfernal) then return ""; end
  end
  -- summon_doomguard,if=!talent.grimoire_of_supremacy.enabled&spell_targets.infernal_awakening<=2&(target.time_to_die>180|target.health.pct<=20|target.time_to_die<30)
  if S.SummonDoomguard:IsCastableP() and (not S.GrimoireofSupremacy:IsAvailable() and Cache.EnemiesCount[40] <= 2 and (Target:TimeToDie() > 180 or Target:HealthPercentage() <= 20 or Target:TimeToDie() < 30)) then
    if AR.Cast(S.SummonDoomguard) then return ""; end
  end
  -- summon_infernal,if=!talent.grimoire_of_supremacy.enabled&spell_targets.infernal_awakening>2
  if S.SummonInfernal:IsCastableP() and (not S.GrimoireofSupremacy:IsAvailable() and Cache.EnemiesCount[40] > 2) then
    if AR.Cast(S.SummonInfernal) then return ""; end
  end
  -- summon_doomguard,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal=1&artifact.lord_of_flames.rank>0&buff.lord_of_flames.remains&!pet.doomguard.active
  if S.SummonDoomguard:IsCastableP() and (S.GrimoireofSupremacy:IsAvailable() and Cache.EnemiesCount[30] == 1 and S.LordofFlames:ArtifactRank() > 0 and bool(Player:BuffRemainsP(S.LordofFlamesBuff)) and not bool(pet.doomguard.active)) then
    if AR.Cast(S.SummonDoomguard) then return ""; end
  end
  -- summon_doomguard,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal=1&equipped.132379&!cooldown.sindorei_spite_icd.remains
  if S.SummonDoomguard:IsCastableP() and (S.GrimoireofSupremacy:IsAvailable() and Cache.EnemiesCount[30] == 1 and I.Item132379:IsEquipped() and not bool(S.SindoreiSpiteIcd:CooldownRemainsP())) then
    if AR.Cast(S.SummonDoomguard) then return ""; end
  end
  -- summon_infernal,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal>1&equipped.132379&!cooldown.sindorei_spite_icd.remains
  if S.SummonInfernal:IsCastableP() and (S.GrimoireofSupremacy:IsAvailable() and Cache.EnemiesCount[30] > 1 and I.Item132379:IsEquipped() and not bool(S.SindoreiSpiteIcd:CooldownRemainsP())) then
    if AR.Cast(S.SummonInfernal) then return ""; end
  end
  -- soul_harvest,if=!buff.soul_harvest.remains
  if S.SoulHarvest:IsCastableP() and (not bool(Player:BuffRemainsP(S.SoulHarvestBuff))) then
    if AR.Cast(S.SoulHarvest) then return ""; end
  end
  -- chaos_bolt,if=active_enemies<4&buff.active_havoc.remains>cast_time
  if S.ChaosBolt:IsCastableP() and (Cache.EnemiesCount[40] < 4 and Player:BuffRemainsP(S.ActiveHavocBuff) > S.ChaosBolt:CastTime()) then
    if AR.Cast(S.ChaosBolt) then return ""; end
  end
  -- channel_demonfire,if=dot.immolate.remains>cast_time&(active_enemies=1|buff.active_havoc.remains<action.chaos_bolt.cast_time)
  if S.ChannelDemonfire:IsCastableP() and (Target:DebuffRemainsP(S.ImmolateDebuff) > S.ChannelDemonfire:CastTime() and (Cache.EnemiesCount[40] == 1 or Player:BuffRemainsP(S.ActiveHavocBuff) < S.ChaosBolt:CastTime())) then
    if AR.Cast(S.ChannelDemonfire) then return ""; end
  end
  -- rain_of_fire,if=active_enemies>=3
  if S.RainofFire:IsCastableP() and (Cache.EnemiesCount[35] >= 3) then
    if AR.Cast(S.RainofFire) then return ""; end
  end
  -- rain_of_fire,if=active_enemies>=6&talent.wreak_havoc.enabled
  if S.RainofFire:IsCastableP() and (Cache.EnemiesCount[35] >= 6 and S.WreakHavoc:IsAvailable()) then
    if AR.Cast(S.RainofFire) then return ""; end
  end
  -- dimensional_rift,if=target.time_to_die<=32|!equipped.144369|charges>1|(!equipped.144369&(!talent.grimoire_of_service.enabled|recharge_time<cooldown.service_pet.remains)&(!talent.soul_harvest.enabled|recharge_time<cooldown.soul_harvest.remains)&(!talent.grimoire_of_supremacy.enabled|recharge_time<cooldown.summon_doomguard.remains))
  if S.DimensionalRift:IsCastableP() and (Target:TimeToDie() <= 32 or not I.Item144369:IsEquipped() or S.DimensionalRift:ChargesP() > 1 or (not I.Item144369:IsEquipped() and (not S.GrimoireofService:IsAvailable() or S.DimensionalRift:RechargeP() < S.ServicePet:CooldownRemainsP()) and (not S.SoulHarvest:IsAvailable() or S.DimensionalRift:RechargeP() < S.SoulHarvest:CooldownRemainsP()) and (not S.GrimoireofSupremacy:IsAvailable() or S.DimensionalRift:RechargeP() < S.SummonDoomguard:CooldownRemainsP()))) then
    if AR.Cast(S.DimensionalRift) then return ""; end
  end
  -- life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<duration*0.3
  if S.LifeTap:IsCastableP() and (S.EmpoweredLifeTap:IsAvailable() and Player:BuffRemainsP(S.EmpoweredLifeTapBuff) < S.LifeTap:BaseDuration() * 0.3) then
    if AR.Cast(S.LifeTap) then return ""; end
  end
  -- cataclysm
  if S.Cataclysm:IsCastableP() and (true) then
    if AR.Cast(S.Cataclysm) then return ""; end
  end
  -- chaos_bolt,if=active_enemies<3&(cooldown.havoc.remains>12&cooldown.havoc.remains|active_enemies=1|soul_shard>=5-spell_targets.infernal_awakening*1.5|target.time_to_die<=10)
  if S.ChaosBolt:IsCastableP() and (Cache.EnemiesCount[40] < 3 and (S.Havoc:CooldownRemainsP() > 12 and bool(S.Havoc:CooldownRemainsP()) or Cache.EnemiesCount[40] == 1 or soul_shard >= 5 - Cache.EnemiesCount[40] * 1.5 or Target:TimeToDie() <= 10)) then
    if AR.Cast(S.ChaosBolt) then return ""; end
  end
  -- shadowburn
  if S.Shadowburn:IsCastableP() and (true) then
    if AR.Cast(S.Shadowburn) then return ""; end
  end
  -- conflagrate,if=!talent.roaring_blaze.enabled&buff.backdraft.stack<3
  if S.Conflagrate:IsCastableP() and (not S.RoaringBlaze:IsAvailable() and Player:BuffStackP(S.BackdraftBuff) < 3) then
    if AR.Cast(S.Conflagrate) then return ""; end
  end
  -- immolate,cycle_targets=1,if=(active_enemies<5|!talent.fire_and_brimstone.enabled)&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>=action.immolate.cast_time*active_enemies)&!talent.roaring_blaze.enabled&remains<=duration*0.3
  if S.Immolate:IsCastableP() and ((Cache.EnemiesCount[40] < 5 or not S.FireandBrimstone:IsAvailable()) and (not S.Cataclysm:IsAvailable() or S.Cataclysm:CooldownRemainsP() >= S.Immolate:CastTime() * Cache.EnemiesCount[40]) and not S.RoaringBlaze:IsAvailable() and Target:DebuffRemainsP(S.Immolate) <= S.Immolate:BaseDuration() * 0.3) then
    if AR.Cast(S.Immolate) then return ""; end
  end
  -- incinerate
  if S.Incinerate:IsCastableP() and (true) then
    if AR.Cast(S.Incinerate) then return ""; end
  end
  -- life_tap
  if S.LifeTap:IsCastableP() and (true) then
    if AR.Cast(S.LifeTap) then return ""; end
  end
end