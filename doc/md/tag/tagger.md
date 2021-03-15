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


#### imports

```lua
local Set = require "set:set"
```


#### Taggable categories

These are the parents of a tag which can receive tags\.

```lua
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
```


## Tagger

Implements the actual tagging mechanism\.

```lua
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
```

```lua
return Tagger
```
