# Tagger


  The tagger implements the Orb tag engine\.

This receives a Skein, and walks the enclosed Doc, finding tags \(hashtags and
handles\), and assigning them to a tag map attached to the Skein\.

This ends up being a pretty gnarly algorithm, since the relationship between
where a tag is, and what it refers to, is non\-trivial\.  But we need to
establish this relationship in order to do all of the interesting things which
Orb is designed to do\.

It's cleaner, as a matter of implementation, to do this in a single pass,
rather than to handle tag assignment if and only if we end up needing it\.  It
will be possible to push this out to the edge if necessary, which I expect it
won't be\.


```lua
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
```

```lua
return Tagger
```
