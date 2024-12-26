local Helpers = require("test_helpers")
Helpers.clear_requires()

local Path = require("pathlib")

local utils = require("nvim-file-runner.utils")
local RuleSet = require("nvim-file-runner.engine.rule_set")
local Condition = require("nvim-file-runner.engine.condition")
local Effect = require("nvim-file-runner.engine.effect")
local Execution = require("nvim-file-runner.execution")
local Engine = require("nvim-file-runner.engine")

local cond = Condition.new

local function effect(provides, inner)
  result = Effect.new(inner, provides)
  return Effect.new(inner, provides)
end

local function failing_effect(provides)
  return Effect.new(
    function()
      error("failing effect")
    end,
    provides
  )
end

T = MiniTest.new_set()

T['start_pipe'] = function()
  local start_pipe = Engine.start_pipe("./file", "mode", "lua")

  MiniTest.expect.equality(
    start_pipe,
    {
      file_path = "./file",
      filetype = "lua",
      mode = "mode",
      initial_pipe = {
        file_path = "./file",
        filetype = "lua",
      }
    }
  )
end

T['_apply_rules_for_requirements'] = MiniTest.new_set()

T['_apply_rules_for_requirements']['skips rules not required, applies in order required'] = function()
  local set = RuleSet.new()

  set:declare_set("name", {
    [cond({})] = failing_effect({"not_a_requirement"}),

    [cond({})] = effect({"inner_cond"}, function(pipe)
      table.insert(pipe.applied, 2)
      pipe.inner_cond = true

      return pipe
    end),

    [cond({inner_cond = true})] = effect({"requirement"}, function(pipe)
      table.insert(pipe.applied, 3)

      return pipe
    end),
  })

  local initial_pipe = { applied = {} }

  MiniTest.expect.equality(
    Engine._apply_rules_for_requirements(initial_pipe, {"requirement"}, set),
    {applied = { 2, 3 }, inner_cond = true}
  )
end

T['_apply_rules_for_requirements']['skips rules already applied'] = function()
  local set = RuleSet.new()

  set:declare_set("name", {
    [cond({})] = effect({"requirement"}, function(pipe)
      pipe.applied = true

      return pipe
    end),
  })

  MiniTest.expect.equality(
    Engine._apply_rules_for_requirements({}, {"requirement"}, set),
    {applied = true}
  )

  MiniTest.expect.equality(
    Engine._apply_rules_for_requirements({}, {"requirement"}, set),
    {}
  )

  set:reset_applied()

  MiniTest.expect.equality(
    Engine._apply_rules_for_requirements({}, {"requirement"}, set),
    {applied = true}
  )
end

T['_apply_rules_for_requirements']['aborts on restart'] = function()
  local set = RuleSet.new()
  local restarting = false

  set:declare_set("name", {
    [cond({})] = effect({"inner_cond"}, function(pipe)
      pipe.inner_cond = true
      if restarting then
        pipe.restart = true
      end

      return pipe
    end),

    [cond({inner_cond = true})] = effect({"requirement"}, function(pipe)
      pipe.applied_last = true

      return pipe
    end),
  })

  -- without restarting:
  MiniTest.expect.equality(
    Engine._apply_rules_for_requirements({}, {"requirement"}, set),
    {applied_last = true, inner_cond = true}
  )

  set:reset_applied()

  -- without restarting (again):
  MiniTest.expect.equality(
    Engine._apply_rules_for_requirements({}, {"requirement"}, set),
    {applied_last = true, inner_cond = true}
  )

  set:reset_applied()

  -- with restarting:
  restarting = true
  MiniTest.expect.equality(
    Engine._apply_rules_for_requirements({}, {"requirement"}, set),
    {inner_cond = true, restart = true}
  )
end

T['_apply_rules_with_restart with "restart" effect'] = function()
  local set = RuleSet.new()

  set:declare_set("name", {
    [cond({mode = "initial"})] = Effect.inventory.restart("final", {from_restart = 1}),
    [cond({mode = "final"})] = effect({"requirement"}, function(pipe)
      pipe.requirement = true

      return pipe
    end)
  })

  local initial_pipe = Engine.start_pipe("./file", "initial", "lua")

  MiniTest.expect.equality(
    Engine._apply_rules_with_restart(initial_pipe, {"requirement", "restart"}, set),
    {
      mode = "final",
      requirement = true,
      from_restart = 1,
      file_path = "./file",
      filetype = "lua"
    }
  )
end

T['get_execution'] = MiniTest.new_set()

T['get_execution']['returns nil if not sufficient data for execution'] = function()
  local set = RuleSet.new()
  set:declare_set("name", {})

  local initial_pipe = Engine.start_pipe("./file", "initial", "lua")

  MiniTest.expect.equality(
    Engine.get_execution("./file", "text", "mode", {}, set),
    nil
  )
end

T['get_execution']['returns execution based on piped data; saves on demand'] = function()
  local set = RuleSet.new()

  set:declare_set("name", {
    [cond({})] = { cmd_template = "echo" }
  })

  local requirements = { "cmd_template" }

  MiniTest.expect.equality(
    Engine.get_execution("/etc/passwd", "text", "mode", requirements, set),
    {
      cmd_template = "echo",
      cmd_template_modifier = utils.id,
      file_path = Path("/etc/passwd"),
      save_file = false
    }
  )

  MiniTest.expect.equality(Execution.saved, {})

  -- repeat, but with save_last_execution:
  set:declare_set("name", {
    [cond({})] = { cmd_template = "echo", save_last_execution = "key" }
  })

  local execution = Engine.get_execution("/etc/passwd", "text", "mode", requirements, set)

  MiniTest.expect.equality(Execution.saved.key, execution)
end

T['get_execution']['retrieves execution on demand'] = function()
  local set = RuleSet.new()

  set:declare_set("name", {
    [cond({})] = { mode = "run_saved_execution", saved_execution = "key" }
  })

  local requirements = Engine.requirements

  Execution.saved.key = nil -- reset state

  local execution = Engine.get_execution("/etc/passwd", "text", "mode", requirements, set)
  MiniTest.expect.equality(execution, nil)

  local saved = {}
  Execution.saved.key = saved
  local execution = Engine.get_execution("/etc/passwd", "text", "mode", requirements, set)
  MiniTest.expect.equality(execution, saved)
end

return T
