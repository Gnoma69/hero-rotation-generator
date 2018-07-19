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
if not Spell.Druid then Spell.Druid = {} end
Spell.Druid.Balance = {
  MoonkinForm                           = Spell(24858),
  SolarWrath                            = Spell(190984),
  FuryofElune                           = Spell(202770),
  CelestialAlignmentBuff                = Spell(194223),
  IncarnationBuff                       = Spell(102560),
  CelestialAlignment                    = Spell(194223),
  Incarnation                           = Spell(102560),
  ForceofNature                         = Spell(205636),
  Sunfire                               = Spell(93402),
  Moonfire                              = Spell(8921),
  StellarFlare                          = Spell(202347),
  LunarStrike                           = Spell(194153),
  LunarEmpowermentBuff                  = Spell(164547),
  SolarEmpowermentBuff                  = Spell(164545),
  Starsurge                             = Spell(78674),
  OnethsIntuitionBuff                   = Spell(209406),
  Starfall                              = Spell(191034),
  StarlordBuff                          = Spell(),
  NewMoon                               = Spell(202767),
  HalfMoon                              = Spell(202768),
  FullMoon                              = Spell(202771),
  WarriorofEluneBuff                    = Spell(202425),
  OnethsOverconfidenceBuff              = Spell(209407),
  BloodFury                             = Spell(20572),
  Berserking                            = Spell(26297),
  ArcaneTorrent                         = Spell(50613),
  LightsJudgment                        = Spell(),
  UseItems                              = Spell(),
  WarriorofElune                        = Spell(202425)
};
local S = Spell.Druid.Balance;

-- Items
if not Item.Druid then Item.Druid = {} end
Item.Druid.Balance = {
  ProlongedPower                   = Item(142117)
};
local I = Item.Druid.Balance;

-- Rotation Var
local ShouldReturn; -- Used to get the return string

-- GUI Settings
local Everyone = HR.Commons.Everyone;
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.Druid.Commons,
  Balance = HR.GUISettings.APL.Druid.Balance
};

-- Variables

local EnemyRanges = {40}
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

local function FutureAstralPower()
  local AstralPower=Player:AstralPower()
  if not Player:IsCasting() then
    return AstralPower
  else
    if Player:IsCasting(S.NewMoon) then
      return AstralPower + 10
    elseif Player:IsCasting(S.HalfMoon) then
      return AstralPower + 20
    elseif Player:IsCasting(S.FullMoon) then
      return AstralPower + 40
    elseif Player:IsCasting(S.SolarWrath) then
      return AstralPower
        + (Player:Buff(S.BlessingofElune) and 10 or 8)
          * ((Player:BuffRemainsP(S.CelestialAlignment) > 0
            or Player:BuffRemainsP(S.IncarnationChosenOfElune) > 0) and 2 or 1)
    elseif Player:IsCasting(S.LunarStrike) then
      return AstralPower
        + (Player:Buff(S.BlessingofElune) and 15 or 10)
          * ((Player:BuffRemainsP(S.CelestialAlignment) > 0
            or Player:BuffRemainsP(S.IncarnationChosenOfElune) > 0) and 2 or 1)
    else
      return AstralPower
    end
  end
end

--- ======= ACTION LISTS =======
local function APL()
  UpdateRanges()
  local function Precombat()
    -- flask
    -- food
    -- augmentation
    -- moonkin_form
    if S.MoonkinForm:IsCastableP() and (true) then
      if HR.Cast(S.MoonkinForm) then return ""; end
    end
    -- snapshot_stats
    -- potion
    if I.ProlongedPower:IsReady() and Settings.Commons.UsePotions and (true) then
      if HR.CastSuggested(I.ProlongedPower) then return ""; end
    end
    -- solar_wrath
    if S.SolarWrath:IsCastableP() and (true) then
      if HR.Cast(S.SolarWrath) then return ""; end
    end
  end
  local function Aoe()
    -- fury_of_elune,if=(buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30)
    if S.FuryofElune:IsCastableP() and ((Player:BuffP(S.CelestialAlignmentBuff) or Player:BuffP(S.IncarnationBuff)) or (S.CelestialAlignment:CooldownRemainsP() > 30 or S.Incarnation:CooldownRemainsP() > 30)) then
      if HR.Cast(S.FuryofElune) then return ""; end
    end
    -- force_of_nature,if=(buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30)
    if S.ForceofNature:IsCastableP() and ((Player:BuffP(S.CelestialAlignmentBuff) or Player:BuffP(S.IncarnationBuff)) or (S.CelestialAlignment:CooldownRemainsP() > 30 or S.Incarnation:CooldownRemainsP() > 30)) then
      if HR.Cast(S.ForceofNature) then return ""; end
    end
    -- sunfire,target_if=refreshable,if=astral_power.deficit>7&target.time_to_die>4
    if S.Sunfire:IsCastableP() and (Player:AstralPowerDeficit() > 7 and Target:TimeToDie() > 4) then
      if HR.Cast(S.Sunfire) then return ""; end
    end
    -- moonfire,target_if=refreshable,if=astral_power.deficit>7&target.time_to_die>4
    if S.Moonfire:IsCastableP() and (Player:AstralPowerDeficit() > 7 and Target:TimeToDie() > 4) then
      if HR.Cast(S.Moonfire) then return ""; end
    end
    -- stellar_flare,target_if=refreshable,if=target.time_to_die>10
    if S.StellarFlare:IsCastableP() and (Target:TimeToDie() > 10) then
      if HR.Cast(S.StellarFlare) then return ""; end
    end
    -- lunar_strike,if=(buff.lunar_empowerment.stack=3|buff.solar_empowerment.stack=2&buff.lunar_empowerment.stack=2&astral_power>=40)&astral_power.deficit>14
    if S.LunarStrike:IsCastableP() and ((Player:BuffStackP(S.LunarEmpowermentBuff) == 3 or Player:BuffStackP(S.SolarEmpowermentBuff) == 2 and Player:BuffStackP(S.LunarEmpowermentBuff) == 2 and FutureAstralPower() >= 40) and Player:AstralPowerDeficit() > 14) then
      if HR.Cast(S.LunarStrike) then return ""; end
    end
    -- solar_wrath,if=buff.solar_empowerment.stack=3&astral_power.deficit>10
    if S.SolarWrath:IsCastableP() and (Player:BuffStackP(S.SolarEmpowermentBuff) == 3 and Player:AstralPowerDeficit() > 10) then
      if HR.Cast(S.SolarWrath) then return ""; end
    end
    -- starsurge,if=buff.oneths_intuition.react|target.time_to_die<=4
    if S.Starsurge:IsCastableP() and (bool(Player:BuffStackP(S.OnethsIntuitionBuff)) or Target:TimeToDie() <= 4) then
      if HR.Cast(S.Starsurge) then return ""; end
    end
    -- starfall,if=!buff.starlord.up|buff.starlord.remains>=4
    if S.Starfall:IsCastableP() and (not Player:BuffP(S.StarlordBuff) or Player:BuffRemainsP(S.StarlordBuff) >= 4) then
      if HR.Cast(S.Starfall) then return ""; end
    end
    -- new_moon,if=astral_power.deficit>12
    if S.NewMoon:IsCastableP() and (Player:AstralPowerDeficit() > 12) then
      if HR.Cast(S.NewMoon) then return ""; end
    end
    -- half_moon,if=astral_power.deficit>22
    if S.HalfMoon:IsCastableP() and (Player:AstralPowerDeficit() > 22) then
      if HR.Cast(S.HalfMoon) then return ""; end
    end
    -- full_moon,if=astral_power.deficit>42
    if S.FullMoon:IsCastableP() and (Player:AstralPowerDeficit() > 42) then
      if HR.Cast(S.FullMoon) then return ""; end
    end
    -- solar_wrath,if=(buff.solar_empowerment.up&!buff.warrior_of_elune.up|buff.solar_empowerment.stack>=3)&buff.lunar_empowerment.stack<3
    if S.SolarWrath:IsCastableP() and ((Player:BuffP(S.SolarEmpowermentBuff) and not Player:BuffP(S.WarriorofEluneBuff) or Player:BuffStackP(S.SolarEmpowermentBuff) >= 3) and Player:BuffStackP(S.LunarEmpowermentBuff) < 3) then
      if HR.Cast(S.SolarWrath) then return ""; end
    end
    -- lunar_strike
    if S.LunarStrike:IsCastableP() and (true) then
      if HR.Cast(S.LunarStrike) then return ""; end
    end
    -- moonfire
    if S.Moonfire:IsCastableP() and (true) then
      if HR.Cast(S.Moonfire) then return ""; end
    end
  end
  local function St()
    -- fury_of_elune,if=(buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30)
    if S.FuryofElune:IsCastableP() and ((Player:BuffP(S.CelestialAlignmentBuff) or Player:BuffP(S.IncarnationBuff)) or (S.CelestialAlignment:CooldownRemainsP() > 30 or S.Incarnation:CooldownRemainsP() > 30)) then
      if HR.Cast(S.FuryofElune) then return ""; end
    end
    -- force_of_nature,if=(buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30)
    if S.ForceofNature:IsCastableP() and ((Player:BuffP(S.CelestialAlignmentBuff) or Player:BuffP(S.IncarnationBuff)) or (S.CelestialAlignment:CooldownRemainsP() > 30 or S.Incarnation:CooldownRemainsP() > 30)) then
      if HR.Cast(S.ForceofNature) then return ""; end
    end
    -- moonfire,target_if=refreshable,if=target.time_to_die>8
    if S.Moonfire:IsCastableP() and (Target:TimeToDie() > 8) then
      if HR.Cast(S.Moonfire) then return ""; end
    end
    -- sunfire,target_if=refreshable,if=target.time_to_die>8
    if S.Sunfire:IsCastableP() and (Target:TimeToDie() > 8) then
      if HR.Cast(S.Sunfire) then return ""; end
    end
    -- stellar_flare,target_if=refreshable,if=target.time_to_die>10
    if S.StellarFlare:IsCastableP() and (Target:TimeToDie() > 10) then
      if HR.Cast(S.StellarFlare) then return ""; end
    end
    -- solar_wrath,if=(buff.solar_empowerment.stack=3|buff.solar_empowerment.stack=2&buff.lunar_empowerment.stack=2&astral_power>=40)&astral_power.deficit>10
    if S.SolarWrath:IsCastableP() and ((Player:BuffStackP(S.SolarEmpowermentBuff) == 3 or Player:BuffStackP(S.SolarEmpowermentBuff) == 2 and Player:BuffStackP(S.LunarEmpowermentBuff) == 2 and FutureAstralPower() >= 40) and Player:AstralPowerDeficit() > 10) then
      if HR.Cast(S.SolarWrath) then return ""; end
    end
    -- lunar_strike,if=buff.lunar_empowerment.stack=3&astral_power.deficit>14
    if S.LunarStrike:IsCastableP() and (Player:BuffStackP(S.LunarEmpowermentBuff) == 3 and Player:AstralPowerDeficit() > 14) then
      if HR.Cast(S.LunarStrike) then return ""; end
    end
    -- starfall,if=buff.oneths_overconfidence.react
    if S.Starfall:IsCastableP() and (bool(Player:BuffStackP(S.OnethsOverconfidenceBuff))) then
      if HR.Cast(S.Starfall) then return ""; end
    end
    -- starsurge,if=!buff.starlord.up|buff.starlord.remains>=4|(gcd.max*(astral_power%40))>target.time_to_die
    if S.Starsurge:IsCastableP() and (not Player:BuffP(S.StarlordBuff) or Player:BuffRemainsP(S.StarlordBuff) >= 4 or (Player:GCD() * (FutureAstralPower() / 40)) > Target:TimeToDie()) then
      if HR.Cast(S.Starsurge) then return ""; end
    end
    -- lunar_strike,if=(buff.warrior_of_elune.up|!buff.solar_empowerment.up)&buff.lunar_empowerment.up
    if S.LunarStrike:IsCastableP() and ((Player:BuffP(S.WarriorofEluneBuff) or not Player:BuffP(S.SolarEmpowermentBuff)) and Player:BuffP(S.LunarEmpowermentBuff)) then
      if HR.Cast(S.LunarStrike) then return ""; end
    end
    -- new_moon,if=astral_power.deficit>10
    if S.NewMoon:IsCastableP() and (Player:AstralPowerDeficit() > 10) then
      if HR.Cast(S.NewMoon) then return ""; end
    end
    -- half_moon,if=astral_power.deficit>20
    if S.HalfMoon:IsCastableP() and (Player:AstralPowerDeficit() > 20) then
      if HR.Cast(S.HalfMoon) then return ""; end
    end
    -- full_moon,if=astral_power.deficit>40
    if S.FullMoon:IsCastableP() and (Player:AstralPowerDeficit() > 40) then
      if HR.Cast(S.FullMoon) then return ""; end
    end
    -- solar_wrath
    if S.SolarWrath:IsCastableP() and (true) then
      if HR.Cast(S.SolarWrath) then return ""; end
    end
    -- moonfire
    if S.Moonfire:IsCastableP() and (true) then
      if HR.Cast(S.Moonfire) then return ""; end
    end
  end
  -- call precombat
  if not Player:AffectingCombat() then
    local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
  end
  -- potion,name=deadly_grace,if=buff.celestial_alignment.up|buff.incarnation.up
  if I.ProlongedPower:IsReady() and Settings.Commons.UsePotions and (Player:BuffP(S.CelestialAlignmentBuff) or Player:BuffP(S.IncarnationBuff)) then
    if HR.CastSuggested(I.ProlongedPower) then return ""; end
  end
  -- blood_fury,if=buff.celestial_alignment.up|buff.incarnation.up
  if S.BloodFury:IsCastableP() and HR.CDsON() and (Player:BuffP(S.CelestialAlignmentBuff) or Player:BuffP(S.IncarnationBuff)) then
    if HR.Cast(S.BloodFury, Settings.Balance.OffGCDasOffGCD.BloodFury) then return ""; end
  end
  -- berserking,if=buff.celestial_alignment.up|buff.incarnation.up
  if S.Berserking:IsCastableP() and HR.CDsON() and (Player:BuffP(S.CelestialAlignmentBuff) or Player:BuffP(S.IncarnationBuff)) then
    if HR.Cast(S.Berserking, Settings.Balance.OffGCDasOffGCD.Berserking) then return ""; end
  end
  -- arcane_torrent,if=buff.celestial_alignment.up|buff.incarnation.up
  if S.ArcaneTorrent:IsCastableP() and HR.CDsON() and (Player:BuffP(S.CelestialAlignmentBuff) or Player:BuffP(S.IncarnationBuff)) then
    if HR.Cast(S.ArcaneTorrent, Settings.Balance.OffGCDasOffGCD.ArcaneTorrent) then return ""; end
  end
  -- lights_judgment,if=buff.celestial_alignment.up|buff.incarnation.up
  if S.LightsJudgment:IsCastableP() and (Player:BuffP(S.CelestialAlignmentBuff) or Player:BuffP(S.IncarnationBuff)) then
    if HR.Cast(S.LightsJudgment) then return ""; end
  end
  -- use_items
  if S.UseItems:IsCastableP() and (true) then
    if HR.Cast(S.UseItems) then return ""; end
  end
  -- warrior_of_elune
  if S.WarriorofElune:IsCastableP() and (true) then
    if HR.Cast(S.WarriorofElune) then return ""; end
  end
  -- incarnation,if=astral_power>=40
  if S.Incarnation:IsCastableP() and (FutureAstralPower() >= 40) then
    if HR.Cast(S.Incarnation) then return ""; end
  end
  -- celestial_alignment,if=astral_power>=40
  if S.CelestialAlignment:IsCastableP() and (FutureAstralPower() >= 40) then
    if HR.Cast(S.CelestialAlignment) then return ""; end
  end
  -- call_action_list,name=aoe,if=spell_targets.starfall>=3
  if (Cache.EnemiesCount[40] >= 3) then
    local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
  end
  -- call_action_list,name=st
  if (true) then
    local ShouldReturn = St(); if ShouldReturn then return ShouldReturn; end
  end
end

HR.SetAPL(102, APL)
