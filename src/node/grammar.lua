



local L = require "lpeg"

local s = require "status" 
if _VERSION == "Lua 5.1" then
  local setfenv = assert( setfenv )
else
  local setfenv
end














































local function makeAstNode(id, first, t, last, metatables)
    t.first = first
    t.last  = last
  if metatables[id] then
    t = metatables[id](t)

  else
    setmetatable(t, Node)
    t.id = id
  end
    return t 
end

local function anonNode (t) 
  return unpack(t)
end














local function define(func, metas, g)









  g = g or {}
  local suppressed = {}
  local env = {}
  local node_mts = metas or {}
  local env_index = {
    START = function( name ) g[ 1 ] = name end,
    SUPPRESS = function( ... )
      suppressed = {}
      for i = 1, select( '#', ... ) do
        suppressed[ select( i, ... ) ] = true
      end
    end,
  }












  setmetatable( env_index, { __index = _G } )
  setmetatable( env, {
    __index = env_index,
    __newindex = function( _, name, val )
      if suppressed[ name ] then
        local v = L.Ct( val ) / anonNode
          g[name] = v
      else
        local v = (L.Cc( name ) 
                * L.Cp 
                * L.Ct( val ) 
                * L.Cp 
                * L.Cc(node_mts)) / makeAstNode
          g[name] = v
      end
    end
  } )
  -- call passed function with custom environment (5.1- and 5.2-style)
  if _VERSION == "Lua 5.1" then
    setfenv( func, env )
  end
  func( env )
  assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
  return g
end



local function new(grammar_template, metas)
    local metas = metas or {}
  if type(grammar_template) == 'function' then
    local grammar = define(grammar_template,  metas)
    io.write("type of grammar is " .. type(grammar) .. "\n")
    for k,v in pairs(grammar) do
      io.write("  " .. tostring(k) .. "  " .. tostring(v) .. "\n")
    end
    return grammar
  else
    s:halt("no way to build grammar out of " .. type(template))
  end
end



return new
