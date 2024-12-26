local Helpers = require("test_helpers")
Helpers.clear_requires()

local RuleSet = require("nvim-file-runner.engine.rule_set")
local Condition = require("nvim-file-runner.engine.condition")

local cond = Condition.new

T = MiniTest.new_set()

T['unapplied_ordered_rules_providing with several sets'] = function()
  local set_name1 = "set 1"
  local set_name2 = "set 2"
  local set = RuleSet.new()

  set:declare_set(set_name1, {
    [cond({})] = {key = "initial"}
  })
  set:declare_set(set_name2, {
    [cond({key = "initial"})] = {key = "changed"}
  })

  local rules = set:unapplied_ordered_rules_providing({"key"})
  MiniTest.expect.equality(#rules, 2)

  set:mark_applied(rules[1])
  MiniTest.expect.equality(set:was_applied(rules[1]), true)
  MiniTest.expect.equality(set:was_applied(rules[2]), false)
  local rules = set:unapplied_ordered_rules_providing({"key"})
  MiniTest.expect.equality(#rules, 1)

  set:reset_applied()
  local rules = set:unapplied_ordered_rules_providing({"key"})
  MiniTest.expect.equality(#rules, 2)

  -- this overwrites rules for `set_name2`:
  set:declare_set(set_name2, {})

  local rules = set:unapplied_ordered_rules_providing({"key"})
  MiniTest.expect.equality(#rules, 1)
end

T['unapplied_ordered_rules_providing ordering'] = function()
  local set = RuleSet.new()
  local set_name = "set name"

  set:declare_set(set_name, {
    [cond({})] = {key = "initial"},
    [cond({key = "initial"})] = {key = "changed"}
  })

  local rules = set:unapplied_ordered_rules_providing({"key"})
  MiniTest.expect.equality(
    rules[1].effect:apply({}),
    {key = "initial"}
  )

  set:declare_set(set_name, {
    [cond({key = "initial"})] = {key = "changed"},
    [cond({})] = {key = "initial"}
  })

  local rules = set:unapplied_ordered_rules_providing({"key"})
  MiniTest.expect.equality(
    rules[1].effect:apply({}),
    {key = "initial"}
  )

  set:declare_set(set_name, {
    [cond({})] = {
      key = "initial",
      [cond({key = "initial"})] = {key = "changed"}
    }
  })

  local rules = set:unapplied_ordered_rules_providing({"key"})
  MiniTest.expect.equality(
    rules[1].effect:apply({}),
    {key = "initial"}
  )
end

return T
