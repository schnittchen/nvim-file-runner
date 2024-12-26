local DeclaredRules = require("nvim-file-runner.engine.declared_rules")

local M = {}
M.__index = M

function M.new()
  local self = setmetatable({}, M)
  self.rules = {}
  self.applied = {}

  return self
end

function M:declare_set(set_name, declared)
  local rules = {}

  -- replace rules of `set_name` with rules from `declared`

  for _, rule in ipairs(self.rules) do
    if rule.set_name ~= set_name then
      table.insert(rules, rule)
    end
  end

  for _, rule in ipairs(DeclaredRules.to_rules(declared, set_name)) do
    table.insert(rules, rule)
  end

  self.rules = rules

  return self
end

function M:was_applied(rule)
  return not not self.applied[rule]
end

function M:mark_applied(rule)
  self.applied[rule] = true

  return self
end

function M:reset_applied()
  self.applied = {}

  return self
end

function M:unapplied_ordered_rules_providing(requirements)
  local result = {}

  for _, rule in ipairs(self.rules) do
    if not self.applied[rule] and rule:provides_any_of(requirements) then
      table.insert(result, rule)
    end
  end

  table.sort(result, function(r1, r2)
    return r1:comes_before(r2)
  end)

  return result
end

return M
