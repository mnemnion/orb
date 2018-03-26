# Grammar Module


```lua
local L = require "node/elpeg"

local s = require "status"
local setfenv 
if _VERSION == "Lua 5.1" then
  setfenv = setfenv
  assert( setfenv )
end
```
## define

  This is going to be a chopped-and-screwed version of epnf.  Now that I
actually understand what it does.


### problems

- [ ] We're gathering stuff twice.


  -  The pattern of passing the string around is a good one.
       doing a match-time capture is therefore not necessary, we 
       should slice the value off the string. 


    -  This means we need to pass in an optional offset, in case we're
       working on a substring.  I need the Grammar class to be sufficiently
       general for my own purposes, and the Prose class needs the offset.

### makeAstNode

  Takes a bunch of params:


  - id :  Name of the rule
  - first :  First position
  - t     :  Table, which may contain other Nodes
  - last  :  Last position
  - metatables :  The metatable collection
  - str   :  The string we're parsing

```lua
local function makeAstNode(id, first, t, last, metatables, str)
    t.first = first
    t.last = last
    t.span = string.sub(str, first, last)
  t.id = id
  if metatables[id] then
    t = metatables[id](t)
  else
    setmetatable(t, Node)
  end
    return t 
  end
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
                * L.Carg(1)) / makeAstNode
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
```
```lua
local function new(grammar_template, metas)
  if type(template) == 'function' then
    local grammar = define(grammar_template,  metas)
    return function(str)
            return L.match(L.P(grammar), str, 1, 'grammar', str) -- other 
         end
  else
    s:halt("no way to build grammar out of " .. type(template))
  end
end
```
```lua
return new
```
