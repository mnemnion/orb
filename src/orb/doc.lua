



















local Peg   = require "espalier:peg"
local table = require "core:core/table"



local Twig      = require "orb:orb/metas/twig"
local Header    = require "orb:orb/header"
local Codeblock = require "orb:orb/codeblock"
local Table     = require "orb:orb/table"
local Prose     = require "orb:orb/prose"
local List      = require "orb:orb/list"
local Listline  = require "orb:orb/list-line"
local fragments = require "orb:orb/fragments"








local Doc_str = [[
            doc  ←  (first-section / section) section*
`first-section`  ←  blocks

        section  ←  header line-end blocks*
         header  ←  " "* "*"+ " " (!"\n" 1)*
                 /   " "* "*"+ &"\n"

       `blocks`  ←  block (block-sep* block)* block-sep*
        `block`  ←  structure
                 /  paragraph
    `structure`  ←  codeblock
                 /  blockquote
                 /  table
                 /  list
                 /  handle-line
                 /  hashtag-line
                 /  link-line
                 /  drawer
      block-sep  ←  "\n\n" "\n"*

      codeblock  ←  code-start (!code-end 1)* code-end
   `code-start`  ←  "#" ("!"+)@codelevel code-type@code_c (!"\n" 1)* "\n"
     `code-end`  ←  "\n" "#" ("/"+)@(#codelevel) code-type@(code_c)
                     (!"\n" 1)* line-end
                 /  -1
    `code-type`  ←  symbol?

     blockquote  ←  block-line+ line-end
     block-line  ←  " "* "> " (!"\n" 1)* (!"\n\n" "\n")?

          table  ←  table-head table-line*
   `table-head`  ←  (" "* handle_h* " "*)@table_c
                    "|" (!"\n" 1)* ("\n" / -1)
   `table-line`  ←  (" "*)@(#table_c) "|" (!line-end 1)* line-end

           list  ←  (list-line / numlist-line)+
      list-line  ←  ("- ")@list_c (!line-end 1)* line-end
                    (!(" "* list-num)
                    (" "+)@(>list_c) !"- "
                    (!line-end 1)* line-end)*
                 /  (" "+ "- ")@list_c (!line-end 1)* line-end
                    (!(" "* list-num)
                    (" "+)@(>=list_c) !"- " (!line-end 1)* line-end)*
   numlist-line  ←  list-num@numlist_c (!line-end 1)* line-end
                    (!(" "* "- ")
                    (" "+)@(>numlist_c)
                    !list-num (!line-end 1)* line-end)*
                 /  (" "+ list-num)@numlist_c (!line-end 1)* line-end
                    (!(" "* "- ")
                    (" "+)@(>=numlist_c)
                    !list-num (!line-end 1)* line-end)*
     `list-num`  ←  [0-9]+ ". "

    handle-line  ←  handle (!line-end 1)* line-end

   hashtag-line  ←  hashtag (!line-end 1)* line-end

      link-line  ←  link-open obelus link-close link line-end
      link-open  ←  "["
         obelus  ←  (!"]" 1)+
     link-close  ←  "]: "
           link  ←  (!line-end 1)*


         drawer  ←  drawer-top line-end
                    ((structure "\n"* / (!drawer-bottom prose-line)+)+
                    / &drawer-bottom)
                    drawer-bottom
   `drawer-top`  ←  " "* ":[" (!"\n" !"]:" 1)*@drawer_c "]:" &"\n"
`drawer-bottom`  ←  " "* ":/[" (!"\n" !"]:" 1)*@(drawer_c) "]:" line-end

      paragraph  ←  (!header !structure par-line (!"\n\n" "\n")?)+
     `par-line`  ←  (!"\n" 1)+
     prose-line  ←  (!"\n" 1)* "\n"
       line-end  ←  (block-sep / "\n" / -1)
]]





Doc_str = Doc_str .. fragments.symbol .. fragments.handle .. fragments.hashtag











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
            -- add to section
            parent[#parent + 1] = section
            -- remove from doc
            doc[i] = nil
            -- adjust .last fields
            parent.last = section.last
            local under
            repeat
               under = parent
               parent = _parent(levels, under)
               parent.last = section.last
            until parent == under
         end
         levels[#levels + 1] = section
      end
   end
   compact(doc, top)
   return doc
end























local Linkline = Twig:inherit "link-line"

Linkline.toMarkdown = Twig.nullstring




local DocMetas = { Twig,
                   header       = Header,
                   codeblock    = Codeblock,
                   table        = Table,
                   paragraph    = Prose,
                   list         = List,
                   list_line    = Listline,
                   numlist_line = Listline,
                   link_line    = Linkline, }



local addall = assert(table.addall)

addall(DocMetas, require "orb:orb/metas/docmetas")



return Peg(Doc_str, DocMetas, nil, post)

