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
if not Spell.Monk then Spell.Monk = {} end
Spell.Monk.Windwalker = {
  ChiBurst                              = Spell(123986),
  ChiWave                               = Spell(115098),
  EnergizingElixir                      = Spell(115288),
  TigerPalm                             = Spell(100780),
  RisingSunKick                         = Spell(107428),
  StrikeoftheWindlord                   = Spell(205320),
  ArcaneTorrent                         = Spell(50613),
  FistsofFury                           = Spell(113656),
  Serenity                              = Spell(152173),
  WhirlingDragonPunch                   = Spell(152175),
  RushingJadeWind                       = Spell(116847),
  SpinningCraneKick                     = Spell(107270),
  BokProcBuff                           = Spell(),
  BlackoutKick                          = Spell(100784),
  CracklingJadeLightning                = Spell(117952),
  TheEmperorsCapacitorBuff              = Spell(235054),
  InvokeXuentheWhiteTiger               = Spell(123904),
  BloodFury                             = Spell(20572),
  Berserking                            = Spell(26297),
  TouchofDeath                          = Spell(115080),
  GaleBurst                             = Spell(),
  StormEarthandFire                     = Spell(137639),
  StormEarthandFireBuff                 = Spell(137639),
  SerenityBuff                          = Spell(152173),
  PressurePointBuff                     = Spell(247255),
  RushingJadeWindBuff                   = Spell(116847),
  SpearHandStrike                       = Spell(116705),
  TouchofKarma                          = Spell(122470)
};
local S = Spell.Monk.Windwalker;

-- Items
if not Item.Monk then Item.Monk = {} end
Item.Monk.Windwalker = {
  ProlongedPower                   = Item(142117),
  DrinkingHornCover                = Item(137097),
  TheEmperorsCapacitor             = Item(144239),
  HiddenMastersForbiddenTouch      = Item(137057)
};
local I = Item.Monk.Windwalker;

-- Rotation Var
local ShouldReturn; -- Used to get the return string

-- GUI Settings
local Everyone = HR.Commons.Everyone;
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.Monk.Commons,
  Windwalker = HR.GUISettings.APL.Monk.Windwalker
};

-- Variables

local EnemyRanges = {8}
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

--- ======= ACTION LISTS =======
local function APL()
  UpdateRanges()
  local function Precombat()
    -- flask
    -- food
    -- augmentation
    -- snapshot_stats
    -- potion
    if I.ProlongedPower:IsReady() and Settings.Commons.UsePotions and (true) then
      if HR.CastSuggested(I.ProlongedPower) then return ""; end
    end
    -- chi_burst
    if S.ChiBurst:IsCastableP() and (true) then
      if HR.Cast(S.ChiBurst) then return ""; end
    end
    -- chi_wave
    if S.ChiWave:IsCastableP() and (true) then
      if HR.Cast(S.ChiWave) then return ""; end
    end
  end
  local function Aoe()
    -- call_action_list,name=cd
    if (true) then
      local ShouldReturn = Cd(); if ShouldReturn then return ShouldReturn; end
    end
    -- energizing_elixir,if=!prev_gcd.1.tiger_palm&chi<=1&(cooldown.rising_sun_kick.remains=0|(artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains=0)|energy<50)
    if S.EnergizingElixir:IsCastableP() and HR.CDsON() and (not Player:PrevGCDP(1, S.TigerPalm) and Player:Chi() <= 1 and (S.RisingSunKick:CooldownRemainsP() == 0 or (S.StrikeoftheWindlord:ArtifactEnabled() and S.StrikeoftheWindlord:CooldownRemainsP() == 0) or Player:Energy() < 50)) then
      if HR.Cast(S.EnergizingElixir, Settings.Windwalker.OffGCDasOffGCD.EnergizingElixir) then return ""; end
    end
    -- arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
    if S.ArcaneTorrent:IsCastableP() and HR.CDsON() and (Player:ChiMax() - Player:Chi() >= 1 and Player:EnergyTimeToMaxPredicted() >= 0.5) then
      if HR.Cast(S.ArcaneTorrent, Settings.Windwalker.OffGCDasOffGCD.ArcaneTorrent) then return ""; end
    end
    -- fists_of_fury,if=talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.serenity.remains>=5&energy.time_to_max>2
    if S.FistsofFury:IsCastableP() and (S.Serenity:IsAvailable() and not I.DrinkingHornCover:IsEquipped() and S.Serenity:CooldownRemainsP() >= 5 and Player:EnergyTimeToMaxPredicted() > 2) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- fists_of_fury,if=talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.serenity.remains>=15|cooldown.serenity.remains<=4)&energy.time_to_max>2
    if S.FistsofFury:IsCastableP() and (S.Serenity:IsAvailable() and I.DrinkingHornCover:IsEquipped() and (S.Serenity:CooldownRemainsP() >= 15 or S.Serenity:CooldownRemainsP() <= 4) and Player:EnergyTimeToMaxPredicted() > 2) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- fists_of_fury,if=!talent.serenity.enabled&energy.time_to_max>2
    if S.FistsofFury:IsCastableP() and (not S.Serenity:IsAvailable() and Player:EnergyTimeToMaxPredicted() > 2) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- fists_of_fury,if=cooldown.rising_sun_kick.remains>=3.5&chi<=5
    if S.FistsofFury:IsCastableP() and (S.RisingSunKick:CooldownRemainsP() >= 3.5 and Player:Chi() <= 5) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- whirling_dragon_punch
    if S.WhirlingDragonPunch:IsCastableP() and (true) then
      if HR.Cast(S.WhirlingDragonPunch) then return ""; end
    end
    -- strike_of_the_windlord,if=!talent.serenity.enabled|cooldown.serenity.remains>=10
    if S.StrikeoftheWindlord:IsCastableP() and HR.CDsON() and (not S.Serenity:IsAvailable() or S.Serenity:CooldownRemainsP() >= 10) then
      if HR.Cast(S.StrikeoftheWindlord) then return ""; end
    end
    -- rising_sun_kick,target_if=cooldown.whirling_dragon_punch.remains>=gcd&!prev_gcd.1.rising_sun_kick&cooldown.fists_of_fury.remains>gcd
    if S.RisingSunKick:IsCastableP() and (true) then
      if HR.Cast(S.RisingSunKick) then return ""; end
    end
    -- rushing_jade_wind,if=chi.max-chi>1&!prev_gcd.1.rushing_jade_wind
    if S.RushingJadeWind:IsCastableP() and (Player:ChiMax() - Player:Chi() > 1 and not Player:PrevGCDP(1, S.RushingJadeWind)) then
      if HR.Cast(S.RushingJadeWind) then return ""; end
    end
    -- chi_burst,if=chi<=3&(cooldown.rising_sun_kick.remains>=5|cooldown.whirling_dragon_punch.remains>=5)&energy.time_to_max>1
    if S.ChiBurst:IsCastableP() and (Player:Chi() <= 3 and (S.RisingSunKick:CooldownRemainsP() >= 5 or S.WhirlingDragonPunch:CooldownRemainsP() >= 5) and Player:EnergyTimeToMaxPredicted() > 1) then
      if HR.Cast(S.ChiBurst) then return ""; end
    end
    -- chi_burst
    if S.ChiBurst:IsCastableP() and (true) then
      if HR.Cast(S.ChiBurst) then return ""; end
    end
    -- spinning_crane_kick,if=(active_enemies>=3|(buff.bok_proc.up&chi.max-chi>=0))&!prev_gcd.1.spinning_crane_kick&set_bonus.tier21_4pc
    if S.SpinningCraneKick:IsCastableP() and ((Cache.EnemiesCount[8] >= 3 or (Player:BuffP(S.BokProcBuff) and Player:ChiMax() - Player:Chi() >= 0)) and not Player:PrevGCDP(1, S.SpinningCraneKick) and HL.Tier21_4Pc) then
      if HR.Cast(S.SpinningCraneKick) then return ""; end
    end
    -- spinning_crane_kick,if=active_enemies>=3&!prev_gcd.1.spinning_crane_kick
    if S.SpinningCraneKick:IsCastableP() and (Cache.EnemiesCount[8] >= 3 and not Player:PrevGCDP(1, S.SpinningCraneKick)) then
      if HR.Cast(S.SpinningCraneKick) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&(!set_bonus.tier19_2pc|talent.serenity.enabled)
    if S.BlackoutKick:IsCastableP() and (not Player:PrevGCDP(1, S.BlackoutKick) and Player:ChiMax() - Player:Chi() >= 1 and HL.Tier21_4Pc and (not HL.Tier19_2Pc or S.Serenity:IsAvailable())) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(chi>1|buff.bok_proc.up|(talent.energizing_elixir.enabled&cooldown.energizing_elixir.remains<cooldown.fists_of_fury.remains))&((cooldown.rising_sun_kick.remains>1&(!artifact.strike_of_the_windlord.enabled|cooldown.strike_of_the_windlord.remains>1)|chi>4)&(cooldown.fists_of_fury.remains>1|chi>2)|prev_gcd.1.tiger_palm)&!prev_gcd.1.blackout_kick
    if S.BlackoutKick:IsCastableP() and ((Player:Chi() > 1 or Player:BuffP(S.BokProcBuff) or (S.EnergizingElixir:IsAvailable() and S.EnergizingElixir:CooldownRemainsP() < S.FistsofFury:CooldownRemainsP())) and ((S.RisingSunKick:CooldownRemainsP() > 1 and (not S.StrikeoftheWindlord:ArtifactEnabled() or S.StrikeoftheWindlord:CooldownRemainsP() > 1) or Player:Chi() > 4) and (S.FistsofFury:CooldownRemainsP() > 1 or Player:Chi() > 2) or Player:PrevGCDP(1, S.TigerPalm)) and not Player:PrevGCDP(1, S.BlackoutKick)) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
    -- crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=19&energy.time_to_max>3
    if S.CracklingJadeLightning:IsCastableP() and (I.TheEmperorsCapacitor:IsEquipped() and Player:BuffStackP(S.TheEmperorsCapacitorBuff) >= 19 and Player:EnergyTimeToMaxPredicted() > 3) then
      if HR.Cast(S.CracklingJadeLightning) then return ""; end
    end
    -- crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=14&cooldown.serenity.remains<13&talent.serenity.enabled&energy.time_to_max>3
    if S.CracklingJadeLightning:IsCastableP() and (I.TheEmperorsCapacitor:IsEquipped() and Player:BuffStackP(S.TheEmperorsCapacitorBuff) >= 14 and S.Serenity:CooldownRemainsP() < 13 and S.Serenity:IsAvailable() and Player:EnergyTimeToMaxPredicted() > 3) then
      if HR.Cast(S.CracklingJadeLightning) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&buff.bok_proc.up
    if S.BlackoutKick:IsCastableP() and (not Player:PrevGCDP(1, S.BlackoutKick) and Player:ChiMax() - Player:Chi() >= 1 and HL.Tier21_4Pc and Player:BuffP(S.BokProcBuff)) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
    -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&(chi.max-chi>=2|energy.time_to_max<3)
    if S.TigerPalm:IsCastableP() and (not Player:PrevGCDP(1, S.TigerPalm) and not Player:PrevGCDP(1, S.EnergizingElixir) and (Player:ChiMax() - Player:Chi() >= 2 or Player:EnergyTimeToMaxPredicted() < 3)) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy.time_to_max<=1&chi.max-chi>=2
    if S.TigerPalm:IsCastableP() and (not Player:PrevGCDP(1, S.TigerPalm) and not Player:PrevGCDP(1, S.EnergizingElixir) and Player:EnergyTimeToMaxPredicted() <= 1 and Player:ChiMax() - Player:Chi() >= 2) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- chi_wave,if=chi<=3&(cooldown.rising_sun_kick.remains>=5|cooldown.whirling_dragon_punch.remains>=5)&energy.time_to_max>1
    if S.ChiWave:IsCastableP() and (Player:Chi() <= 3 and (S.RisingSunKick:CooldownRemainsP() >= 5 or S.WhirlingDragonPunch:CooldownRemainsP() >= 5) and Player:EnergyTimeToMaxPredicted() > 1) then
      if HR.Cast(S.ChiWave) then return ""; end
    end
    -- chi_wave
    if S.ChiWave:IsCastableP() and (true) then
      if HR.Cast(S.ChiWave) then return ""; end
    end
  end
  local function Cd()
    -- invoke_xuen_the_white_tiger
    if S.InvokeXuentheWhiteTiger:IsCastableP() and HR.CDsON() and (true) then
      if HR.Cast(S.InvokeXuentheWhiteTiger, Settings.Windwalker.OffGCDasOffGCD.InvokeXuentheWhiteTiger) then return ""; end
    end
    -- blood_fury
    if S.BloodFury:IsCastableP() and HR.CDsON() and (true) then
      if HR.Cast(S.BloodFury, Settings.Windwalker.OffGCDasOffGCD.BloodFury) then return ""; end
    end
    -- berserking
    if S.Berserking:IsCastableP() and HR.CDsON() and (true) then
      if HR.Cast(S.Berserking, Settings.Windwalker.OffGCDasOffGCD.Berserking) then return ""; end
    end
    -- arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
    if S.ArcaneTorrent:IsCastableP() and HR.CDsON() and (Player:ChiMax() - Player:Chi() >= 1 and Player:EnergyTimeToMaxPredicted() >= 0.5) then
      if HR.Cast(S.ArcaneTorrent, Settings.Windwalker.OffGCDasOffGCD.ArcaneTorrent) then return ""; end
    end
    -- touch_of_death,cycle_targets=1,max_cycle_targets=2,if=!artifact.gale_burst.enabled&equipped.hidden_masters_forbidden_touch&!prev_gcd.1.touch_of_death
    if S.TouchofDeath:IsCastableP() and HR.CDsON() and (not S.GaleBurst:ArtifactEnabled() and I.HiddenMastersForbiddenTouch:IsEquipped() and not Player:PrevGCDP(1, S.TouchofDeath)) then
      if HR.Cast(S.TouchofDeath) then return ""; end
    end
    -- touch_of_death,if=!artifact.gale_burst.enabled&!equipped.hidden_masters_forbidden_touch
    if S.TouchofDeath:IsCastableP() and HR.CDsON() and (not S.GaleBurst:ArtifactEnabled() and not I.HiddenMastersForbiddenTouch:IsEquipped()) then
      if HR.Cast(S.TouchofDeath) then return ""; end
    end
    -- touch_of_death,cycle_targets=1,max_cycle_targets=2,if=artifact.gale_burst.enabled&((talent.serenity.enabled&cooldown.serenity.remains<=1)|chi>=2)&(cooldown.strike_of_the_windlord.remains<8|cooldown.fists_of_fury.remains<=4)&cooldown.rising_sun_kick.remains<7&!prev_gcd.1.touch_of_death
    if S.TouchofDeath:IsCastableP() and HR.CDsON() and (S.GaleBurst:ArtifactEnabled() and ((S.Serenity:IsAvailable() and S.Serenity:CooldownRemainsP() <= 1) or Player:Chi() >= 2) and (S.StrikeoftheWindlord:CooldownRemainsP() < 8 or S.FistsofFury:CooldownRemainsP() <= 4) and S.RisingSunKick:CooldownRemainsP() < 7 and not Player:PrevGCDP(1, S.TouchofDeath)) then
      if HR.Cast(S.TouchofDeath) then return ""; end
    end
  end
  local function Sef()
    -- tiger_palm,target_if=debuff.mark_of_the_crane.down,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy=energy.max&chi<1
    if S.TigerPalm:IsCastableP() and (not Player:PrevGCDP(1, S.TigerPalm) and not Player:PrevGCDP(1, S.EnergizingElixir) and Player:Energy() == Player:EnergyMax() and Player:Chi() < 1) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
    if S.ArcaneTorrent:IsCastableP() and HR.CDsON() and (Player:ChiMax() - Player:Chi() >= 1 and Player:EnergyTimeToMaxPredicted() >= 0.5) then
      if HR.Cast(S.ArcaneTorrent, Settings.Windwalker.OffGCDasOffGCD.ArcaneTorrent) then return ""; end
    end
    -- call_action_list,name=cd
    if (true) then
      local ShouldReturn = Cd(); if ShouldReturn then return ShouldReturn; end
    end
    -- storm_earth_and_fire,if=!buff.storm_earth_and_fire.up
    if S.StormEarthandFire:IsCastableP() and HR.CDsON() and (not Player:BuffP(S.StormEarthandFireBuff)) then
      if HR.Cast(S.StormEarthandFire, Settings.Windwalker.OffGCDasOffGCD.StormEarthandFire) then return ""; end
    end
    -- call_action_list,name=aoe,if=active_enemies>3
    if (Cache.EnemiesCount[8] > 3) then
      local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=st,if=active_enemies<=3
    if (Cache.EnemiesCount[8] <= 3) then
      local ShouldReturn = St(); if ShouldReturn then return ShouldReturn; end
    end
  end
  local function Serenity()
    -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy=energy.max&chi<1&!buff.serenity.up
    if S.TigerPalm:IsCastableP() and (not Player:PrevGCDP(1, S.TigerPalm) and not Player:PrevGCDP(1, S.EnergizingElixir) and Player:Energy() == Player:EnergyMax() and Player:Chi() < 1 and not Player:BuffP(S.SerenityBuff)) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- call_action_list,name=cd
    if (true) then
      local ShouldReturn = Cd(); if ShouldReturn then return ShouldReturn; end
    end
    -- serenity
    if S.Serenity:IsCastableP() and HR.CDsON() and (true) then
      if HR.Cast(S.Serenity, Settings.Windwalker.OffGCDasOffGCD.Serenity) then return ""; end
    end
    -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies<3
    if S.RisingSunKick:IsCastableP() and (Cache.EnemiesCount[8] < 3) then
      if HR.Cast(S.RisingSunKick) then return ""; end
    end
    -- strike_of_the_windlord
    if S.StrikeoftheWindlord:IsCastableP() and HR.CDsON() and (true) then
      if HR.Cast(S.StrikeoftheWindlord) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(!prev_gcd.1.blackout_kick)&(prev_gcd.1.strike_of_the_windlord|prev_gcd.1.fists_of_fury)&active_enemies<2
    if S.BlackoutKick:IsCastableP() and ((not Player:PrevGCDP(1, S.BlackoutKick)) and (Player:PrevGCDP(1, S.StrikeoftheWindlord) or Player:PrevGCDP(1, S.FistsofFury)) and Cache.EnemiesCount[8] < 2) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
    -- fists_of_fury,if=((equipped.drinking_horn_cover&buff.pressure_point.remains<=2&set_bonus.tier20_4pc)&(cooldown.rising_sun_kick.remains>1|active_enemies>1)),interrupt=1
    if S.FistsofFury:IsCastableP() and (((I.DrinkingHornCover:IsEquipped() and Player:BuffRemainsP(S.PressurePointBuff) <= 2 and HL.Tier20_4Pc) and (S.RisingSunKick:CooldownRemainsP() > 1 or Cache.EnemiesCount[8] > 1))) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- fists_of_fury,if=((!equipped.drinking_horn_cover|buff.bloodlust.up|buff.serenity.remains<1)&(cooldown.rising_sun_kick.remains>1|active_enemies>1)),interrupt=1
    if S.FistsofFury:IsCastableP() and (((not I.DrinkingHornCover:IsEquipped() or Player:HasHeroism() or Player:BuffRemainsP(S.SerenityBuff) < 1) and (S.RisingSunKick:CooldownRemainsP() > 1 or Cache.EnemiesCount[8] > 1))) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- spinning_crane_kick,if=active_enemies>=3&!prev_gcd.1.spinning_crane_kick
    if S.SpinningCraneKick:IsCastableP() and (Cache.EnemiesCount[8] >= 3 and not Player:PrevGCDP(1, S.SpinningCraneKick)) then
      if HR.Cast(S.SpinningCraneKick) then return ""; end
    end
    -- rushing_jade_wind,if=!prev_gcd.1.rushing_jade_wind&buff.rushing_jade_wind.down&buff.serenity.remains>=4
    if S.RushingJadeWind:IsCastableP() and (not Player:PrevGCDP(1, S.RushingJadeWind) and Player:BuffDownP(S.RushingJadeWindBuff) and Player:BuffRemainsP(S.SerenityBuff) >= 4) then
      if HR.Cast(S.RushingJadeWind) then return ""; end
    end
    -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies>=3
    if S.RisingSunKick:IsCastableP() and (Cache.EnemiesCount[8] >= 3) then
      if HR.Cast(S.RisingSunKick) then return ""; end
    end
    -- rushing_jade_wind,if=!prev_gcd.1.rushing_jade_wind&buff.rushing_jade_wind.down&active_enemies>1
    if S.RushingJadeWind:IsCastableP() and (not Player:PrevGCDP(1, S.RushingJadeWind) and Player:BuffDownP(S.RushingJadeWindBuff) and Cache.EnemiesCount[8] > 1) then
      if HR.Cast(S.RushingJadeWind) then return ""; end
    end
    -- spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick
    if S.SpinningCraneKick:IsCastableP() and (not Player:PrevGCDP(1, S.SpinningCraneKick)) then
      if HR.Cast(S.SpinningCraneKick) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick
    if S.BlackoutKick:IsCastableP() and (not Player:PrevGCDP(1, S.BlackoutKick)) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
  end
  local function SerenityOpener()
    -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy=energy.max&chi<1&!buff.serenity.up&cooldown.fists_of_fury.remains<=0
    if S.TigerPalm:IsCastableP() and (not Player:PrevGCDP(1, S.TigerPalm) and not Player:PrevGCDP(1, S.EnergizingElixir) and Player:Energy() == Player:EnergyMax() and Player:Chi() < 1 and not Player:BuffP(S.SerenityBuff) and S.FistsofFury:CooldownRemainsP() <= 0) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
    if S.ArcaneTorrent:IsCastableP() and HR.CDsON() and (Player:ChiMax() - Player:Chi() >= 1 and Player:EnergyTimeToMaxPredicted() >= 0.5) then
      if HR.Cast(S.ArcaneTorrent, Settings.Windwalker.OffGCDasOffGCD.ArcaneTorrent) then return ""; end
    end
    -- call_action_list,name=cd,if=cooldown.fists_of_fury.remains>1
    if (S.FistsofFury:CooldownRemainsP() > 1) then
      local ShouldReturn = Cd(); if ShouldReturn then return ShouldReturn; end
    end
    -- serenity,if=cooldown.fists_of_fury.remains>1
    if S.Serenity:IsCastableP() and HR.CDsON() and (S.FistsofFury:CooldownRemainsP() > 1) then
      if HR.Cast(S.Serenity, Settings.Windwalker.OffGCDasOffGCD.Serenity) then return ""; end
    end
    -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies<3&buff.serenity.up
    if S.RisingSunKick:IsCastableP() and (Cache.EnemiesCount[8] < 3 and Player:BuffP(S.SerenityBuff)) then
      if HR.Cast(S.RisingSunKick) then return ""; end
    end
    -- strike_of_the_windlord,if=buff.serenity.up
    if S.StrikeoftheWindlord:IsCastableP() and HR.CDsON() and (Player:BuffP(S.SerenityBuff)) then
      if HR.Cast(S.StrikeoftheWindlord) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(!prev_gcd.1.blackout_kick)&(prev_gcd.1.strike_of_the_windlord)
    if S.BlackoutKick:IsCastableP() and ((not Player:PrevGCDP(1, S.BlackoutKick)) and (Player:PrevGCDP(1, S.StrikeoftheWindlord))) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
    -- fists_of_fury,if=cooldown.rising_sun_kick.remains>1|buff.serenity.down,interrupt=1
    if S.FistsofFury:IsCastableP() and (S.RisingSunKick:CooldownRemainsP() > 1 or Player:BuffDownP(S.SerenityBuff)) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.serenity.down&chi<=2&cooldown.serenity.remains<=0&prev_gcd.1.tiger_palm
    if S.BlackoutKick:IsCastableP() and (Player:BuffDownP(S.SerenityBuff) and Player:Chi() <= 2 and S.Serenity:CooldownRemainsP() <= 0 and Player:PrevGCDP(1, S.TigerPalm)) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
    -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&chi=1
    if S.TigerPalm:IsCastableP() and (not Player:PrevGCDP(1, S.TigerPalm) and not Player:PrevGCDP(1, S.EnergizingElixir) and Player:Chi() == 1) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
  end
  local function St()
    -- call_action_list,name=cd
    if (true) then
      local ShouldReturn = Cd(); if ShouldReturn then return ShouldReturn; end
    end
    -- energizing_elixir,if=!prev_gcd.1.tiger_palm&chi<=1&(cooldown.rising_sun_kick.remains=0|(artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains=0)|energy<50)
    if S.EnergizingElixir:IsCastableP() and HR.CDsON() and (not Player:PrevGCDP(1, S.TigerPalm) and Player:Chi() <= 1 and (S.RisingSunKick:CooldownRemainsP() == 0 or (S.StrikeoftheWindlord:ArtifactEnabled() and S.StrikeoftheWindlord:CooldownRemainsP() == 0) or Player:Energy() < 50)) then
      if HR.Cast(S.EnergizingElixir, Settings.Windwalker.OffGCDasOffGCD.EnergizingElixir) then return ""; end
    end
    -- arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
    if S.ArcaneTorrent:IsCastableP() and HR.CDsON() and (Player:ChiMax() - Player:Chi() >= 1 and Player:EnergyTimeToMaxPredicted() >= 0.5) then
      if HR.Cast(S.ArcaneTorrent, Settings.Windwalker.OffGCDasOffGCD.ArcaneTorrent) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&buff.bok_proc.up
    if S.BlackoutKick:IsCastableP() and (not Player:PrevGCDP(1, S.BlackoutKick) and Player:ChiMax() - Player:Chi() >= 1 and HL.Tier21_4Pc and Player:BuffP(S.BokProcBuff)) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
    -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy.time_to_max<=1&chi.max-chi>=2
    if S.TigerPalm:IsCastableP() and (not Player:PrevGCDP(1, S.TigerPalm) and not Player:PrevGCDP(1, S.EnergizingElixir) and Player:EnergyTimeToMaxPredicted() <= 1 and Player:ChiMax() - Player:Chi() >= 2) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- strike_of_the_windlord,if=!talent.serenity.enabled|cooldown.serenity.remains>=10
    if S.StrikeoftheWindlord:IsCastableP() and HR.CDsON() and (not S.Serenity:IsAvailable() or S.Serenity:CooldownRemainsP() >= 10) then
      if HR.Cast(S.StrikeoftheWindlord) then return ""; end
    end
    -- whirling_dragon_punch
    if S.WhirlingDragonPunch:IsCastableP() and (true) then
      if HR.Cast(S.WhirlingDragonPunch) then return ""; end
    end
    -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=((chi>=3&energy>=40)|chi>=5)&(!talent.serenity.enabled|cooldown.serenity.remains>=6)
    if S.RisingSunKick:IsCastableP() and (((Player:Chi() >= 3 and Player:Energy() >= 40) or Player:Chi() >= 5) and (not S.Serenity:IsAvailable() or S.Serenity:CooldownRemainsP() >= 6)) then
      if HR.Cast(S.RisingSunKick) then return ""; end
    end
    -- fists_of_fury,if=talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.serenity.remains>=5&energy.time_to_max>2
    if S.FistsofFury:IsCastableP() and (S.Serenity:IsAvailable() and not I.DrinkingHornCover:IsEquipped() and S.Serenity:CooldownRemainsP() >= 5 and Player:EnergyTimeToMaxPredicted() > 2) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- fists_of_fury,if=talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.serenity.remains>=15|cooldown.serenity.remains<=4)&energy.time_to_max>2
    if S.FistsofFury:IsCastableP() and (S.Serenity:IsAvailable() and I.DrinkingHornCover:IsEquipped() and (S.Serenity:CooldownRemainsP() >= 15 or S.Serenity:CooldownRemainsP() <= 4) and Player:EnergyTimeToMaxPredicted() > 2) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- fists_of_fury,if=!talent.serenity.enabled&energy.time_to_max>2
    if S.FistsofFury:IsCastableP() and (not S.Serenity:IsAvailable() and Player:EnergyTimeToMaxPredicted() > 2) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- fists_of_fury,if=cooldown.rising_sun_kick.remains>=3.5&chi<=5
    if S.FistsofFury:IsCastableP() and (S.RisingSunKick:CooldownRemainsP() >= 3.5 and Player:Chi() <= 5) then
      if HR.Cast(S.FistsofFury) then return ""; end
    end
    -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!talent.serenity.enabled|cooldown.serenity.remains>=5
    if S.RisingSunKick:IsCastableP() and (not S.Serenity:IsAvailable() or S.Serenity:CooldownRemainsP() >= 5) then
      if HR.Cast(S.RisingSunKick) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&(!set_bonus.tier19_2pc|talent.serenity.enabled)
    if S.BlackoutKick:IsCastableP() and (not Player:PrevGCDP(1, S.BlackoutKick) and Player:ChiMax() - Player:Chi() >= 1 and HL.Tier21_4Pc and (not HL.Tier19_2Pc or S.Serenity:IsAvailable())) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
    -- spinning_crane_kick,if=(active_enemies>=3|(buff.bok_proc.up&chi.max-chi>=0))&!prev_gcd.1.spinning_crane_kick&set_bonus.tier21_4pc
    if S.SpinningCraneKick:IsCastableP() and ((Cache.EnemiesCount[8] >= 3 or (Player:BuffP(S.BokProcBuff) and Player:ChiMax() - Player:Chi() >= 0)) and not Player:PrevGCDP(1, S.SpinningCraneKick) and HL.Tier21_4Pc) then
      if HR.Cast(S.SpinningCraneKick) then return ""; end
    end
    -- crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=19&energy.time_to_max>3
    if S.CracklingJadeLightning:IsCastableP() and (I.TheEmperorsCapacitor:IsEquipped() and Player:BuffStackP(S.TheEmperorsCapacitorBuff) >= 19 and Player:EnergyTimeToMaxPredicted() > 3) then
      if HR.Cast(S.CracklingJadeLightning) then return ""; end
    end
    -- crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=14&cooldown.serenity.remains<13&talent.serenity.enabled&energy.time_to_max>3
    if S.CracklingJadeLightning:IsCastableP() and (I.TheEmperorsCapacitor:IsEquipped() and Player:BuffStackP(S.TheEmperorsCapacitorBuff) >= 14 and S.Serenity:CooldownRemainsP() < 13 and S.Serenity:IsAvailable() and Player:EnergyTimeToMaxPredicted() > 3) then
      if HR.Cast(S.CracklingJadeLightning) then return ""; end
    end
    -- spinning_crane_kick,if=active_enemies>=3&!prev_gcd.1.spinning_crane_kick
    if S.SpinningCraneKick:IsCastableP() and (Cache.EnemiesCount[8] >= 3 and not Player:PrevGCDP(1, S.SpinningCraneKick)) then
      if HR.Cast(S.SpinningCraneKick) then return ""; end
    end
    -- rushing_jade_wind,if=chi.max-chi>1&!prev_gcd.1.rushing_jade_wind
    if S.RushingJadeWind:IsCastableP() and (Player:ChiMax() - Player:Chi() > 1 and not Player:PrevGCDP(1, S.RushingJadeWind)) then
      if HR.Cast(S.RushingJadeWind) then return ""; end
    end
    -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(chi>1|buff.bok_proc.up|(talent.energizing_elixir.enabled&cooldown.energizing_elixir.remains<cooldown.fists_of_fury.remains))&((cooldown.rising_sun_kick.remains>1&(!artifact.strike_of_the_windlord.enabled|cooldown.strike_of_the_windlord.remains>1)|chi>4)&(cooldown.fists_of_fury.remains>1|chi>2)|prev_gcd.1.tiger_palm)&!prev_gcd.1.blackout_kick
    if S.BlackoutKick:IsCastableP() and ((Player:Chi() > 1 or Player:BuffP(S.BokProcBuff) or (S.EnergizingElixir:IsAvailable() and S.EnergizingElixir:CooldownRemainsP() < S.FistsofFury:CooldownRemainsP())) and ((S.RisingSunKick:CooldownRemainsP() > 1 and (not S.StrikeoftheWindlord:ArtifactEnabled() or S.StrikeoftheWindlord:CooldownRemainsP() > 1) or Player:Chi() > 4) and (S.FistsofFury:CooldownRemainsP() > 1 or Player:Chi() > 2) or Player:PrevGCDP(1, S.TigerPalm)) and not Player:PrevGCDP(1, S.BlackoutKick)) then
      if HR.Cast(S.BlackoutKick) then return ""; end
    end
    -- chi_wave,if=chi<=3&(cooldown.rising_sun_kick.remains>=5|cooldown.whirling_dragon_punch.remains>=5)&energy.time_to_max>1
    if S.ChiWave:IsCastableP() and (Player:Chi() <= 3 and (S.RisingSunKick:CooldownRemainsP() >= 5 or S.WhirlingDragonPunch:CooldownRemainsP() >= 5) and Player:EnergyTimeToMaxPredicted() > 1) then
      if HR.Cast(S.ChiWave) then return ""; end
    end
    -- chi_burst,if=chi<=3&(cooldown.rising_sun_kick.remains>=5|cooldown.whirling_dragon_punch.remains>=5)&energy.time_to_max>1
    if S.ChiBurst:IsCastableP() and (Player:Chi() <= 3 and (S.RisingSunKick:CooldownRemainsP() >= 5 or S.WhirlingDragonPunch:CooldownRemainsP() >= 5) and Player:EnergyTimeToMaxPredicted() > 1) then
      if HR.Cast(S.ChiBurst) then return ""; end
    end
    -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&(chi.max-chi>=2|energy.time_to_max<3)
    if S.TigerPalm:IsCastableP() and (not Player:PrevGCDP(1, S.TigerPalm) and not Player:PrevGCDP(1, S.EnergizingElixir) and (Player:ChiMax() - Player:Chi() >= 2 or Player:EnergyTimeToMaxPredicted() < 3)) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- chi_wave
    if S.ChiWave:IsCastableP() and (true) then
      if HR.Cast(S.ChiWave) then return ""; end
    end
    -- chi_burst
    if S.ChiBurst:IsCastableP() and (true) then
      if HR.Cast(S.ChiBurst) then return ""; end
    end
  end
  -- call precombat
  if not Player:AffectingCombat() then
    local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
  end
  -- auto_attack
  -- spear_hand_strike,if=target.debuff.casting.react
  if S.SpearHandStrike:IsCastableP() and Settings.General.InterruptEnabled and Target:IsInterruptible() and (Target:IsCasting()) then
    if HR.CastAnnotated(S.SpearHandStrike, false, "Interrupt") then return ""; end
  end
  -- touch_of_karma,interval=90,pct_health=0.5
  if S.TouchofKarma:IsCastableP() and (true) then
    if HR.Cast(S.TouchofKarma, Settings.Windwalker.OffGCDasOffGCD.TouchofKarma) then return ""; end
  end
  -- potion,if=buff.serenity.up|buff.storm_earth_and_fire.up|(!talent.serenity.enabled&trinket.proc.agility.react)|buff.bloodlust.react|target.time_to_die<=60
  if I.ProlongedPower:IsReady() and Settings.Commons.UsePotions and (Player:BuffP(S.SerenityBuff) or Player:BuffP(S.StormEarthandFireBuff) or (not S.Serenity:IsAvailable() and bool(trinket.proc.agility.react)) or Player:HasHeroism() or Target:TimeToDie() <= 60) then
    if HR.CastSuggested(I.ProlongedPower) then return ""; end
  end
  -- touch_of_death,if=target.time_to_die<=9
  if S.TouchofDeath:IsCastableP() and HR.CDsON() and (Target:TimeToDie() <= 9) then
    if HR.Cast(S.TouchofDeath) then return ""; end
  end
  -- call_action_list,name=serenity,if=(talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up
  if ((S.Serenity:IsAvailable() and S.Serenity:CooldownRemainsP() <= 0) or Player:BuffP(S.SerenityBuff)) then
    local ShouldReturn = Serenity(); if ShouldReturn then return ShouldReturn; end
  end
  -- call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
  if (not S.Serenity:IsAvailable() and (Player:BuffP(S.StormEarthandFireBuff) or S.StormEarthandFire:ChargesP() == 2)) then
    local ShouldReturn = Sef(); if ShouldReturn then return ShouldReturn; end
  end
  -- call_action_list,name=sef,if=!talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.strike_of_the_windlord.remains<=18&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1|target.time_to_die<=25|cooldown.touch_of_death.remains>112)&cooldown.storm_earth_and_fire.charges=1
  if (not S.Serenity:IsAvailable() and I.DrinkingHornCover:IsEquipped() and (S.StrikeoftheWindlord:CooldownRemainsP() <= 18 and S.FistsofFury:CooldownRemainsP() <= 12 and Player:Chi() >= 3 and S.RisingSunKick:CooldownRemainsP() <= 1 or Target:TimeToDie() <= 25 or S.TouchofDeath:CooldownRemainsP() > 112) and S.StormEarthandFire:ChargesP() == 1) then
    local ShouldReturn = Sef(); if ShouldReturn then return ShouldReturn; end
  end
  -- call_action_list,name=sef,if=!talent.serenity.enabled&!equipped.drinking_horn_cover&(cooldown.strike_of_the_windlord.remains<=14&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1|target.time_to_die<=15|cooldown.touch_of_death.remains>112)&cooldown.storm_earth_and_fire.charges=1
  if (not S.Serenity:IsAvailable() and not I.DrinkingHornCover:IsEquipped() and (S.StrikeoftheWindlord:CooldownRemainsP() <= 14 and S.FistsofFury:CooldownRemainsP() <= 6 and Player:Chi() >= 3 and S.RisingSunKick:CooldownRemainsP() <= 1 or Target:TimeToDie() <= 15 or S.TouchofDeath:CooldownRemainsP() > 112) and S.StormEarthandFire:ChargesP() == 1) then
    local ShouldReturn = Sef(); if ShouldReturn then return ShouldReturn; end
  end
  -- call_action_list,name=aoe,if=active_enemies>3
  if (Cache.EnemiesCount[8] > 3) then
    local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
  end
  -- call_action_list,name=st,if=active_enemies<=3
  if (Cache.EnemiesCount[8] <= 3) then
    local ShouldReturn = St(); if ShouldReturn then return ShouldReturn; end
  end
end

HR.SetAPL(269, APL)
