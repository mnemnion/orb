









































































local Twig = require "orb:orb/metas/twig"
local table = require "core:core/table"






local List = Twig :inherit 'list'






local function _parent(list, dent)
   local parent;
   repeat
      parent = list.parent
   until parent.indent == dent
   return parent
end



local function _makesublist(list_line)
   local sublist = { first = list_line.first,
                     last = list_line.last }
   local lead = { first = list_line.first,
                  last = list_line.last,
                  parent = sublist,
                  id = 'lead' }
   sublist[1] = lead
   lead[1] =  list_line
   list_line.parent = lead
   return setmetatable(sublist, List)
end



local insert, compact = assert(table.insert), assert(table.compact)

local function _insert(list, list_line)
   insert(list, list_line)
   list_line.parent = list
   list.last = list_line.last
end

local function post(list)
   local top = #list
   local base = list[1] -- always 2 by the grammar but that could change
   -- add an indent to the list itself
   list.indent = base
   -- tracking variables:
   local dent = base
   local work_list = list
   for i = 1, top do
      -- is it an indent line?
      if list[i].indent > dent then
         -- handle base list a bit differently
         if work_list == list then
            -- make a list from the previous line
            local sublist = _makesublist(list[i - 1])
            dent = list[i].indent
            sublist.indent = dent
            -- insert working line
            _insert(sublist, list[i])
            -- replace prior line with list
            list[i - 1] = sublist
            -- nil out working line
            list[i] = nil
            -- replace the work list
            work_list = sublist
         else
            local sublist = _makesublist(work_list[#work_list])
            dent = list[i].indent
            sublist.indent = dent
            _insert(sublist, list[i])
            list[i] = nil
            work_list = sublist
         end
      elseif dent > base and dent == list[i].indent then
         -- put it in the worklist
         _insert(work_list, list[i])
         list[i] = nil
      elseif dent < list[i].indent then
         -- get a new work_list
         work_list = _parent(work_list, list[i].indent)
         _insert(work_list, list[i])
         dent = list[i].indent
         list[i] = nil
      end -- otherwise we have a list_line we can leave in place
   end
   compact(list, top)
   return list
end







local subgrammar = require "espalier:espalier/subgrammar"
local Twig = require "orb:orb/metas/twig"



local list_str = [[
     list
]]

