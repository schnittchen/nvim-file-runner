local Helpers = require("test_helpers")
Helpers.clear_requires()

local utils = require("nvim-file-runner.utils")
local DeclaredRules = require("nvim-file-runner.engine.declared_rules")
local Condition = require("nvim-file-runner.engine.condition")
local Effect = require("nvim-file-runner.engine.effect")
local Predicate = require("nvim-file-runner.engine.predicate")

local cond = Condition.new

T = MiniTest.new_set()

T['empty'] = function()
  local set_name = "rule set name"

  local declared
  local rules

  declared = {}
  rules = DeclaredRules.to_rules(declared, set_name)
  MiniTest.expect.equality(rules, {})

  declared = {
    [cond({})] = {}
  }
  rules = DeclaredRules.to_rules(declared, set_name)
  MiniTest.expect.equality(rules, {})
end

T['simple'] = function()
  local set_name = "rule set name"
  local declared = {
    [cond({})] = {bogus = "bogus"}
  }

  local rules = DeclaredRules.to_rules(declared, set_name)

  MiniTest.expect.equality(#rules, 1)

  local rule = rules[1]

  MiniTest.expect.equality(rule.set_name, set_name)
  MiniTest.expect.equality(rule:does_apply({}), true)
  MiniTest.expect.equality(rule.effect.provides, { bogus = true })
  MiniTest.expect.equality(rule.cond.requirements, {})
  MiniTest.expect.equality(rule:apply({}), { bogus = "bogus" })
end

T['nested'] = function()
  local set_name = "rule set name"
  local declared = {
    [cond({key = "value"})] = {
      outer_hit = true,
      [cond({other_key = "other value"})] = {
        inner_hit = true,
      },
    },
  }

  local rules = DeclaredRules.to_rules(declared, set_name)

  MiniTest.expect.equality(#rules, 2)

  table.sort(rules, function(rule1, rule2)
    return #rule1.cond.requirements < #rule2.cond.requirements
  end)

  local outer_rule = rules[1]
  local inner_rule = rules[2]

  MiniTest.expect.equality(outer_rule.set_name, set_name)
  MiniTest.expect.equality(outer_rule:does_apply({}), false)
  MiniTest.expect.equality(outer_rule:does_apply({key = "value"}), true)
  MiniTest.expect.equality(outer_rule.cond.requirements, { "key" })
  MiniTest.expect.equality(outer_rule:apply({}), { outer_hit = true })

  MiniTest.expect.equality(inner_rule.set_name, set_name)
  MiniTest.expect.equality(inner_rule:does_apply({}), false)
  MiniTest.expect.equality(inner_rule:does_apply({key = "value"}), false)
  MiniTest.expect.equality(inner_rule:does_apply({key = "value", other_key = "other value"}), true)
  table.sort(inner_rule.cond.requirements)
  MiniTest.expect.equality(inner_rule.cond.requirements, { "key", "other_key" })
  MiniTest.expect.equality(inner_rule:apply({}), { inner_hit = true })
end

T['complex effect'] = function()
  local set_name = "rule set name"
  local declared = {
    [cond({})] = Effect.new(function(pipe)
      pipe["provided"] = "bogus"

      return pipe
    end, { "provided" })
  }

  local rules = DeclaredRules.to_rules(declared, set_name)

  MiniTest.expect.equality(#rules, 1)

  local rule = rules[1]

  MiniTest.expect.equality(rule.set_name, set_name)
  MiniTest.expect.equality(rule:does_apply({}), true)
  MiniTest.expect.equality(rule.effect.provides, { provided = true })
  MiniTest.expect.equality(rule.cond.requirements, {})
  MiniTest.expect.equality(rule:apply({}), { provided = "bogus" })
end

T['condition predicate'] = function()
  local set_name = "rule set name"
  local predicate = Predicate.new(function(value)
    return not not value
  end)
  local declared = {
    [cond({ required = predicate })] = { bogus = "bogus" }
  }

  local rules = DeclaredRules.to_rules(declared, set_name)

  MiniTest.expect.equality(#rules, 1)

  local rule = rules[1]

  MiniTest.expect.equality(rule.set_name, set_name)
  MiniTest.expect.equality(rule:does_apply({}), false)
  MiniTest.expect.equality(rule:does_apply({ required = false }), false)
  MiniTest.expect.equality(rule:does_apply({ required = true }), true)
end

return T
