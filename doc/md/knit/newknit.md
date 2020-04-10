# Knit

#NB we're gating the old and new parser/compiler pathways, so this is
functions needed to keep compiling Orb source code, while being expandable
into a true literate programming system.


For the first goal, we must keep doing what we're doing: by default, a sorcery
file will have a one-to-one relationship to its source code, and there will be
one such sorcery for each type of codeblock in the source.


But this relationship is _normal_ rather than necessary or inevitable, so we
want to generate a source map as soon as practical.


For now, the design goal is to allow for the possibility of producing multiple
types of sorcery based on multiple different code blocks, and to offer the
affordances necessary to do more complex sorts of labor.


The kniter will therefore receive the entire skein, not just the Doc in the
source table.  The skein is expected to carry any additional pieces of
information (example: pieces of code to transclude or macroexpand) needed to
complete the act of knitting the source doc.


### Structure

  I can tell that I have a long way to go on this module, because my sense of
how to structure it is still hazy.


I do know that the input is a Skein, which needs to contain the Doc, and any
fragments needed to perform transclusion or macroexpension.  Any other
configuration is also carried by the skein.


The output, which is attached to the skein rather than returned, needs to be
able to accomodate multiple text artifacts, and it's likely that it will bear
messages as well.  It's probably okay for messages to be a skein-level
abstraction, and that's all the handwaving I'll do on that for now.


The artifacts themselves will be instances of [[scroll][@br/scroll]], with the
open question being how to organize the table.


I'm thinking that the table should be keyed by 'type', which we can
provisionally treat as equivalent to the file extension. The values should be
an array table containing scrolls, and scrolls should be clever enough to have
an optional File with associated Path.


Overriding the default Path with a custom one through the tag engine is an
example of a message which could be passed by a knitter, or more likely
attached to the skein during the spin phase.


### Initial Implementation

This is going to get quite a bit more complex, but not right away.


For now, we'll have a Knitter, which is a collection of language-specific
knitters.  The minimum is completely standard and simply takes the contents of
appropriate codeblocks and inserts enough newlines that the lines line up.


More interesting is to include a predicate function, which triggers an
"asLang" pathway.  I want this functionality working soon, because the first
and second cases are SQL and PEG/espalier format.


We want to take a block that looks like this:

```orb

#!sql @create-dog-table #as_lua
CREATE dog (dog_id INTEGER, name TEXT, age NUMBER);
```
#/orb
about it to turn ``@Insert.dog`` into an assignment to an existing ``Insert``
table, by dropping the otherwise mandatory ``local``.


This isn't a substitute for transclusion, but a complement to it. SQL is SQL,
and we want to be able to maintain a single literate document describing data
structures and transclude it anywhere it might be useful.


We would still need to massage it somewhat to turn it into the target
language.  While this can be accomplished through macroexpansion, I deem it
more readable and better to embody the simplest transformations in this sort
of common pattern.


Making this general, eloquent, and extensible, will take a few iterations.


#### imports

```lua
local Scroll = require "scroll:scroll"
```
```lua
local Knitter = {}
Knitter.__index = Knitter
```
```lua
function Knitter.knit(knitter, skein)
   local doc = skein.source.doc
   local knit
   if skein.knit then
      knit = skein.knit
   else
      skein.knit = {}
      knit = skein.knit
   end
   for section in doc:select "section" do
      -- iterate blocks
      for block in ipairs(section) do
         if section.id == "codeblock" then
            -- add codeblock to scroll:
            -- detect type
            -- create scroll(s) of type if necessary
            -- add scroll
         else
            -- for now:
            -- get number of lines in section
            -- add equivalent newlines to scrolls
         end
      end
   end
end
```
```lua
local function new()
   local knitter = setmetatable({}, Knitter)
   return knitter
end

Knitter.idEst = new
```
```lua
return new
```