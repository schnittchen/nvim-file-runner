local Path = require("pathlib")

local M = {}

-- TODO there's also Path:shell_string...
local path_escape_modes = {
  [false] = function(string)
    return string
  end,
  path_cmd_string = function(string)
    return Path(string):cmd_string()
  end
}

-- `pattern` can be any lua pattern.
local replace_pattern = function(string, pattern, replacement)
  local rep = function()
    return replacement
  end

  local result = string:gsub(pattern, rep)
  return result
end

function M.escape_path(path, strategy)
  return path_escape_modes[strategy.path_escape_mode](path)
end

function M.merge(t1, t2)
  local result = {}
  for k, v in pairs(t1) do
    result[k] = v
  end
  for k, v in pairs(t2) do
    result[k] = v
  end
  return result
end

function M.is_empty(t)
  for _,_ in pairs(t) do
    return false
  end
  return true
end

function M.current_file()
  local result = vim.fn.expand('%')

  if Path(result):exists() then
    return result
  else
    return nil
  end
end

function M.current_line()
  return vim.api.nvim_win_get_cursor(0)[1]
end

function M.current_indent()
  return vim.fn.indent(".")
end

function M.substitute_path(template, path, strategy)
  path = M.escape_path(path, strategy)

  return replace_pattern(template, "{}", path)
end

function M.substitute_line(template, line)
  return replace_pattern(template, "{#}", line)
end

function M.id(arg)
  return arg
end

function M.sane_pack(...)
  local result = table.pack(...)
  result["n"] = nil

  return result
end

function M.lib_real_abs_path(path)
  return Path(path):realpath():to_absolute()
end

-- Is `path` below `other_path`? Both arguments
-- must be result of `lib_real_abs_path`
function M.path_is_below(path, other_path)
  return not not path:relative_to(other_path)
end

function M.path_relative_to(path, other_path)
  path = M.lib_real_abs_path(path)
  other_path = M.lib_real_abs_path(other_path)

  return path:relative_to(other_path):tostring()
end

function M.path_with_root(path, root)
  local path = Path(path)

  if path:is_absolute() then
    return path:tostring()
  elseif not root then
    return path:tostring()
  else
    return (Path(root) / path):tostring()
  end
end

-- message must be one line and not contain anything fancy:
function M.complain(message)
  vim.cmd.echohl("WarningMsg")
  vim.cmd.echo("'" .. message .. "'")
  vim.cmd.echohl("None")
end

return M
