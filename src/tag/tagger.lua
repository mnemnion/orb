





















local Set = require "set:set"








local taggable = Set {
   'section',
   'header',
   'list_line',
   'codeblock',
   'blockquote',
   'handle_line',
   'hashtag_line',
   'table',
   'drawer'
}








local sub = assert(string.sub)
local insert = assert(table.insert)

local function _taggableParent(node, doc)
   local parent = node.parent
   while parent ~= doc do
      if taggable :∈ (parent.id) then
         break
      end
   end
   return parent
end

local function Tagger(skein)
   local doc = assert(skein.source.doc, "No doc found on Skein")
   local tags = {}
   skein.tags = tags
   for node in doc:walk() do
      if node.id == 'hashtag' then
         -- this is where all the gnarly stuff happens
         -- for now, add the node itself to the tag collection
         local tagspan = sub(node.str, node.first + 1, node.last)
         tags[tagspan] = tags[tagspan] or {}
         insert(tags[tagspan], node)
         tags[node] = tags[node] or {}
         tags[node][tagspan] = true
      end
   end

   return skein
end



return Tagger

