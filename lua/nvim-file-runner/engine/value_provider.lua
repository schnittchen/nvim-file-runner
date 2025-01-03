local utils = require("nvim-file-runner.utils")
local Inventory = require("nvim-file-runner.inventory")

local M = {}

M.__index = M

M.inventory = Inventory.new("Value provider")

M.inventory.constant = function(_pipe, constant)
  return constant
end

M.inventory.get = function(pipe, key)
  return pipe[key]
end

M.inventory.current_line_indented = function(_pipe)
  return utils.current_indent() ~= 0
end

M.inventory.current_line_number = function(_pipe)
  return utils.current_line()
end

M.inventory.matches = function(pipe, key, pattern)
  return not not string.match(pipe[key], pattern)
end

M.inventory.strategy = function(_pipe, name, options)
  if options then
    return { name, options }
  else
    return name
  end
end

function M.new(key, ...)
  local self = setmetatable({}, M)
  self.key = key
  self.varargs = utils.sane_pack(...)

  return self
end

function M.wrap(value)
  if getmetatable(value) == M then
    return value
  else
    return M.new("constant", value)
  end
end

function M:apply(pipe)
  return M.inventory[self.key](pipe, table.unpack(self.varargs))
end

return M
