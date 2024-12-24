local M = {}

M.__index = M

function M.new(cond, effect, set_name)
  local self = setmetatable({}, M)
  self.cond = cond
  self.effect = effect
  self.set_name = set_name
  return self
end

function M:does_apply(pipe)
  return self.cond:does_apply(pipe)
end

function M:requirements()
  return self.cond.requirements
end

function M:comes_before(other)
  local weight = self.cond.weight
  local other_weight = other.cond.weight

  if weight == other_weight then
    -- Since this function is used for sorting, we have to
    -- return a stable value in this case:
    return self.cond:was_created_before(other.cond)
  else
    -- more lightweight conditions sort up:
    return weight < other_weight
  end
end

function M:provides_any_of(requirements)
  return self.effect:provides_any_of(requirements)
end

function M:apply(pipe)
  return self.effect:apply(pipe)
end

return M
