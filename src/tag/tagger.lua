



















local tag_ids = { hashtag = true, handle = true }

local sub = assert(string.sub)

local insert = assert(table.insert)


local function Tagger(skein)
   local tags = {}
   skein.tags = tags
   for node in skein.source.doc:walk() do
      if tag_ids[node.id] then
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

