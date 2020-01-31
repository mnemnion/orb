


















local Peg   = require "espalier:peg"
local Node  = require "espalier:node"
local table = require "core:core/table"



local Header    = require "orb:orb/header"
local Codeblock = require "orb:orb/codeblock"
local Prose     = require "orb:orb/prose"
local fragments = require "orb:orb/fragments"



local Doc_str = [[
            doc  ←  first-section* section+
`first-section`  ←  blocks

        section  ←  header line-end blocks*
         header  ←  " "* "*"+ " " (!"\n" 1)*
                 /   " "* "*"+ &"\n"

       `blocks`  ←  block (block-sep* block)* block-sep*
        `block`  ←  structure
                 /  paragraph
    `structure`  ←  codeblock
                 /  table
                 /  list
                 /  handle-line
                 /  hashtag-line
                 /  drawer
   `block-sep`   ←  "\n\n" "\n"*

     codeblock   ←  code-start (!code-end 1)* code-end
   `code-start`  ←  "#" ("!"+)@codelevel code-type@code_c (!"\n" 1)* "\n"
     `code-end`  ←  "\n" "#" ("/"+)@(#codelevel) code-type@(code_c)
                     (!"\n" 1)* line-end
                 /  -1
    `code-type`  ←  symbol

          table  ←  table-head table-line*
   `table-head`  ←  (" "* handle_h* " "*)@table_c
                    "|" (!"\n" 1)* ("\n" / -1)
   `table-line`  ←  (" "*)@(#table_c) "|" (!line-end 1)* line-end

           list  ←  (list-line / numlist-line)+
      list-line  ←  ("- ")@list_c (!"\n" 1)* (!line-end 1)* line-end
                    (!(" "* [0-9] ". ")
                    (" "+)@(>list_c) !"- "
                    (!line-end 1)* line-end)*
                 /  (" "+ "- ")@list_c (!"\n" 1)* (!line-end 1)* line-end
                    (!(" "* [0-9] ". ")
                    (" "+)@(>=list_c) !"- " (!line-end 1)* line-end)*
   numlist-line  ←  ([0-9]+ ". ")@numlist_c (!line-end 1)* line-end
                    (!(" "* "- ")
                    (" "+)@(>numlist_c) (!"\n" 1)* line-end)*
                 /  (" "+ [0-9]+ ". ")@numlist_c (!line-end 1)* line-end
                    (!(" "* "- ")
                    (" "+)@(>=numlist_c) (!"\n" 1)* line-end)*

    handle-line  ←  handle (!line-end 1)* line-end

   hashtag-line  ←  hashtag (!line-end 1)* line-end

         drawer  ←  drawer-top line-end
                    ((structure "\n"* / (!drawer-bottom prose-line)+)+
                    / &drawer-bottom)
                    drawer-bottom
   `drawer-top`  ←  " "* ":[" (!"\n" !"]:" 1)*@drawer_c "]:" &"\n"
`drawer-bottom`  ←  " "* ":/[" (!"\n" !"]:" 1)*@(drawer_c) "]:" line-end

      paragraph  ←  (!header !structure par-line (!"\n\n" "\n")?)+
     `par-line`  ←  (!"\n" 1)+
    prose-line   ←  (!"\n" 1)* "\n"
     `line-end`  ←  (block-sep / "\n" / -1)
]] .. fragments.symbol .. fragments.handle .. fragments.hashtag











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
                   codeblock = Codeblock,
                   paragraph = Prose, }



return Peg(Doc_str, DocMetas, nil, post)
