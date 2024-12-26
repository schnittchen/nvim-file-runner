local utils = require("nvim-file-runner.utils")
local Execution = require("nvim-file-runner.execution")

local M = {}

function M.start_pipe(file_path, mode, filetype)
  local pipe = {
    filetype = filetype,
    file_path = file_path
  }

  return utils.merge(pipe, { initial_pipe = pipe, mode = mode })
end

function M._apply_rules_for_requirements(pipe, requirements, ruleset)
  -- gather all rules which satisfy at least one requirement, and have not been applied yet:
  local providing_rules = ruleset:unapplied_ordered_rules_providing(requirements)

  -- Q: collect all provider requirements first?
  for _, rule in ipairs(providing_rules) do
    if not ruleset:was_applied(rule) then
      pipe = M._apply_rules_for_requirements(pipe, rule:requirements(), ruleset)

      if pipe.restart then
        return pipe
      end

      if rule:does_apply(pipe) then
        pipe = rule:apply(pipe)
        ruleset:mark_applied(rule)

        if pipe.restart then
          return pipe
        end
      end
    end
  end

  return pipe
end

M.requirements = { "restart", "mode" }
for _, req in ipairs(Execution.requirements) do
  table.insert(M.requirements, req)
end

function M._apply_rules_with_restart(pipe, requirements, ruleset)
  local seen_modes = {}

  while true do
    seen_modes[pipe.mode] = true

    ruleset:reset_applied()
    pipe = M._apply_rules_for_requirements(pipe, requirements, ruleset)

    if pipe.restart then
      if seen_modes[pipe.mode] then
        error("mode circularity")
      end

      pipe.restart = nil
    else
      return pipe
    end
  end
end

M.get_execution = function(file_path, filetype, mode, requirements, ruleset)
  local pipe = M._apply_rules_with_restart(
    M.start_pipe(file_path, mode, filetype),
    requirements,
    ruleset
  )

  local execution

  if pipe.mode == "run_saved_execution" then
    execution = Execution.saved[pipe.saved_execution]

    if not execution then
      -- XXX not visible when any print is following!
      utils.complain("cannot retrieve execution: " .. vim.inspect(pipe.saved_execution))
      return
    end
  else
    execution = Execution.from_pipe(pipe)

    if pipe.save_last_execution then
      Execution.saved[pipe.save_last_execution] = execution
    end
  end

  return execution
end

return M
