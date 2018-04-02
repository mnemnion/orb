 
```lua
local L = require( "lpeg" )

local assert = assert
local string, io = assert( string ), assert( io )
local V = string.sub( assert( _VERSION ), -4 )
local _G = assert( _G )
local error = assert( error )
local pairs = assert( pairs )
local next = assert( next )
local type = assert( type )
local tostring = assert( tostring )
local setmetatable = assert( setmetatable )
local setfenv = setfenv
local getfenv = getfenv
if V == " 5.1" then
  assert( setfenv )
  assert( getfenv )
end


-- module table
local epnf = {}


local function make_ast_node( id, pos, t, pos_b, str )
  t.id = id
  t.pos = pos
  t.pos_b = pos_b
  t.str = string.sub(str,pos, pos_b -   1)

  return t
end


-- some useful/common lpeg patterns
local Cp = L.Cp
local Cc = L.Cc
local Ct = L.Ct
local L_Carg_1 = L.Carg( 1 )


-- setup an environment where you can easily define lpeg grammars
-- with lots of syntax sugar
function epnf.define( func, g, e )
  g = g or {}
  if e == nil then
    e = V == " 5.1" and getfenv( func ) or _G
  end
  local suppressed = {}
  local env = {}
  local env_index = {
    START = function( name ) g[ 1 ] = name end,
    SUPPRESS = function( ... )
      suppressed = {}
      for i = 1, select( '#', ... ) do
        suppressed[ select( i, ... ) ] = true
      end
    end,
  }

  setmetatable( env_index, { __index = e } )
  setmetatable( env, {
    __index = env_index,
    __newindex = function( _, name, val )
      if suppressed[ name ] then
        g[ name ] = val
      else
        g[ name ] = (Cc( name ) 
              * Cp() 
              * Ct( val )
              * Cp()
              * L_Carg_1) / make_ast_node
      end
    end
  } )
  -- call passed function with custom environment (5.1- and 5.2-style)
  if V == " 5.1" then
    setfenv( func, env )
  end
  func( env )
  assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
  return g
end


-- apply a given grammar to a string and return the ast. also allows
-- to set the name of the string for error messages
function epnf.parse( g, name, input, ... )
  return L.match( L.P( g ), input, 1, name, ... ), name, input
end


-- apply a given grammar to the contents of a file and return the ast
function epnf.parsefile( g, fname, ... )
  local f = assert( io.open( fname, "r" ) )
  local a,n,i = epnf.parse( g, fname, assert( f:read"*a" ), ... )
  f:close()
  return a,n,i
end


-- apply a given grammar to a string and return the ast. automatically
-- picks a sensible name for error messages
function epnf.parsestring( g, str, ... )
  local s = string.sub( str, 1, 20 )
  if #s < #str then s = s .. "..." end
  local name = "[\"" .. string.gsub( s, "\n", "\\n" ) .. "\"]"
  return epnf.parse( g, name, str, ... )
end


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

-- write a string representation of the given ast to stderr for
-- debugging
function epnf.dumpast( node )
  return dump_ast( node, "" )
end


-- export a function for reporting errors during ast validation
epnf.raise = raise_error


-- return module table
return epnf
```
