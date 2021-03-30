





















local Set = require "set:set"
local Annotate = require "status:annotate"








local taggable = Set {
   'section',
   'header',
   'list_line',
   'numlist_line',
   'codeblock',
   'blockquote',
   'handle_line',
   'hashtag_line',
   'table',
   'drawer',
}








local sub, lower = assert(string.sub), assert(string.lower)
local insert = assert(table.insert)












local function _taggableParent(node, doc)
   local parent = node.parent
   while parent ~= doc do
      if taggable :∈ (parent.id) then
         break
      end
      parent = parent.parent
   end
   return parent
end











local function _capitalTag(tag)
   local first = sub(tag, 1, 1)
   if lower(first) == first then
      return false, tag
   else
      return true, lower(first) .. sub(tag, 2)
   end
end







local function _tagUp(tags, node, tag, note)
   note("tagging a %s on line %d with %s", node.id, (node:linePos()), tag)
   tags[tag] = tags[tag] or {}
   insert(tags[tag], node)
   tags[node] = tags[node] or {}
   tags[node][tag] = true
end








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
   -- some are as simple as just tagging the parent
   codeblock  = _tagUp,
   blockquote = _tagUp,
   table      = _tagUp,
   drawer     = _tagUp,

}

-- numlist_lines use the list_line logic
_capTagResolve.numlist_line = _capTagResolve.list_line



local function Tagger(skein)
   local note = skein.note or Annotate()
   skein.note = note
   local doc = assert(skein.source.doc, "No doc found on Skein")
   local tags = {}
   skein.tags = tags
   for node in doc:walk() do
      if node.id == 'hashtag' then
         -- this is where all the gnarly stuff happens
         -- for now, add the node itself to the tag collection
         local tagspan = sub(node.str, node.first + 1, node.last)
         local tag_parent = _taggableParent(node, doc)
         local iscap, tag = _capitalTag(tagspan)
         if iscap then
            note("capital tag %s on %s, made into %s",
                  tagspan, tag_parent.id, tag)
            _capTagResolve[tag_parent.id](tags, tag_parent, tag, note)
         else
            note("miniscule tag %s on %s", tag, tag_parent.id)
            _tagUp(tags, tag_parent, tag, note)
         end
      end
   end

   return skein
end



return function(skein)
   local ok, res = pcall(Tagger, skein)
   if ok then return skein end
   skein.note("error: %s", res)
   return skein
end

