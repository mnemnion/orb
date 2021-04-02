# Twig


Every Node in Orb inherits from this common table\.

```lua
local Node = require "espalier:espalier/node"
local a = require "anterm:anterm"
local Set = require "set:set"
local Codepoints = require "singletons:singletons/codepoints"
local Phrase = require "singletons:singletons/phrase"
```


## Twig Module

For speed, we're going to copy everything from Node, rather than inheriting in
the usual sense\.

```lua
local Twig = {}

for k,v in next, Node do
   Twig[k] = v
end

Twig.__index = Twig
Twig.id = "twig"
```


### Twig:select\(pred\)

\#NB:


Every call to `select` has to iterate the entire Node\.

For some of the algorithms we've contemplated, that could get pretty
expensive\.  In addition, the structure of an already\-parsed Node may be
mutated somewhat, but at least the `id` field will remain consistent by the
time that parsing is complete\.

So we'll handle this by memoizing selections that are based on strings\.

```lua
local _select = Node.select

function Twig.select(twig, pred)
   if type(pred) == "function" then
      return _select(twig, pred)
   end
   local memo
   twig.__memo = twig.__memo or {}
   if twig.__memo[pred] then
      memo = twig.__memo[pred]
   else
      memo = {}
      for result in _select(twig, pred) do
         memo[#memo + 1] = result
      end
      twig.__memo[pred] = memo
   end
   local cursor = 0
   return function()
      cursor = cursor + 1
      if cursor > #memo then
         return nil
      end
      return memo[cursor]
   end
end
```


### Twig:bustCache\(\)

`:bustCache` is sent to a Node as part of a graft\.

Since grafting a Node will invalidate our selector caches, we
clear them here:

\#NB

```lua
function Twig.bustCache(twig)
   twig.__memo = nil
end
```


## Twig:toMarkdown\(scroll\)

The base operation for converting a Doc particle to Markdown is to filter it
for escapeable characters\.

The Markdown this produces is less readable, but from a bit of light testing,
these escapes are allowed anywhere, with a few exceptions which are handled
separately\.

```lua
local md_special = Set {"\\", "`", "*", "_", "{", "}", "[", "]", "(", ")",
                        "#", "+", "-", ".", "!"}

function Twig.toMarkdown(twig, scroll)
   if #twig == 0 then
      local points = Codepoints(twig:span())
      for i , point in ipairs(points) do
         if md_special(point) then
            points[i] = "\\" .. point
         end
      end
      scroll:add(tostring(points))
   else
      for _, sub_twig in ipairs(twig) do
         sub_twig:toMarkdown(scroll)
      end
   end
end
```


#### Twig:toHtml\(\)

The default for a Twig is a `span` tag\.

I will probably come back around and rewrite this using an htmlification
generator function, once it feels like I have the basics down\.

```lua
local function _escapeHtml(span)
   -- stub
   return span
end

function Twig.toHtml(twig, skein)
   local phrase = '<span class="' .. twig.id .. Phrase '">'
   if #twig == 0 then
      phrase = phrase .. _escapeHtml(twig:span())
   else
      for _, sub_twig in ipairs(twig) do
         phrase = phrase .. sub_twig:toHtml(skein)
      end
   end
   return phrase .. "</span>"
end
```


### Twig:nullstring\(\)

There are a bunch of circumstances where we need a function
which simply returns `""`, and we may as well keep a single
function around to perform this\.

```lua
function Twig.nullstring()
   return ""
end
```

```lua
return Twig
```
