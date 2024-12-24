package.path = package.path .. ";./scripts/?.lua;./lua/?.lua"

-- fail deliberately (This makes the usual test runner code not be skipped)
error("continue")

