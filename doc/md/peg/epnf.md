 
 A modified epnf.

```lua
local L = require( "lpeg" )
---[[
local assert = assert
local _VERSION = assert( _VERSION )
local string, io = assert( string ), assert( io )
local error = assert( error )
local pairs = assert( pairs )
local next = assert( next )
local type = assert( type )
local tostring = assert( tostring )
local setmetatable = assert( setmetatable )

if _VERSION == "Lua 5.1" then
  local setfenv = assert( setfenv )
else
  local setfenv
end
--]]
```

 module table

```lua
local epnf = {}
```

 Node metatable

```lua
epnf.Node = require "peg/node"
```

 maximum of two numbers while avoiding math lib as a dependency

```lua
local function max( a, b )
  if a < b then return b else return a end
end
```

 get the line which p points into, the line number and the position
 of the beginning of the line

```lua
local function getline( s, p )
  local lno, sol = 1, 1
  for i = 1, p do
    if string.sub( s, i, i ) == "\n" then
      lno = lno + 1
      sol = i + 1
    end
  end
  local eol = #s
  for i = sol, #s do
    if string.sub( s, i, i ) == "\n" then
      eol = i - 1
      break
    end
  end
  return string.sub( s, sol, eol ), lno, sol
end
```

 raise an error during semantic validation of the ast

```lua
local function raise_error( n, msg, s, p )
  local line, lno, sol = getline( s, p )
  assert( p <= #s )
  local clen = max( 70, p+10-sol )
  if #line > clen then
    line = string.sub( line, 1, clen ) .. "..."
  end
  local marker = string.rep( " ", p-sol ) .. "^"
  error(":"..lno..": "..msg.."\n"..line.."\n"..marker, 0 )
end
```

 parse-error reporting function

```lua
local function parse_error( s, p, n, e )
  if p <= #s then
    local msg = "parse error"
    if e then msg = msg .. ", " .. e end
    raise_error( n, msg, s, p )
  else -- parse error at end of input
    local _,lno = string.gsub( s, "\n", "\n" )
    if string.sub( s, -1, -1 ) ~= "\n" then lno = lno + 1 end
    local msg = ": parse error at <eof>"
    if e then msg = msg .. ", " .. e end
    error( n..":"..lno..msg, 0 )
  end
end
```
### make_ast_node

This needs to look for a metatable in the defined parser.


Which means we need to pass that in. 


```lua
local function make_ast_node(metatables, id, first, t, last, str, root)
  if type(t[1]) == "table" then    
    if t[1].span then
        t.val = t[1].val
        t.first = t[1].first
        t.last = t[1].last
        t[1] = nil
    else
      t.first = first
      t.last = last
    end
    t.id = id
    t.root = root
    setmetatable(t,epnf.Node)
    return t
  end
end

local function anon_node (t) 
  return unpack(t)
end
```

 some useful/common lpeg patterns

```lua
local L_Cp = L.Cp()
local L_Carg_1 = L.Carg( 1 )
local function E( msg )
  return L.Cmt( L_Carg_1 * L.Cc( msg ), parse_error )
end
local function EOF( msg )
  return -L.P( 1 ) + E( msg )
end
local letter = L.R( "az", "AZ" ) + L.P"_"
local digit = L.R"09"
local ID = L.C( letter * (letter+digit)^0 )
local function W( s )
  return L.P( s ) * -(letter+digit)
end
local WS = L.S" \r\n\t\f\v"
```

setup an environment where you can easily define lpeg grammars
 with lots of syntax sugar

```lua
function epnf.define( func, g, unsuppressed)
  g = g or {}
  local suppressed = {}
  local env = {}
  local node_mts = {}
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
      if suppressed[ name ] and not unsuppressed then
        local v = L.Ct( val ) / anon_node
          g[ name ] = v
      else
        local v = ( L.Cc(node_mts)
                * L.Cc( name ) 
                * L_Cp 
                * L.Ct( val ) 
                * L_Cp 
                * L.Carg(1)
                * L.Carg(2)) / make_ast_node
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

 apply a given grammar to a string and return the ast. also allows
 to set the name of the string for error messages

```lua
function epnf.parse( g, name, input, ... )
  return L.match( L.P( g ), input, 1, name, ... ), name, input
end
```

 apply a given grammar to the contents of a file and return the ast

```lua
function epnf.parsefile( g, fname, ... )
  local f = assert( io.open( fname, "r" ) )
  local a,n,i = epnf.parse( g, fname, assert( f:read"*a" ), ... )
  f:close()
  return a,n,i
end
```

 apply a given grammar to a string and return the ast. automatically
 picks a sensible name for error messages

```lua
function epnf.parsestring( g, str, ... )
  local s = string.sub( str, 1, 20 )
  if #s < #str then s = s .. "..." end
  local name = "[\"" .. string.gsub( s, "\n", "\\n" ) .. "\"]"
  return epnf.parse( g, name, str, ... )
end
```

 export a function for reporting errors during ast validation

```lua
epnf.raise = raise_error

local function write( ... ) return io.stderr:write( ... ) end

local function dump_ast( node, prefix )
  if type( node ) == "table" then
    write( "{" )
    if next( node ) ~= nil then
      write( "\n" )
      if type( node.id ) == "string" and
         type( node.pos ) == "number" then
        write( prefix, "  id = ", node.id,
               ",  pos = ", tostring( node.pos ), "\n" )
      end
      for k,v in pairs( node ) do
        if k ~= "id" and k ~= "pos" then
          write( prefix, "  ", tostring( k ), " = " )
          dump_ast( v, prefix.."  " )
        end
      end
    end
    write( prefix, "}\n" )
  else
    write( tostring( node ), "\n" )
  end
end
```

 write a string representation of the given ast to stderr for
 debugging

```lua
function epnf.dumpast( node )
  return dump_ast( node, "" )
end
```

 return module table

```lua
return epnf
```
