local M = {}

function M:new(tbl)
  tbl = tbl or {}
  setmetatable(tbl, self)
  self.__index = self
  return tbl
end

function M:handle()
  error("abstract")
end

local with_user_message = M:new()

function with_user_message:handle()
  vim.cmd.echohl("WarningMsg")
  vim.cmd.echo("'" .. self.message .. "'")
  vim.cmd.echohl("None")
end

function M.with_user_message(msg)
  error(with_user_message:new({message = "nvim-file-runner: " .. msg}))
end

return M

