# Knit


  Knitting is the action by which source files are converted into 'source
code', which we call sorcery to distinguish it from the actual source\.

This module needs to keep in tension two goals: to provide the critical
functions needed to keep compiling Orb source code, while being expandable
into a true literate programming system\.

For the first goal, we must keep doing what we're doing: by default, a sorcery
file will have a one\-to\-one relationship to its source code, and there will be
one such sorcery for each type of codeblock in the source\.

But this relationship is *normal* rather than necessary or inevitable, so we
want to generate a source map as soon as practical\.

For now, the design goal is to allow for the possibility of producing multiple
types of sorcery based on multiple different code blocks, and to offer the
affordances necessary to do more complex sorts of labor\.

The kniter will therefore receive the entire skein, not just the Doc in the
source table\.  The skein is expected to carry any additional pieces of
information \(example: pieces of code to transclude or macroexpand\) needed to
complete the act of knitting the source doc\.


### Structure

  I can tell that I have a long way to go on this module, because my sense of
how to structure it is still hazy\.

I do know that the input is a Skein, which needs to contain the Doc, and any
fragments needed to perform transclusion or macroexpension\.  Any other
configuration is also carried by the skein\.

The output, which is attached to the skein rather than returned, needs to be
able to accomodate multiple text artifacts, and it's likely that it will bear
messages as well\.  It's probably okay for messages to be a skein\-level
abstraction, and that's all the handwaving I'll do on that for now\.

The artifacts themselves will be instances of [scroll](orb/-/blob/trunk/doc/mdUsers/atman/Dropbox/br/orb/orb/knit/knit.md), with the
open question being how to organize the table\.

I'm thinking that the table should be keyed by 'type', which we can
provisionally treat as equivalent to the file extension\. The values should be
an array table containing scrolls, and scrolls should be clever enough to have
an optional File with associated Path\.

Overriding the default Path with a custom one through the tag engine is an
example of a message which could be passed by a knitter, or more likely
attached to the skein during the spin phase\.


### Initial Implementation

This is going to get quite a bit more complex, but not right away\.

For now, we'll have a Knitter, which is a collection of language\-specific
knitters\.  The minimum is completely standard and simply takes the contents of
appropriate codeblocks and inserts enough newlines that the lines line up\.

More interesting is to include a predicate function, which triggers anasLang" pathway\.  I want this functionality working soon, because the first
and
" second cases are SQL and PEG/espalier format\.

We want to take a block that looks like this:

```orb

#!sql @create-dog-table #asLua
CREATE dog (dog_id INTEGER, name TEXT, age NUMBER);
#/sql

```

And parse that into a local variable long\-string\.  We can be smart enough
about it to turn `@Insert.dog` into an assignment to an existing `Insert`
table, by dropping the otherwise mandatory `local`\.

This isn't a substitute for transclusion, but a complement to it\. SQL is SQL,
and we want to be able to maintain a single literate document describing data
structures and transclude it anywhere it might be useful\.

We would still need to massage it somewhat to turn it into the target
language\.  While this can be accomplished through macroexpansion, I deem it
more readable and better to embody the simplest transformations in this sort
of common pattern\.

Making this general, eloquent, and extensible, will take a few iterations\.


#### imports

```lua
local Scroll = require "scroll:scroll"
local Set = require "set:set"

local knitters = require "orb:knit/knitters"

local core = require "core:core"
```

```lua
local Knitter = {}
Knitter.__index = Knitter
```

```lua
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
   -- specialize the knitter collection and create scrolls for each type
   local knit_set = Set()
   for codeblock in doc :select 'codeblock' do
      local code_type = codeblock :select 'code_type'()
      knit_set:insert(knitters[code_type and code_type:span()])
   end
   for knitter, _ in pairs(knit_set) do
      local scroll = Scroll()
      knitted[knitter.code_type] = scroll
      -- #todo this bakes in assumptions we wish to relax
      scroll.line_count = 1
      scroll.path = skein.source.file.path
                       :subFor(skein.source_base,
                               skein.knit_base,
                               knitter.code_type)
   end
   for codeblock in doc :select 'codeblock' do
      local code_type = codeblock :select 'code_type'() :span()
      local tagset = skein.tags[codeblock]
      if (not tagset) or (not skein.tags[codeblock] 'noKnit') then
         for knitter in pairs(knit_set) do
            if knitter.code_type == code_type then
               knitter.knit(codeblock, knitted[code_type], skein)
            end
            if knitter.pred(codeblock, skein) then
               knitter.pred_knit(codeblock, knitted[knitter.code_type], skein)
            end
         end
      end
   end
   -- clean up unused scrolls
   for code_type, scroll in pairs(knitted) do
      if #scroll == 0 then
         knitted[code_type] = nil
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


## Roadmap

  The initial implmentation covers us for continuing to develop in Orb format,
following the conventions which are already established\.

The step after that is to get source mapping working correctly, with a
database schema to store sourcemapped values, probably in `bridge.modules`\.
This will require making `scroll` into something more sophisticated than what
it is now\.

This has to be plugged into the error system, probably with an `xpcall` in
`pylon`\.

The next step involves macroexpansions and transclusions\.  The general
strategy here is to create a closure which will complete the work, when passed
the missing parameters needed to do it\.

This is then added to the Skein, and the Codex trolls through the Skeins
looking for uncompleted work, reaching outside itself, if necessary, to
complete it\.
