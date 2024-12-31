local utils = require("nvim-file-runner.utils")
local ValueProvider = require("nvim-file-runner.engine.value_provider")
local Inventory = require("nvim-file-runner.inventory")

local M = { inventory = Inventory.new("Effect") }

M.__index = M

local apply_providing = function(pipe, providing)
  for k, v in pairs(providing) do
    pipe[k] = ValueProvider.wrap(v):apply(pipe)
  end

  return pipe
end

function M.is_effect(arg)
  return getmetatable(arg) == M
end

function M.from_providing(providing)
  local inner = function(pipe)
    return apply_providing(pipe, providing)
  end

  local provides = {}
  for k, _ in pairs(providing) do
    table.insert(provides, k)
  end

  return M.new(inner, provides)
end

function M.to_effect(data)
  if getmetatable(data) == M then
    return data
  else
    return M.from_providing(data)
  end
end

function M.new(inner, provided)
  local self = setmetatable({}, M)

  self.inner = inner
  self.provides = {}
  for _, p in ipairs(provided) do

    self.provides[p] = true
  end

  return self
end

function M:provides_any_of(requirements)
  for _, req in ipairs(requirements) do
    if self.provides[req] then
      return true
    end
  end

  return false
end

function M:apply(pipe)
  return self.inner(pipe)
end

M.inventory.restart = function(new_mode, payload)
  local inner =
    function(pipe)
      local result = utils.merge(pipe.initial_pipe, payload)

      result.restart = true
      result.mode = new_mode

      return result
    end

  return M.new(inner, { "restart" })
end

return M
