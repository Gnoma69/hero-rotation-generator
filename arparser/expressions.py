# -*- coding: utf-8 -*-
"""
Define the objects representing simc expressions.

@author: skasch
"""

from .lua import LuaNamed, LuaExpression, Method, Literal
from .executions import Spell, Item
from .druid import balance_astral_power_value
from .units import Pet
from .constants import SPELL, BUFF, DEBUFF, BOOL, PET, BLOODLUST


class Expression:
    """
    Represent a singleton condition (i.e. without any operator).
    """

    def __init__(self, condition_expression, simc):
        self.condition_expression = condition_expression
        self.parent_action = condition_expression.action
        self.simc = simc
        self.pet_caster = None
        self.condition_list = self.build_condition_list()
        self.player_unit = condition_expression.action.player
        self.target_unit = condition_expression.action.target

    def build_condition_list(self):
        """
        Return the splitted structure of the condition.
        """
        return self.simc.split('.')

    def expression(self):
        """
        Return the expression of the condition.
        """
        if (self.condition_list[0] in self.actions_to_self()
                and len(self.condition_list) == 1):
            return self.action(to_self=True)
        try:
            return getattr(self, self.condition_list[0])()
        except AttributeError:
            return Literal(self.simc)

    def caster(self, spell=None):
        """
        The caster of the spell; default is player, is pet if the spell is cast
        by a pet.
        """
        if self.player_unit.spell_property(spell, PET):
            return Pet(self.player_unit)
        if self.pet_caster:
            return self.pet_caster
        return self.player_unit

    def pet(self):
        """
        Return the condition for a pet.{name}.{condition} expression.
        """
        pet_name = self.condition_list[1]
        self.pet_caster = Pet(self.player_unit, pet_name)
        self.condition_list = self.condition_list[2:]
        return self.expression()

    def actions_to_self(self):
        """
        The list of actions that can be applied to self (i.e. the execution of
        the action) for shortcut.
        """
        return [method for method in dir(ActionExpression)
                if callable(getattr(ActionExpression, method))
                and not method.startswith('__') and not method == 'print_lua']

    def action(self, to_self=False):
        """
        Return the condition when the prefix is action.
        """
        return ActionExpression(self, to_self)

    def spell_haste(self):
        """
        Return the condition when the prefix is spell_haste.
        """
        return LuaExpression(self.player_unit, Method('SpellHaste'), [])

    def set_bonus(self):
        """
        Return the condition when the prefix is set_bonus.
        """
        return SetBonus(self)

    def equipped(self):
        """
        Return the condition when the prefix is equipped.
        """
        return Equipped(self)

    def cooldown(self):
        """
        Return the condition when the prefix is cooldown.
        """
        return Cooldown(self)

    def buff(self):
        """
        Return the condition when the prefix is buff.
        """
        return Buff(self)

    def debuff(self):
        """
        Return the condition when the prefix is debuff.
        """
        return Debuff(self)

    def dot(self):
        """
        Return the condition when the prefix is dot.
        """
        return Dot(self)

    def prev_gcd(self):
        """
        Return the condition when the prefix is prev_gcd.
        """
        return PrevGCD(self)

    def gcd(self):
        """
        Return the condition when the prefix is gcd.
        """
        return GCD(self)

    def time(self):
        """
        Return the condition when the prefix is time.
        """
        return Time(self)

    def astral_power(self):
        """
        Return the condition when the prefix is astral_power.
        """
        return AstralPower(self)

    def runic_power(self):
        """
        Return the condition when the prefix is runic_power.
        """
        return RunicPower(self)

    def fury(self):
        """
        Return the condition when the prefix is fury.
        """
        return Fury(self)

    def mana(self):
        """
        Return the condition when the prefix is mana.
        """
        return Mana(self)

    def talent(self):
        """
        Return the condition when the prefix is talent.
        """
        return Talent(self)

    def charges_fractional(self):
        """
        Return the condition when the prefix is charges_fractional.
        """
        return LuaExpression(Spell(self.parent_action, 'blood_boil'),
                             Method('ChargesFractional'), [])

    def rune(self):
        """
        Return the condition when the prefix is rune.
        """
        return Rune(self)

    def target(self):
        """
        Return the condition when the prefix is target.
        """
        return TargetExpression(self)

    def variable(self):
        """
        Return the condition when the prefix is variable.
        """
        lua_varname = LuaNamed(self.condition_list[1]).lua_name()
        return Literal(lua_varname)


class BuildExpression(LuaExpression):
    """
    Build an expression from a call.
    """

    def __init__(self, call):
        call = 'ready' if call == 'up' else call
        getattr(self, call)()
        super().__init__(self.object_, self.method, self.args)


class Expires:
    """
    Available expressions for conditions with expiration times.
    """

    def __init__(self, condition, simc, ready_simc, spell_type=SPELL,
                 spell=None):
        self.condition = condition
        self.simc = LuaNamed(simc)
        self.ready_simc = LuaNamed(ready_simc)
        if not spell:
            spell_simc = condition.condition_list[1]
            if spell_simc == BLOODLUST:
                self.spell = Literal(BLOODLUST)
            else:
                self.spell = Spell(condition.parent_action, spell_simc,
                                   spell_type)
        else:
            self.spell = spell
        self.object_ = self.spell
        self.method = None
        self.args = []

    def ready(self):
        """
        Return the arguments for the expression {expires}.spell.up.
        """
        if self.spell.simc == BLOODLUST:
            self.method = Method('HasHeroism', type_=BOOL)
            # Required when called from Aura
            self.args = []
        else:
            self.method = Method(f'{self.ready_simc.lua_name()}P', type_=BOOL)

    def remains(self):
        """
        Return the arguments for the expression {expires}.spell.remains.
        """
        if self.spell.simc == BLOODLUST:
            self.method = Method('HasHeroism', type_=BOOL)
            # Required when called from Aura
            self.args = []
        else:
            self.method = Method(f'{self.simc.lua_name()}RemainsP')

    def duration(self):
        """
        Return the arguments for the expression {aura}.spell.duration.
        """
        self.method = Method('BaseDuration')


class Aura(Expires):
    """
    Available expressions for auras (buffs and debuffs).
    """

    def __init__(self, condition, simc, object_, spell_type=SPELL, spell=None):
        super().__init__(condition, simc, simc, spell_type=spell_type,
                         spell=spell)
        # Overrides values from Expires
        self.object_ = object_
        self.method = None
        self.args = [self.spell]

    def down(self):
        """
        Return the arguments for the expression {aura}.spell.down.
        """
        if self.spell.simc == BLOODLUST:
            self.method = Method('HasNotHeroism', type_=BOOL)
            self.args = []
        else:
            self.method = Method(f'{self.simc.lua_name()}DownP', type_=BOOL)

    def stack(self):
        """
        Return the arguments for the expression {aura}.spell.stack.
        """
        if self.spell.simc == BLOODLUST:
            self.method = Method('HasHeroism', type_=BOOL)
            self.args = []
        else:
            self.method = Method(f'{self.simc.lua_name()}StackP')

    def react(self):
        """
        Return the arguments for the expression {aura}.spell.stack.
        """
        self.stack()

    def duration(self):
        """
        Return the arguments for the expression {aura}.spell.duration.
        """
        # Override as buff.spell.duration refers to the Expires form.
        self.object_ = self.spell
        self.method = Method('BaseDuration')
        self.args = []


class ActionExpression(BuildExpression):
    """
    Represent the expression for a action. condition. Also works for expressions
    implicitly referring to the execution of the condition.
    """

    def __init__(self, condition, to_self=False):
        self.condition = condition
        self.to_self = to_self
        if to_self:
            call = condition.condition_list[0]
        else:
            call = condition.condition_list[2]
        self.object_ = self.action_object()
        self.args = []
        self.aura_model = self.build_aura()
        super().__init__(call)

    def action_object(self):
        """
        The object of the action expression, depending on whether the action is
        applied to self (i.e. the execution) or not.
        """
        if self.to_self:
            return self.condition.parent_action.execution().object_()
        else:
            return Spell(self.condition.parent_action,
                         self.condition.condition_list[1])

    def build_aura(self):
        """
        The action aura when referring to the action as a buff or debuff.
        """
        if self.condition.player_unit.spell_property(
                self.action_object(), DEBUFF):
            aura_type = DEBUFF
            aura_object = self.condition.target_unit
        else:
            aura_type = BUFF
            aura_object = self.condition.player_unit
        return Aura(self.condition, aura_type, aura_object,
                    spell=self.action_object())

    def from_aura(self):
        """
        Get attributes from the aura corresponding to the action object.
        """
        self.object_ = self.aura_model.object_
        self.method = self.aura_model.method
        self.args = self.aura_model.args

    def execute_time(self):
        """
        Return the arguments for the expression action.spell.execute_time.
        """
        self.method = Method('ExecuteTime')

    def recharge_time(self):
        """
        Return the arguments for the expression action.spell.recharge_time.
        """
        self.method = Method('RechargeP')

    def full_recharge_time(self):
        """
        Return the arguments for the expression action.spell.full_recharge_time.
        """
        self.method = Method('FullRechargeTimeP')

    def cast_time(self):
        """
        Return the arguments for the expression action.spell.cast_time.
        """
        self.method = Method('CastTime')

    def charges(self):
        """
        Return the arguments for the expression action.spell.charges.
        """
        self.method = Method('ChargesP')

    def cooldown(self):
        """
        Return the arguments for the expression action.spell.charges.
        """
        self.method = Method('Cooldown')

    def usable_in(self):
        """
        Return the arguments for the expression action.spell.usable_in.
        """
        self.method = Method('UsableInP')

    def ready(self):
        """
        Return the arguments for the expression action.spell.ready.
        """
        self.aura_model.ready()
        self.from_aura()

    def remains(self):
        """
        Return the arguments for the expression action.spell.remains.
        """
        self.aura_model.remains()
        self.from_aura()

    def down(self):
        """
        Return the arguments for the expression action.spell.down.
        """
        self.aura_model.down()
        self.from_aura()

    def stack(self):
        """
        Return the arguments for the expression action.spell.stack.
        """
        self.aura_model.stack()
        self.from_aura()

    def react(self):
        """
        Return the arguments for the expression action.spell.react.
        """
        self.aura_model.react()
        self.from_aura()

    def duration(self):
        """
        Return the arguments for the expression action.spell.duration.
        """
        self.aura_model.duration()
        self.from_aura()


class SetBonus(Literal):
    """
    Represent the expression for a set_bonus. condition.
    """

    def __init__(self, condition):
        lua_tier = f'AC.{self.lua_tier_name(condition)}'
        super().__init__(lua_tier, type_=BOOL)

    def lua_tier_name(self, condition):
        """
        Parse the lua name for the tier variable name holding whether a tier set
        is equipped or not.
        """
        simc = condition.condition_list[1]
        return '_'.join(word.title() for word in simc.split('_'))


class Equipped(BuildExpression):
    """
    Represent the expression for a equipped. condition.
    """

    def __init__(self, condition):
        self.condition = condition
        call = 'value'
        self.object_ = Item(condition.parent_action,
                            condition.condition_list[1])
        self.args = []
        super().__init__(call)

    def  value(self):
        """
        Return the arguments for the expression equipped.
        """
        self.method = Method('IsEquipped', type_=BOOL)


class PrevGCD(BuildExpression):
    """
    Represent the expression for a prev_gcd. condition.
    """

    def __init__(self, condition):
        self.condition = condition
        call = 'value'
        self.object_ = condition.caster(condition.condition_list[2])
        self.args = [Literal(condition.condition_list[1]),
                     Spell(condition.parent_action,
                           condition.condition_list[2])]
        super().__init__(call)

    def value(self):
        """
        Return the arguments for the expression prev_gcd.
        """
        self.method = Method('PrevGCDP', type_=BOOL)


class GCD(BuildExpression):
    """
    Represent the expression for a gcd. condition.
    """
    # TODO update GCD to take into account current execution.

    def __init__(self, condition):
        self.condition = condition
        if len(condition.condition_list) > 1:
            call = condition.condition_list[1]
        else:
            call = 'value'
        self.object_ = condition.player_unit
        self.args = []
        super().__init__(call)

    def remains(self):
        """
        Return the arguments for the expression gcd.remains.
        """
        self.method = Method('GCDRemains')

    def max(self):
        """
        Return the arguments for the expression gcd.max.
        """
        return self.value()

    def value(self):
        """
        Return the arguments for the expression gcd.
        """
        self.method = Method('GCD')


class Time(BuildExpression):
    """
    Represent the expression for a time. condition.
    """

    def __init__(self, condition):
        self.condition = condition
        if len(condition.condition_list) > 1:
            call = condition.condition_list[1]
        else:
            call = 'value'
        self.object_ = None
        self.args = []
        super().__init__(call)

    def value(self):
        """
        Return the arguments for the expression time.
        """
        self.method = Method('AC.CombatTime')


class Rune(BuildExpression):
    """
    Represent the expression for a rune. condition.
    """

    def __init__(self, condition):
        self.condition = condition
        call = condition.condition_list[1]
        self.object_ = condition.player_unit
        super().__init__(call)

    def time_to_3(self):
        """
        Return the arguments for the expression rune.time_to_3.
        """
        self.method = Method('RuneTimeToX')
        self.args = [Literal('3')]


class Talent(BuildExpression):
    """
    Represent the expression for a talent. condition.
    """

    def __init__(self, condition):
        self.condition = condition
        call = condition.condition_list[2]
        self.object_ = Spell(condition.parent_action,
                             condition.condition_list[1])
        self.args = []
        super().__init__(call)

    def enabled(self):
        """
        Return the arguments for the expression talent.spell.enabled.
        """
        self.method = Method('IsAvailable', type_=BOOL)


class Resource(BuildExpression):
    """
    Represent the expression for resource (mana, runic_power, etc) condition.
    """

    def __init__(self, condition, simc):
        self.condition = condition
        self.simc = LuaNamed(simc)
        if len(condition.condition_list) > 1:
            call = condition.condition_list[1]
        else:
            call = 'value'
        self.object_ = condition.player_unit
        self.args = []
        super().__init__(call)

    def value(self):
        """
        Return the arguments for the expression {resource}.
        """
        self.method = Method(f'{self.simc.lua_name()}')

    def deficit(self):
        """
        Return the arguments for the expression {resource}.deficit.
        """
        self.method = Method(f'{self.simc.lua_name()}Deficit')

    def pct(self):
        """
        Return the arguments for the expression {resource}.pct.
        """
        self.method = Method(f'{self.simc.lua_name()}Percentage')


class AstralPower(Resource):
    """
    Represent the expression for a astral_power. condition.
    """

    def __init__(self, condition):
        super().__init__(condition, 'astral_power')

    @balance_astral_power_value
    def value(self):
        return super().value()


class RunicPower(Resource):
    """
    Represent the expression for a runic_power. condition.
    """

    def __init__(self, condition):
        super().__init__(condition, 'runic_power')


class Fury(Resource):
    """
    Represent the expression for a fury. condition.
    """

    def __init__(self, condition):
        super().__init__(condition, 'fury')


class Mana(Resource):
    """
    Represent the expression for a mana. condition.
    """

    def __init__(self, condition):
        super().__init__(condition, 'mana')


class Debuff(BuildExpression, Aura):
    """
    Represent the expression for a debuff. condition.
    """

    def __init__(self, condition):
        object_ = condition.target_unit
        Aura.__init__(self, condition, DEBUFF, object_, spell_type=DEBUFF)
        call = condition.condition_list[2]
        super().__init__(call)


class Dot(Debuff):
    """
    Represent the expression for a dot. condition.
    """


class Buff(BuildExpression, Aura):
    """
    Represent the expression for a buff. condition.
    """

    def __init__(self, condition):
        object_ = condition.caster()
        Aura.__init__(self, condition, BUFF, object_, spell_type=BUFF)
        call = condition.condition_list[2]
        super().__init__(call)


class Cooldown(BuildExpression, Expires):
    """
    Represent the expression for a cooldown. condition.
    """

    def __init__(self, condition):
        Expires.__init__(self, condition, 'cooldown', 'cooldown_up')
        call = condition.condition_list[2]
        super().__init__(call)

    def charges(self):
        """
        Return the arguments for the expression cooldown.spell.charges.
        """
        self.method = Method('ChargesP')

    def recharge_time(self):
        """
        Return the arguments for the expression cooldown.spell.recharge_time.
        """
        self.method = Method('RechargeP')



class TargetExpression(BuildExpression):
    """
    Represent the expression for a target. condition.
    """

    def __init__(self, condition):
        self.condition = condition
        call = condition.condition_list[1]
        self.object_ = self.condition.target_unit
        self.args = []
        super().__init__(call)

    def time_to_die(self):
        """
        Return the arguments for the expression cooldown.spell.ready.
        """
        self.method = Method('TimeToDie')
