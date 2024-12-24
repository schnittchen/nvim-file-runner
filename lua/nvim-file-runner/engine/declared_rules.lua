local M = {}

local Condition = require("nvim-file-runner.engine.condition")
local Effect = require("nvim-file-runner.engine.effect")
local Rule = require("nvim-file-runner.engine.rule")

local append_as_rules
append_as_rules = function(cond, data, set_name, result)
  if Effect.is_effect(data) then
    table.insert(result, Rule.new(cond, data, set_name))

    return
  end

  local has_rest = false
  local rest = {}

  for k, v in pairs(data) do
    if Condition.is_condition(k) then
      local cond = k:merge(cond)

      append_as_rules(cond, v, set_name, result)
    else
      has_rest = true
      rest[k] = v
    end
  end

  if has_rest then
    table.insert(result, Rule.new(cond, Effect.to_effect(rest), set_name))
  end

  return result
end

M.to_rules = function(declared, set_name)
  result = {}
  append_as_rules(Condition.new(), declared, set_name, result)

  return result
end

return M
