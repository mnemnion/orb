
































































































local Scroll = require "scroll:scroll"
local Set = require "set:set"

local knitters = require "orb:knit/knitters"

core = assert(core)



local Knitter = {}
Knitter.__index = Knitter



local insert = assert(table.insert)


function Knitter.knit(knitter, skein)
   local doc = skein.source.doc
   local knitted
   if skein.knitted then
      knitted = skein.knitted
   else
      knitted = {}
      skein.knitted = knitted
   end
   knitted.scrolls = knitted.scrolls or {}
   local scrolls = knitted.scrolls
   -- specialize the knitter collection and create scrolls for each type
   local knit_set = Set()
   for code_type in doc :select 'code_type' do
      knit_set:insert(knitters[code_type:span()])
   end
   for knitter, _ in pairs(knit_set) do
      local scroll = Scroll()
      scrolls[knitter.code_type] = scroll
      -- #todo this is awkward, find a better way to do this
      scroll.line_count = 1
      scroll.path = skein.source.file.path
                       :subFor(skein.source_base,
                               skein.knit_base,
                               knitter.code_type)
      if not scroll.path then
         scroll.path = "no path created"
      end
   end
   for codeblock in doc :select 'codeblock' do
      -- retrieve line numbers
      local code_type = codeblock:select 'code_type'() :span()
      for knitter in pairs(knit_set) do
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
