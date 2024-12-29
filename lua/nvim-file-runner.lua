local M = {}

local utils = require("nvim-file-runner.utils")
local RuleSet = require("nvim-file-runner.engine.rule_set")
local Condition = require("nvim-file-runner.engine.condition")
local ValueProvider = require("nvim-file-runner.engine.value_provider")
local Engine = require("nvim-file-runner.engine")
local Predicate = require("nvim-file-runner.engine.predicate")
local Effect = require("nvim-file-runner.engine.effect")

M.value = ValueProvider.new

function M.pred(name, ...)
  return Predicate.inventory[name](...)
end

M.cond = Condition.new

function M.effect(name, ...)
  return Effect.inventory[name](...)
end

local ruleset = RuleSet.new()

function M.rules(set_name, spec)
  ruleset:declare_set(set_name, spec)
end

M.requirements = {}
for _, req in ipairs(Engine.requirements) do
  table.insert(M.requirements, req)
end

function M.run(mode)
  local file_path = utils.current_file()

  if not file_path then
    return
  end

  local filetype = vim.o.filetype

  local execution = Engine.get_execution(file_path, filetype, mode, M.requirements, ruleset)

  if execution then
    execution:perform()
  end
end

function M.setup()
end

return M
