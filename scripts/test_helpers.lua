return {
  clear_requires = function()
    local keys = {}
    for key, _ in pairs(package.loaded) do
      if key:match("^nvim%-file%-runner.") then
        table.insert(keys, key)
      end
    end

    for _, key in ipairs(keys) do
      package.loaded[key] = nil
    end
  end
}
