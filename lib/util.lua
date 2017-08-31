local ansi = require "ansi"
local cyan = tostring(ansi.cyan)
local magenta = tostring(ansi.magenta)
local clear = tostring(ansi.clear)
local green = tostring(ansi.green)

local util = {}

function util.publish(mod)
-- a utility for publishing modules.
-- makes a copy of the module, stripping all
-- values starting with `__`.
-- It returns the stripped form
local catch = {}
  for k,v in pairs(mod) do
      if type (k) == "string" 
       and k:sub(1,2) ~= "--" then
           catch[k] = v
      else end
    end
  return catch
end

function util.F ()
-- A method for functionalizing tables.
-- This lets us define both fn() and fn.subfn()
-- over a proper closure. 
-- All lookups on the "function" will return nil. 
  local meta = {}
  meta["__index"] = function(self,ordinal) 
    return self(ordinal)
  end
  meta["__newindex"] = function() return nil end
  return meta
end

function util.dive(tree)
  -- quick and dirty recurser. blows up the stack if 
  -- there are any cyclic references. 
  -- internal sanity check.
  for k,v in pairs(tree) do 
    if type(v) == "table" then
      dive(v)
    end
  end
  return nil, "contains no cyclic references"
end

function util.tableand(tablep, pred)
  if type(tablep) == "table" and pred then
    return true
  else
    return false
  end
end  

function util.flip()
  local coin = math.random(0,1)
  if coin == 0 then 
    return false
  else
    return true
  end
end

return util



















