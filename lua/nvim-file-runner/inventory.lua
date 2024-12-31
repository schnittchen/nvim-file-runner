local Error = require("nvim-file-runner.error")

local M = {}

function M.new(category)
  if not category then
    error("category argument missing")
  end

  local result = {}
  setmetatable(result, {
    __index = M._get
  })

  result._category = category
  return result
end

function M._get(inventory, key)
  Error.with_user_message(inventory._category .. " not found by key " .. vim.inspect(key))
end

return M
