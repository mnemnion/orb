










local Stator = setmetatable({}, {__index = Stator})












local function call(stator)
  return setmetatable({}, {__index = stator, __call = call })
end









local function new(Stator)
  local stator = call(Stator)
  stator.g, stator.G, stator._G = stator, stator, stator
  return stator
end




return setmetatable(Stator, {__call = new})
