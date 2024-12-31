local utils = require("nvim-file-runner.utils")
local Inventory = require("nvim-file-runner.inventory")

local M = { inventory = Inventory.new("Predicate") }

M.__index = M

function M.new(fun)
  local self = setmetatable({}, M)
  self.fun = fun
  return self
end

function M.is_predicate(arg)
  return getmetatable(arg) == M
end

function M:apply(value)
  return self.fun(value)
end

function M.inventory.path_below(path)
  path = utils.lib_real_abs_path(path)

  local fun = function(p)
    p = utils.lib_real_abs_path(p)

    return utils.path_is_below(p, path)
  end

  return M.new(fun)
end

return M
