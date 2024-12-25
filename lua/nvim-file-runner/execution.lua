local Path = require("pathlib")

local utils = require("nvim-file-runner.utils")
local Strategy = require("nvim-file-runner.strategy")

local M = {saved = {}}

M.__index = M

function M.from_pipe(pipe)
  if not pipe.cmd_template then
    utils.complain("no file command could be determined")
    return
  end

  local self = setmetatable({}, M)

  self.save_file = pipe.save_file or false
  self.strategy_spec = pipe.strategy_spec

  if pipe.path_root then
    self.path_root = utils.lib_real_abs_path(pipe.path_root)
  end

  self.cmd_template = pipe.cmd_template
  self.cmd_template_modifier = pipe.cmd_template_modifier or utils.id
  self.file_path = utils.lib_real_abs_path(pipe.file_path)
  self.file_path_modifier = pipe.file_path_modifier
  self.cmd_wd = pipe.cmd_wd
  self.file_path_root = pipe.file_path_root

  self.cmd_line_number = pipe.cmd_line_number

  return self
end

function M:compute_cmd(cwd, strategy)
  cwd = Path(cwd)

  local cmd_wd =
    utils.lib_real_abs_path(
      utils.path_with_root(self.cmd_wd or cwd, self.path_root)
    )

  local file_path_root =
    utils.lib_real_abs_path(
      utils.path_with_root(self.file_path_root or cmd_wd, self.path_root)
    )

  local file_path = self.file_path

  if utils.path_is_below(file_path, file_path_root) then
    file_path = Path(utils.path_relative_to(file_path, file_path_root))
  end

  if self.file_path_modifier then
    file_path = self.file_path_modifier(file_path)
  end

  local result = self.cmd_template

  result = self.cmd_template_modifier(result)
  result = utils.substitute_path(result, file_path:tostring(), strategy)

  if self.cmd_line_number then
    result = utils.substitute_line(result, self.cmd_line_number)
  end

  local cd_path

  if utils.path_is_below(cmd_wd, cwd) then
    cd_path = utils.path_relative_to(cmd_wd, cwd)
  else
    cd_path = cmd_wd
  end

  if cd_path == "." then
    cd_path = nil
  end

  if cd_path then
    cd_path = utils.escape_path(cd_path, strategy)

    result = "cd " .. cd_path .. " && " .. result
  end

  return result
end

function M:perform()
  if self.save_file then
    vim.cmd("silent update")
  end

  local strategy = Strategy.from_desc(self.strategy_spec)
  local cmd = self:compute_cmd(Path.cwd(), strategy)

  return strategy:execute(cmd)
end

M.requirements = {
  "strategy_spec",
  "path_root",
  "file_path",
  "file_path_root",
  "file_path_modifier",
  "cmd_template",
  "cmd_template_modifier",
  "cmd_line_number",
  "cmd_wd",
  "save_file"
}

return M
