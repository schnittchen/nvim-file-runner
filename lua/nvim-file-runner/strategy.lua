local Inventory = require("nvim-file-runner.inventory")

local M = {inventory = Inventory.new("Strategy")}
M.__index = M

function M:new(tbl)
  tbl = tbl or {}
  setmetatable(tbl, self)
  tbl.options = vim.tbl_deep_extend("force", self.options or {}, tbl.options or {})
  self.__index = self
  return tbl
end

function M:execute(_cmd)
  error("abstract")
end

M.inventory.bang = M:new({path_escape_mode = "path_cmd_string"})

function M.inventory.bang:execute(cmd)
  vim.cmd("! " .. cmd)
end

M.inventory.basic = M:new({
  path_escape_mode = false,
  options = {height = false, restore_on_success = false}
})

function M.inventory.basic:execute(cmd)
  -- close buffer (terminating process):
  local restore = function()
    vim.cmd("bd!")
    vim.cmd.execute("'wincmd p'")
  end

  local on_exit = function(_, code)
    if code == 0 and self.options.restore_on_success then
      restore()
    end
  end

  if self.options.height then
    vim.cmd("botright new +resize" .. options.height)
  else
    vim.cmd("botright new")
  end
  vim.fn.termopen(cmd, { on_exit = on_exit })

  vim.keymap.set("n", "<enter>", restore, { buffer = true })
end

function M.from_desc(desc)
  local cmd_strategy, cmd_strategy_options
  desc = desc or "basic"

  if type(desc) == "table" then
    cmd_strategy, cmd_strategy_options = unpack(desc)
    return M.inventory[cmd_strategy]:new({ options = cmd_strategy_options })
  else
    return M.inventory[desc]:new()
  end
end

return M
