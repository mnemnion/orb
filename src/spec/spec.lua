


local walk_spec = require "spec/walk-spec"






local function Specify()
  local results = {}
  local folder = walk_spec.folder .. "/"
  for class, fn in pairs(walk_spec) do
    results[folder .. class] = fn()
  end
  return results
end




return walk_spec
