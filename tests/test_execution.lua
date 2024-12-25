local Helpers = require("test_helpers")
Helpers.clear_requires()

local Path = require("pathlib")
local utils = require("nvim-file-runner.utils")
local Execution = require("nvim-file-runner.execution")
local Strategy = require("nvim-file-runner.strategy")

local minimal_strategy = {path_escape_mode = false}

local requirements = {}
for _, req in ipairs(Execution.requirements) do
  requirements[req] = true
end

local from_pipe_result = function(pipe)
  -- we only want to pass pipe with keys from `Execution.requirements`:
  local bad_keys = {}
  for k, _ in pairs(pipe) do
    if not requirements[k] then
      table.insert(bad_keys, k)
    end
  end

  for _, k in ipairs(bad_keys) do
    pipe[k] = nil
  end

  return Execution.from_pipe(pipe)
end

local compute_cmd_result = function(pipe, cwd, strategy)
  execution = from_pipe_result(pipe)

  return execution:compute_cmd(cwd, strategy)
end

describe('from_pipe', function()
  it('returns nil when cmd_template missing', function()
    local pipe = {}
    local result = from_pipe_result(pipe)

    MiniTest.expect.equality(result, nil)
  end)

  it('returns expected result in minimal setup example', function()
    local pipe = {
      file_path = ".",
      cmd_template = "cmd_template",
      strategy_spec = "strategy spec",
    }
    local result = from_pipe_result(pipe)

    MiniTest.expect.equality(result, {
      save_file = false,
      strategy_spec = "strategy spec",
      cmd_template = "cmd_template",
      cmd_template_modifier = utils.id,
      file_path = utils.lib_real_abs_path(".")
    })
  end)

  it('returns expected result in exhaustive setup example', function()
    local cmd_template_modifier = function(cmd_template)
      return cmd_template
    end
    local file_path_modifier = function(path)
      return path
    end

    local pipe = {
      save_file = true,
      file_path = ".",
      path_root = "..",
      cmd_wd = "../..",
      file_path_root = "../../..",
      cmd_template = "cmd_template",
      cmd_template_modifier = cmd_template_modifier,
      file_path_modifier = file_path_modifier,
      strategy_spec = "strategy spec",
      cmd_line_number = 2
    }
    local result = from_pipe_result(pipe)

    MiniTest.expect.equality(result, {
      save_file = true,
      strategy_spec = "strategy spec",
      path_root = utils.lib_real_abs_path(".."),
      cmd_template = "cmd_template",
      cmd_template_modifier = cmd_template_modifier,
      file_path = utils.lib_real_abs_path("."),
      file_path_modifier = file_path_modifier,
      cmd_wd = "../..",
      file_path_root = "../../..",
      cmd_line_number = 2
    })
  end)
end)

describe('compute_cmd', function()
  it('handles line number substitution', function()
    local pipe = {
      cmd_template = "{#}",
      cmd_line_number = 2
    }

    MiniTest.expect.equality(
      compute_cmd_result(pipe, "/proc", minimal_strategy),
      "2"
    )
  end)

  it('returns cmd_template (when that has no substitution patterns)', function()
    local pipe = {
      cmd_template = "cmd_template",
    }

    MiniTest.expect.equality(
      compute_cmd_result(pipe, "/proc", minimal_strategy),
      "cmd_template"
    )
  end)

  it('returns result of cmd_template_modifier', function()
    local pipe = {
      file_path = "/etc/passwd",
      cmd_template = "cmd_template",
      cmd_template_modifier = function()
        return "modified {}"
      end
    }

    MiniTest.expect.equality(
      compute_cmd_result(pipe, "/proc", minimal_strategy),
      "modified /etc/passwd"
    )
  end)

  describe('handling of cmd_wd and `cd` prepending', function()
    describe('without cmd_wd, but with path_root', function()
      it('does not prepend a `cd`, ignoring path_root', function()
        local pipe = {
          cmd_template = "cmd_template",
          path_root = "/dev"
        }

        MiniTest.expect.equality(
          compute_cmd_result(pipe, "/proc", minimal_strategy),
          "cmd_template"
        )
      end)
    end)

    describe('with cmd_wd given as absolute path', function()
      it('prepends a `cd` as appropriate', function()
        local pipe = {
          cmd_wd = "/etc/ssl",
          cmd_template = "cmd_template",
        }

        MiniTest.expect.equality(
          compute_cmd_result(pipe, "/proc", minimal_strategy),
          "cd /etc/ssl && cmd_template"
        )

        MiniTest.expect.equality(
          compute_cmd_result(pipe, "/etc", minimal_strategy),
          "cd ssl && cmd_template"
        )

        MiniTest.expect.equality(
          compute_cmd_result(pipe, "/etc/ssl", minimal_strategy),
          "cmd_template"
        )
      end)
    end)

    describe('with cmd_wd given as relative path', function()
      it('interprets cmd_wd relative to the cwd', function()
        local cwd = Path.cwd()

        local pipe = {
          cmd_wd = "..",
          cmd_template = "cmd_template"
        }

        local expected_cdpath = cwd:parent()

        MiniTest.expect.equality(
          compute_cmd_result(pipe, cwd:tostring(), minimal_strategy),
          "cd " .. expected_cdpath .. " && cmd_template"
        )
      end)

      describe('with path_root', function()
        it('interprets cmd_wd relative to path_root', function()
          local pipe = {
            cmd_wd = "ssl",
            path_root = "/etc",
            cmd_template = "cmd_template"
          }

          MiniTest.expect.equality(
            compute_cmd_result(pipe, "/proc", minimal_strategy),
            "cd /etc/ssl && cmd_template"
          )

          MiniTest.expect.equality(
            compute_cmd_result(pipe, "/etc", minimal_strategy),
            "cd ssl && cmd_template"
          )

          MiniTest.expect.equality(
            compute_cmd_result(pipe, "/etc/ssl", minimal_strategy),
            "cmd_template"
          )
        end)
      end)
    end)
  end)

  describe('file_path interpolation w.r.t. file_path_root, cmd_wd and path_root', function()
    it('with absolute file_path_root', function()
      local pipe = {
        file_path_root = "/etc",
        file_path = "/etc/passwd",
        cmd_template = "echo {}"
      }

      MiniTest.expect.equality(
        compute_cmd_result(pipe, "/proc", minimal_strategy),
        "echo passwd"
      )

      MiniTest.expect.equality(
        compute_cmd_result(pipe, "/etc", minimal_strategy),
        "echo passwd"
      )
    end)

    it('with relative file_path_root, with path_root', function()
      local pipe = {
        path_root = "/etc",
        file_path_root = "ssl",
        file_path = "/etc/ssl/README",
        cmd_template = "echo {}"
      }

      MiniTest.expect.equality(
        compute_cmd_result(pipe, "/proc", minimal_strategy),
        "echo README"
      )

      MiniTest.expect.equality(
        compute_cmd_result(pipe, "/etc", minimal_strategy),
        "echo README"
      )
    end)

    it('without file_path_root', function()
      local pipe = {
        file_path = "/etc/ssl/README",
        cmd_template = "echo {}"
      }

      local assertions = function()
        MiniTest.expect.equality(
          compute_cmd_result(pipe, "/proc", minimal_strategy),
          "echo /etc/ssl/README"
        )

        MiniTest.expect.equality(
          compute_cmd_result(pipe, "/etc", minimal_strategy),
          "echo ssl/README"
        )
      end

      assertions()

      pipe.path_root = "/etc"
      assertions()
    end)
  end)
end)

it('executes', function()
  local pipe = {
    strategy_spec = "test_execution executes",
    file_path = "/etc/ssl/README",
    cmd_template = "echo {}"
  }

  local executed_cmd

  local strategy = Strategy:new({ path_escape_mode = false, options = {}})
  function strategy:execute(cmd)
    executed_cmd = cmd
  end
  Strategy.inventory[pipe.strategy_spec] = strategy

  from_pipe_result(pipe):perform()

  MiniTest.expect.equality(executed_cmd, "echo /etc/ssl/README")
end)
