





local Peg = require "espalier:peg"
local Set = require "set:set"
local core = require "core:core"
local Twig = require "orb:orb/metas/twig"
local fragments = require "orb:orb/fragments"

local ProseMetas = require "orb:orb/metas/prosemetas"



local prose_str = [[
               prose  ←  ( escape
                          / link
                          / italic
                          / bold
                          / strike
                          / literal
                          / verbatim
                          / underline
                          / raw )+

              escape  ←  "\\" {*/~_=`][}
                link  ←  "[[" (!"]" 1)+ "]" WS*  ("[" (!"]" 1)+ "]")* "]"
                      /  "[[" (!"]" 1)+ "]" (!(WS /"]") 1)* "]"

                bold  ←   bold-start bold-body bold-end
        `bold-start`  ←  "*"+@bold-c !WS
          `bold-end`  ←  "*"+@(bold-c)
         `bold-body`  ←  ( WS+ (!non-bold !bold-end fill)+
                          / WS* non-bold
                          / (!non-bold !bold-end fill)+ )+
         `non-bold`   ←  italic / strike / underline / literal / verbatim

              italic  ←  italic-start italic-body italic-end
      `italic-start`  ←  "/"+@italic-c !WS
        `italic-end`  ←  "/"+@(italic-c)
       `italic-body`  ←  ( WS+ (!non-italic !italic-end fill)+
                          / WS* non-italic
                          / (!non-italic !italic-end fill)+ )+
       `non-italic`   ←  bold / strike / underline / literal / verbatim

              strike  ←  strike-start strike-body strike-end
      `strike-start`  ←  "~"+@strike-c !WS
        `strike-end`  ←  "~"+@(strike-c)
       `strike-body`  ←  ( WS+ (!non-strike !strike-end fill)+
                                / WS* non-strike
                                / (!non-strike !strike-end fill)+ )+
        `non-strike`  ←  bold / italic / underline / literal / verbatim

           underline  ←  underline-start underline-body underline-end
   `underline-start`  ←  "_"+@underline-c !WS
     `underline-end`  ←  "_"+@(underline-c)
    `underline-body`  ←  ( WS+ (!non-underline !underline-end fill)+
                             / WS* non-underline
                             / (!non-underline !underline-end fill)+ )+
     `non-underline`  ←  bold / italic / strike / literal / verbatim

            literal  ←  literal-start literal-body literal-end
    `literal-start`  ←  "="+@literal-c
      `literal-end`  ←  "="+@(literal-c)
     `literal-body`  ←  (!literal-end 1)+

     verbatim  ←  verbatim-start verbatim-body verbatim-end
    `verbatim-start`  ←  ("`" "`"+)@verbatim-c
      `verbatim-end`  ←  ("`" "`"+)@(verbatim-c)
     `verbatim-body`  ←  (!verbatim-end 1)+

              `fill`  ←  !WS 1
                WS    ←  (" " / "\n")
              `raw`   ←  ( !bold
                            !italic
                            !strike
                            !literal
                            !verbatim
                            !underline
                            !escape
                            !link (word / punct / WS) )+
              word  ←  (!t 1)+
             punct  ←  {\n.,:;?!)(][\"}+
]] .. fragments.t

















local bounds = { bold      = "*",
                 italic    = "/",
                 literal   = "=",
                 verbatim  = "`",
                 underline = "_",
                 strike    = "~" }
local bookends = Set(core.keys(bounds))



local byte = assert(string.byte)
local insert = assert(table.insert)

local function _makeBooks(bound, str, first, last)
   local count = 0
   while true do
      if byte(str, first + count + 1) ~= bound then
         break
      end
      -- may as well prevent infinite work on malformed input...
      if first + count + 1 > last then break end
      count = count + 1
   end
   local head = setmetatable({ first = first,
                               last  = first + count,
                               str   = str,
                               id    = "bound" }, Twig)
   local tail = setmetatable({ first = last - count,
                               last  = last,
                               str   = str,
                               id    = "bound" }, Twig)
   return head, tail, count
end


local function _fillGen(bookended)
   local bound = byte(bounds[bookended.id])
   local str, first, last = bookended.str, bookended.first, bookended.last
   if #bookended == 0 then
      local head, tail, count = _makeBooks(bound, str, first, last)
      local body = setmetatable({ first = first + count + 1,
                                  last  = last - count - 1,
                                  str   = str,
                                  id    = "body" }, Twig)
      insert(bookended, head)
      insert(bookended, body)
      insert(bookended, tail)
   else
      local head, tail, count = _makeBooks(bound, str, first, last)
      -- temporary array to hold the new collection
      local new_order = {head}
      local next_first = head.last + 1
      -- test and capture first text
      if next_first ~= bookended[1].first then
      insert(new_order, setmetatable({ first = next_first,
                                       last  = bookended[1].first - 1,
                                       str   = str,
                                       id    = "word" }, Twig))
      end
      -- test and capture interspersed text
      for i = 2, #bookended do
         insert(new_order, bookended[i - 1])
         if not (bookended[i - 1].last + 1 == bookended[i].first) then
            local inter = setmetatable({ first = bookended[i - 1].last + 1,
                                         last  = bookended[i].first - 1,
                                         str   = str,
                                         id    = "word" }, Twig)
            insert(new_order, inter)
         end
      end
      insert(new_order, bookended[#bookended])
      -- test and capture end text
      if bookended[#bookended].last ~= bookended.last then
         local hip = setmetatable({ first = bookended[#bookended].last + 1,
                                    last  = bookended.last - count - 1,
                                    str   = str,
                                    id    = "word" }, Twig)
         insert(new_order, hip)
      end
      for i, node in ipairs(new_order) do
         bookended[i] = node
      end
      insert(bookended, tail)
   end
end



local function _prosePost(prose)
   for node in prose:walk() do
     if bookends[node.id] then
        _fillGen(node)
     end
   end
   return prose
end





local proseMetas = { Twig,
                      WS   =  require "orb:orb/metas/ws",
                      link =  require "orb:orb/link"  }

core.addall(proseMetas, require "orb:orb/metas/prosemetas")

local prose_grammar = Peg(prose_str, proseMetas, nil, _prosePost).parse









local function prose_fn(t)
   local match = prose_grammar(t.str, t.first, t.last)
   if match then
       if match.last == t. last then
         -- label the match according to the rule
         match.id = t.id or "prose"
         return match
       else
         match.id = t.id .. "-INCOMPLETE"
         return match
       end
   end
   -- if error:
   t.id = "prose-nomatch"
   return setmetatable(t, Node)
end



return prose_fn
