


















local Peg = require "espalier:peg"
local Node = require "espalier:node"
local table = require "core:core/table"



local Header = require "orb:orb/header"
local Codeblock = require "orb:orb/codeblock"
local fragments = require "orb:orb/fragments"



local Doc_str = [[
            doc  ←  first-section* section+
`first-section`  ←  blocks

        section  ←  header line-end blocks*
         header  ←  " "* "*"+ " " (!"\n" 1)*
                 /   " "* "*"+ &"\n"

       `blocks`  ←  block (block-sep block)* block-sep*
        `block`  ←  codeblock / table / list / numbered-list / proseblock
    `block-sep`  ←  "\n\n" "\n"*

     codeblock   ←  code-start (!code-end 1)* code-end
   `code-start`  ←  "#" ("!"+)@codelevel code-type@code_c (!"\n" 1)* "\n"
     `code-end`  ←  "\n" "#" ("/"+)@(#codelevel) code-type@(code_c)
                     (!"\n" 1)* line-end
    `code-type`  ←  symbol

           list  ←  list-line+
      list-line  ←  (" "* "- ")@list_c (!"\n" 1)* (!line-end 1)* line-end
                    ((" "+)@(>=list_c) !"- " (!line-end 1)* line-end)*


  numbered-list  ←  numlist-line+
   numlist-line  ←  (" "* [0-9]+ "." " ")@numlist_c (!line-end 1)* line-end
                       ((" "+)@(>=numlist_c) (!"\n" 1)* line-end)*

          table  ←  "placeholder"
     proseblock  ←  (!"\n\n" !header 1)+
     `line-end`  ←  (block-sep / "\n" / -1)
]] .. fragments.symbol











local compact = assert(table.compact)

local function _parent(levels, section)
   local top = #levels
   if top == 0 then
      return section
   end
   local level = section :select "level"() :len()
   for i = top, 1, -1 do
      local p_level = levels[i] :select "level"() :len()
      if p_level < level then
         return levels[i]
      end
   end
   return section
end

local function post(doc)
   local levels = {}
   local top = #doc
   for i = 1, top do
      local section = doc[i]
      if section:select "section" () then
         local parent = _parent(levels, section)
         if parent ~= section then
            parent[#parent + 1] = section
            doc[i] = nil
         end
         levels[#levels + 1] = section
      end
   end
   compact(doc, top)
   return doc
end











local DocMetas = { header = Header,
                   codeblock = Codeblock, }



return Peg(Doc_str, DocMetas, nil, post)
