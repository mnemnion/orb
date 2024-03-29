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

The artifact this generates is a tag map, found at `skein.tags`\. This is
a bidirectional map: if given a tag, it returns an array of all Nodes which
are tagged with that tag, in the order in which they appear in the
document\.  If given a Node, it will return an array of all tags which pertain
to that Node\.

Both a Node and a tag can appear twice in a given array, this will happen if
a capital tag, such as `#Todo`, sub\-tags something like a `list_item`, and
that list item also has the miniscule tag `#todo`: or indeed, the capital tag
`#Todo`\.  I think this is the right way to approach that situation, and it
would be moderately expensive to prevent it \(a linear search every time
something is added is fundamentally O\(m\*n\) despite that both parameters have
been narrowed\)\.

It does mean that care must be taken to either do idempotent things, detect
duplicates, or intend that an action be taken twice if this situation arises\.


#### imports

```lua
local Set = require "set:set"
```

```lua
local s = require "status:status" ()
```


#### Taggable categories

These are the parents of a tag which can receive tags\.

```lua
local taggable = Set {
   'header',
   'list_line',
   'section',
   'numlist_line',
   'codeblock',
   'blockquote',
   'paragraph',
   'handle_line',
   'hashtag_line',
   'table',
   'drawer',
}
```


## Tagger

Implements the actual tagging mechanism\.

```lua
local sub, lower = assert(string.sub), assert(string.lower)
local insert = assert(table.insert)
```


### \_taggableParent\(node, doc\)

Returns the parent of the tag Node which is "taggable"\.

Also passed the Doc, to facilitate checking for root\.  This could also be
done with node\.parent == node, but this is more robust, and we have the Doc
handy\.

```lua
local function _taggableParent(node, doc, note)
-- note("finding parent of %s", node.id)
   local parent = node.parent
   while parent ~= doc do
      -- note("checking parent %s", parent.id)
      if taggable :∈ (parent.id) then
         break
      end
      parent = parent.parent
   end
   return parent
end
```


### \_capitalTag\(tag\)

Receives the text of the tag, checking it for initial capitalization\.

If capitalized, returns `true` and the minimized version of the tag, if not,
`false` and the original tag text\.

```lua
local function _capitalTag(tag)
   local first = sub(tag, 1, 1)
   if lower(first) == first then
      return false, tag
   else
      return true, lower(first) .. sub(tag, 2)
   end
end
```

### \_tagUp\(tags, tag, node\)

We make a map of tag\-to\-node, and node\-to\-tag\.

```lua
local function _tagUp(tags, node, tag, note)
   note("tagging a %s on line %d with %s", node.id, (node:linePos()), tag)
   tags[tag] = tags[tag] or {}
   insert(tags[tag], node)
   tags[node] = tags[node] or Set {}
   tags[node][tag] = true
end
```


### \_clingsDown\(cling\_line\)

This returns `true` if the line "clings" down, and `false` if it instead
clings up\.

The cling rule says that a hashtag line, or handle line, applies to the block
it is closer to, or if there is a tie, the block below it\.

```lua
local function _endPred(node)
   if node.id == "line_end" or node.id == "block_sep" then
      return true
   else
      return false
   end
end

local function _clingsDown(cling_line, note)
   local back, front = cling_line :selectBack(_endPred)(),
                       cling_line :selectFrom(_endPred, cling_line.first)()
   local backlen = back and back:len() or 0
   local frontlen = front and front:len() or 0

   note("back length %d front length %d", backlen, frontlen)
   --[[
   if back then
      note("back token %s", back:strLine())
   end
   if front then
      note("front token %s", front:strLine())
   end
   --]]

   return backlen >= frontlen
end
```


#### \_\(cap|min\)TagResolve\[id\]\(tags, parent, tag, note\)

  A table of functions which resolve a capital or minimal tag, based on the
type of parent\.

```lua
-- a set of whitespace-esque possible block values, which we don't want
-- to tag during the cling rule
local skippable = Set {'block_sep', 'line_end'}
-- I don't know that line_end will ever come up but we may as well exclude it

local _capTagResolve = {
   list_line = function(tags, list_line, tag, note)
      if list_line.parent.id ~= 'lead' then
         -- no children on a list line, just apply the tag
         _tagUp(tags, list_line, tag, note)
         return
      end
      local list = list_line.parent.parent
      local function _tagChildren(l)
         note("tagging children of list on line %d", list_line:linePos())
         for _, child in ipairs(l) do
            if child.id == 'lead' then
               -- tag the list_line
               _tagUp(tags, child[1], tag, note)
            elseif child.id == 'list_line' or child.id == 'numlist_line' then
               _tagUp(tags, child, tag, note)
            elseif child.id == 'list' then
               _tagChildren(child)
            else
               note("encountered a strange child: %s", child.id)
            end
         end
      end
      _tagChildren(list)
   end,
   header = function(tags, header, tag, note)
      local section = header.parent
      note("tagging %s and subsections with %s on line %d",
           section.id, tag, section:linePos())
      _tagUp(tags, section, tag, note)
      local function _tagChildren(sec)
         for _, child in ipairs(sec) do
            if child.id == 'section' then
               note("tagging subsection on line %d", child:linePos())
               _tagUp(tags, child, tag, note)
               _tagChildren(child)
            end
         end
      end
      _tagChildren(section)
   end,
   hashtag_line = function(tags, hashtag_line, tag, note)
      local clingsDown = _clingsDown(hashtag_line, note)
      local section = hashtag_line.parent
      assert(section.id == 'section' or section.id == 'doc',
             "found tagline parent with id " .. section.id)
      local cD = clingsDown and "clings down" or "clings up"
      note("tagline parent is %s, %s", section.id, cD)
      local index;
      for i = 1, #section do
         if section[i] == hashtag_line then
            index = i
         end
      end
      -- rummage around for valid blocks to tag before and after the index
      local prior, after;
      local cursor = index - 1
      while not prior do
         if section[cursor] and (not skippable(section[cursor].id)) then
            prior = section[cursor]
         elseif cursor == 0 then
            -- leave prior nil
            break
         else
            cursor = cursor - 1
         end
      end
      cursor = index + 1
      while not after do
         if section[cursor] and (not skippable(section[cursor].id)) then
            after = section[cursor]
         elseif cursor == #section + 1 then
            break
         else
            cursor = cursor + 1
         end
      end
      if not after then
         note("no after")
      end
      if not prior then
         note("no prior")
      end

      if clingsDown then
         -- can't tag down if we're at the end of the Doc
         if not after then
            note("forcing cling up at end of Doc")
            if not prior then
               -- this can happen if a Doc is just a hashtag line
               note("didn't find a valid taggable before or after, weird")
            else
               _tagUp(tags, prior, tag, note)
            end
         else
            _tagUp(tags, after, tag, note)
         end
      else
         -- can't tag up if we're in the first block of a Doc
         if prior then
            _tagUp(tags, prior, tag, note)
         elseif not after then
            note("didn't find a valid taggable before or after, weird")
         else
            _tagUp(tags, after, tag, note)
         end
      end
   end,
   -- some are as simple as just tagging the parent
   codeblock  = _tagUp,
   blockquote = _tagUp,
   paragraph  = _tagUp,
   table      = _tagUp,
   drawer     = _tagUp,
   handle_line = _tagUp,
}

-- numlist_lines use the list_line logic
_capTagResolve.numlist_line = _capTagResolve.list_line

-- miniscule tags are mostly just _tagUp
local _minTagResolve = {}

for field in pairs(taggable) do
   _minTagResolve[field] = _tagUp
end

_minTagResolve.hashtag_line = _capTagResolve.hashtag_line
```

```lua
local function hashtagAction(hashtag, skein)
   local line = hashtag:linePos()
   -- this is where all the gnarly stuff happens
   -- for now, add the hashtag itself to the tag collection
   local tagspan = sub(hashtag.str, hashtag.first + 1, hashtag.last)
   local tag_parent = _taggableParent(hashtag, skein.source.doc, skein.note)
   local iscap, tag = _capitalTag(tagspan)
   if iscap then
      skein.note("line %d: capital tag %s on %s, made into %s",
            line, tagspan, tag_parent.id, tag)
      local resolver = _capTagResolve[tag_parent.id]
      if resolver then
         resolver(skein.tags, tag_parent, tag, skein.note)
      else
         s:halt("no resolver function for %s", tag_parent.id)
      end
   else
      skein.note("line %d: miniscule tag %s on %s", line, tag, tag_parent.id)
      local resolver = _minTagResolve[tag_parent.id]
      if resolver then
         resolver(skein.tags, tag_parent, tag, skein.note)
      else
         s:halt("no resolver function for %s", tag_parent.id)
      end
   end
end

local function Tagger(skein)
   local doc = assert(skein.source.doc, "No doc found on skein")
   local tags = {}
   skein.tags = tags
   for node in doc:walk() do
      if node.id == 'hashtag' then
         hashtagAction(node, skein)
      end
   end

   return skein
end
```

```lua
return function(skein)
   local ok, res = xpcall(function() return Tagger(skein) end, debug.traceback)
   if ok then return skein end
   skein.note("error: %s", res)
   s:warn(res)
   return skein
end
```
