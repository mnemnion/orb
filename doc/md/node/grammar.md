# Grammar Module


```lua
local L = require "node/elpeg"

local s = require "status" 
if _VERSION == "Lua 5.1" then
  local setfenv = assert( setfenv )
else
  local setfenv
end
```
## define

  This is going to be a chopped-and-screwed version of epnf.  Now that I
actually understand what it does.


### problems

- We're gathering stuff twice.


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



 - [ ] #Todo


   - [ ]  Impose an intermediate Root metatable.  Where should this be 
          done?  Ideally these are added directly to the Node subclasses,
          before the parse, then removed when the parse completes.


     -  The easier way is to pass in a new Root and stick it on during
        makeAstNode.  This is unacceptably wasteful in a systems tool, but
        is also an optimization, so let's start with the clearer approach.


   - [ ]  Handle string captures as well as table captures. 

```lua
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
```
### define, proper

  I'm going to slice this into pieces in the Orb document, because a) it 
needs documentation and b) we're going to be customizing it, finally, to
suit our own needs. 

```lua
local function define(func, metas, g)
```

First step is set up our =_ENV=.


In a way this is an elaborate workaround for Lua's global-by-default 
antipattern, which we aim to eliminate with Lun.

```lua
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
```

Here's where the magic happens.


The __newindex method takes any new assignment in global, so
any grammar rules, and applies a consistent capture to them.


Now we get to figure out what that capture wants to be!

```lua
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
```
```lua
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
```
```lua
return new
```
