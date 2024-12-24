local Helpers = require("test_helpers")
Helpers.clear_requires()

local Strategy = require("nvim-file-runner.strategy")
local basic = Strategy.inventory.basic

T = MiniTest.new_set()

T['options handling'] = function()
  MiniTest.expect.equality(basic.options, {
    height = false,
    restore_on_success = false
  })

  local my_basic = basic:new({ options = { restore_on_success = true }})
  MiniTest.expect.equality(my_basic.options, {
    height = false,
    restore_on_success = true
  })
end

T['from_desc'] = function()
  local pipe
  local result

  pipe = { strategy = "basic" }
  result = Strategy.from_desc(pipe.strategy)
  MiniTest.expect.equality(result.options,
    {height = false, restore_on_success = false}
  )

  pipe = { strategy = { "basic", { restore_on_success = true } } }
  result = Strategy.from_desc(pipe.strategy)
  MiniTest.expect.equality(result.options,
    {height = false, restore_on_success = true}
  )
end

return T
