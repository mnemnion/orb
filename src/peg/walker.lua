






















local util = require "lib/util"
local backwalk = {}

local function make_backref (ast)
   return function() return ast end
end


local function index_gen ()
   local first = {}
   local last  = {}
   local closed = {}
   local depth = {}
   local length = 0
   local meta  = util.F()
   meta.__call = function(_, ordinal)
      return first[ordinal], last[ordinal], depth[ordinal]
   end
   -- This override requires 5.2
   meta.__len = function() return length end
   closed.len = function() return length end
   closed.add = function(table, deep)
      length = length+1
      first[length] = table
      first[table]  = length -- Janus table!
       depth[length] = deep
       depth[table]  = deep
   end
   closed.close = function(table)
      last[first[table]] = length
      last[table] = length
   end
   setmetatable(closed,meta)
   return closed
end

function backwalk.walk_ast (ast)
   local index = index_gen()
   local str = ast.str
   local function walker (ast, parent, deep)
      deep = deep + 1
      if ast.isnode then
         index.add(ast,deep)
         for i, v in ipairs(ast) do
            if type(v) == "table" and v.isnode then
                walker(v,ast, deep)
            end
         end
         ast.parent = make_backref(parent)
         index.close(ast)
       end
   end
   walker(ast,ast,0)
   ast.index = index
   return ast 
end

return backwalk
