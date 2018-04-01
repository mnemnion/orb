



local L = require "node/elpeg"

local s = require "status" 
if _VERSION == "Lua 5.1" then
  local setfenv = assert( setfenv )
else
  local setfenv
end














































local function makeAstNode(id, first, t, last, metatables, str, root)
    t.first = first
    t.last  = last
  t.str   = str -- This belongs on the Root metatable
  t.root  = root -- Also wrong, good enough for now.   
  if metatables[id] then
    t = metatables[id](t)

  else
    setmetatable(t, Node)
    t.id = id
  end
  if t[1] and #t == 1 and type(t[1]) == 'string' then
    -- here we're just checking that C(patt) does
    -- the expected thing
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
    E = E,
    EOF = EOF,
    ID = ID,
    W = W,
    WS = WS,
  }
  -- copy lpeg shortcuts
  for k,v in pairs( L ) do
    if string.match( k, "^%u%w*$" ) then
      env_index[ k ] = v
    end
  end











  setmetatable( env_index, { __index = _G } )
  setmetatable( env, {
    __index = env_index,
    __newindex = function( _, name, val )
      if suppressed[ name ] then
        local v = L.Ct( val ) / anonNode
          g[name] = v
      else
        local v = (L.Cc( name ) 
                * L_Cp 
                * L.Ct( val ) 
                * L_Cp 
                * L.Cc(node_mts)
                * L.Carg(1)
                * L.Carg(2)) / makeAstNode
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
  if type(template) == 'function' then
    local grammar = define(grammar_template,  metas)
    return function(str)
            return L.match(L.P(grammar), str, 1, 'grammar', str, {}) -- other 
         end
  else
    s:halt("no way to build grammar out of " .. type(template))
  end
end



return new
