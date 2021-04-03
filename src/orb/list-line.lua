




local subGrammar = require "espalier:espalier/subgrammar"
local Peg = require "espalier:espalier/peg"
local Twig = require "orb:orb/metas/twig"
local prose = require "orb:orb/prose"
local fragments = require "orb:orb/fragments"
local anterm = require "anterm:anterm"


local listline_str = [[
     list-line  ←  depth number* sep WS
                   (cookie / radio)*
                   (key colon text / text) cookie* list-end
         depth  ←  " "*
        number  ←  [0-9]+
           sep  ←  "-" / "."
        cookie  ←  "[" (!"]" 1)+ "]"
         radio  ←  "(" 1 ")" ; this should be one utf-8 character
           key  ←  " "* (handle / hashtag / (!":" !gap 1)+) " "*
         colon  ←  ":" &(ws (!ws 1))
          text  ←  (!(cookie list-end / list-end) 1)+
            WS  ←  ws
          `ws`  ←  { \n}+
      list-end  ←  "\n"* -1
]]


listline_str = listline_str .. fragments.gap
               .. fragments.handle .. fragments.hashtag







local Sep = Twig:inherit 'sep'

function Sep.toMarkdown(sep, scroll)
   scroll:add(sep:span())
end






local Cookie = Twig:inherit 'cookie'
Cookie.toMarkdown = Sep.toMarkdown






local listline_Meta = { Twig,
                        text = prose,
                        sep = Sep,
                        cookie = Cookie }
local listline_grammar = Peg(listline_str, listline_Meta).parse








local Listline = Twig:inherit "list_line"


local super_strExtra = Twig . strExtra

function Listline.strExtra(list_line)
   local phrase = super_strExtra(list_line)
   return phrase .. anterm.magenta(tostring(list_line.indent))
end
















local gsub = assert(string.gsub)

local function makeAdjustment(level_space)
   return function(str)
      return gsub(str, '\n[ ]+', level_space)
   end
end

function Listline.toMarkdown(list_line, scroll)
   local phrase = ""
   local level_space = "\n" .. (" "):rep(list_line.indent + 2)
   local defer = makeAdjustment(level_space)
   local close_mark = scroll:deferStart(defer)
   for _, node in ipairs(list_line) do
      node:toMarkdown(scroll)
   end
   scroll:deferFinish(close_mark)
end




local function listline_fn(t)
   local match = listline_grammar(t.str, t.first, t.last)
   if match then
       if match.last == t.last then
         -- label the match according to the rule
         match.id = t.id or "list_line"
         match.indent = match:select"sep"().last - match.first + 2
         return setmetatable(match, Listline)
       else
         match.id = t.id .. "_INCOMPLETE"
         return match
       end
   end
   -- if error:
   -- we need to fix the list line grammar to recognize more lists, but for
   -- now, we know it makes mistakes. So we're just going to post-process
   -- it in a sort of ugly way
   setmetatable(t, Listline)
   t.id = 'list_line_nomatch'
   local _, sep_end = t:span():find('%s+- ')
   t.indent = sep_end
   return setmetatable(t, Twig)
end





return listline_fn

