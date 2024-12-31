local Helpers = require("test_helpers")
Helpers.clear_requires()

local Inventory = require("nvim-file-runner.inventory")

T = MiniTest.new_set()

T['works as s store with error handling'] = function()
  local I = Inventory.new("I")
  local J = Inventory.new("J")

  I.foo = 1
  MiniTest.expect.equality(I.foo, 1)

  J.bar = 2
  MiniTest.expect.equality(J.bar, 2)

  local p1, p2 = pcall(function()
    return I.bar
  end)
  MiniTest.expect.equality(p1, false)
  MiniTest.expect.equality(not not p2.handle, true)
end

return T
