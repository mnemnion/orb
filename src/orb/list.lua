









































































local Twig = require "orb:orb/metas/twig"
local table = require "core:core/table"
local anterm = require "anterm:anterm"
local c = require "singletons/color" . color -- #todo remove

local s = require "status:status" ()
s.verbose = false






local List = Twig :inherit 'list'

local super_strExtra = Twig . strExtra

function List.strExtra(list)
   local phrase = super_strExtra(list)
   return phrase .. anterm.magenta(tostring(list.indent))
end





















































local DEPTH = 512
local function _parent(list, dent, list_line)
   local parent = list
   local count = 1
   repeat
      parent = parent.parent
      count = count + 1
   until parent.indent <= dent or count == DEPTH
   if count >= DEPTH then
      s:warn(anterm.red("infinite loop or absurdly deep list folding!"))
      s:warn(debug.traceback())
   end
   return parent
end



local function _makesublist(parent, line)
   if not line then
      s:verb("no line! \n %s", debug.traceback())
   end
   local sublist = { first = line.first,
                     last = line.last,
                     parent = parent,
                     str = line.str }
   local lead = { first = line.first,
                  last = line.last,
                  parent = sublist,
                  str = line.str,
                  id = 'lead' }
   setmetatable(lead, Twig)
   sublist[1] = lead
   lead[1] =  line
   line.parent = lead
   return setmetatable(sublist, List)
end



local insert, compact = assert(table.insert), assert(table.compact)

local function _insert(list, list_line)
   insert(list, list_line)
   list_line.parent = list
   list.last = list_line.last
   -- the base list won't have a parent yet
   if not list.parent then return end
   local parent = list.parent
   while parent.parent and parent.id == 'list' do
      parent.last = list_line.last
      local newparent = parent.parent
      parent = newparent
   end
   --]]
end

local function post(list)
   local linum = list:linePos()
   local top = #list
   local base = list[1].indent
   -- add an indent to the list itself
   list.indent = base
   -- tracking variables:
   local dent = base
   local work_list = list
   for i = 1, top do
      -- is it an indent line?
      if not list[i].indent then
         local id, line, col = list[i].id, list[i]:linePos()
         s:verb("no indent on %s at line %d, col %d", id, line, col)
      end
      if list[i].indent > dent then
         -- handle base list a bit differently
         if work_list == list then
            -- make a list from the previous line
            local sublist = _makesublist(work_list, list[i - 1])
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
            local sublist = _makesublist(work_list, work_list[#work_list])
            -- this moves the tip of the work list to the lead of the sub list
            -- so we need to remove it from the work list
            work_list[#work_list] = nil
            dent = list[i].indent
            sublist.indent = dent
            _insert(work_list, sublist)
            _insert(sublist, list[i])
            list[i] = nil
            work_list = sublist
         end
      elseif dent > base and dent == list[i].indent then
         -- put it in the worklist
         _insert(work_list, list[i])
         list[i] = nil
      elseif list[i].indent < dent then
         -- get a new work_list
         work_list = _parent(work_list, list[i].indent, list[i])
         if work_list ~= list then
            _insert(work_list, list[i])
            dent = list[i].indent
            list[i] = nil
         else -- otherwise, we leave the line in-place
            dent = list[i].indent
         end
      else -- otherwise we have a list_line we can leave in place
         local linstart = list[i]:linePos()
      end
   end
   compact(list, top)
   return list
end













local function List_fn(list, offset)
   setmetatable(list, List)
   return post(list)
end



return List_fn

