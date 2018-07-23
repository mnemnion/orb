












local L   = require "lpeg"
local s   = require "status" ()
local Carg, Cc, Cp, P = L.Carg, L.Cc, L.Cp, L.P



local Err = require "espalier/node" : inherit()
Err.id = "ERROR"









function Err.toLua(err)
  local line, col = err:linePos(err.first)
  s:halt("ERROR at line: " .. line .. " col: " .. col)
end








local function parse_error(pos, name, msg, patt, str)
   local message = msg or name or "Not Otherwise Specified"
   s:verb("Parse Error: ", message)
   local errorNode =  setmetatable({}, Err)
   errorNode.first =  pos
   errorNode.last  =  #str -- See above
   errorNode.msg   =  message
   errorNode.name  =  name
   errorNode.str   =  str
   errorNode.rest  =  string.sub(str, pos)
   errorNode.patt  =  patt

   return errorNode
end















function Err.Err(name, msg, patt)
  return Cp() * Cc(name) * Cc(msg) * Cc(patt) * Carg(1) / parse_error
end

Err.E = Err.Err

function Err.EOF(name, msg)
  return -P(1) + Err.Err(name, msg), Cp()
end

return Err
