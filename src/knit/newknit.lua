
































































































local Scroll = require "scroll:scroll"
local Set = require "set:set"

local knitters = require "orb:knit/knitters"

core = assert(core)



local Knitter = {}
Knitter.__index = Knitter



local insert = assert(table.insert)


function Knitter.knit(knitter, skein)
   local doc = skein.source.doc
   local knit
   if skein.knit then
      knit = skein.knit
   else
      knit = {}
      skein.knit = knit
   end
   knit.scrolls = knit.scrolls or {}
   local scrolls = knit.scrolls
   -- specialize the knitter collection and create scrolls for each type
   local knit_set = Set()
   for code_type in doc :select 'code_type' do
      knit_set:insert(knitters[code_type:span()])
   end
   for knitter, _ in pairs(knit_set) do
      scrolls[knitter.code_type] = Scroll()
      -- #todo this is awkward, find a better way to do this
      scrolls[knitter.code_type].line_count = 1
   end
   for codeblock in doc :select 'codeblock' do
      -- retrieve line numbers
      local code_type = codeblock:select 'code_type'() :span()
      for knitter in pairs(knit_set) do
         -- #todo pass the right scroll for the code_type
         if knitter.code_type == code_type then
            knitter.knit(codeblock, scrolls[code_type], skein)
         end
         if knitter.pred(codeblock) then
            knitter.pred_knit(codeblock, scrolls[knitter.code_type], skein)
         end
      end
   end
   -- clean up unused scrolls
   for code_type, scroll in pairs(scrolls) do
      if #scroll == 0 then
         scrolls[code_type] = nil
      end
   end
end



local function new()
   local knitter = setmetatable({}, Knitter)

   return knitter
end

Knitter.idEst = new



return new
