local utils = require("nvim-file-runner.utils")
local Predicate = require("nvim-file-runner.engine.predicate")

local M = {}

M.__index = M
M.last_id = 0

function M.new(arg)
  local self = setmetatable({}, M)
  self.value = arg or {}

  M.last_id = M.last_id + 1
  self.id = M.last_id

  self.requirements = {}
  self.weight = 0
  for k, _ in pairs(self.value) do
    table.insert(self.requirements, k)
    self.weight = self.weight + 1
  end

  return self
end

function M.is_condition(arg)
  return getmetatable(arg) == M
end

-- TODO too simple
-- (this should error if the merged rule could not apply at all)
function M:merge(cond)
  return M.new(utils.merge(self.value, cond.value))
end

function M:was_created_before(other)
  return self.id < other.id
end

function M:does_apply(table)
  for k, v in pairs(self.value) do
    if Predicate.is_predicate(v) then
      if not v:apply(table[k]) then
        return false
      end
    else
      if table[k] ~= v then
        return false
      end
    end
  end

  return true
end

return M
