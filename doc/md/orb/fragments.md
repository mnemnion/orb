# Fragments


  A collection of PEG rules which stand alone, and are added in various places
to proper Grammars.


The first newline in a Lua long string is not included in the body, so these
appear to have an 'extra' newline.

```lua
local fragments = {}
```
### gap

This is for lookahead, matching various tokens which represent the end of
certain complex types (ex: URLs), which are otherwise difficult to cleanly
terminate, without consuming the match.

```lua
local gap_str = [[
    `gap`  <-  { \n([)]} / -1
]]
fragments.gap = gap_str
```
### hashtag

```lua
local hashtag_h_str = [[

   `hashtag_h`  ←  "#" (!gap 1)+
]] .. gap_str

local hashtag_str = [[

   hashtag  ←  hashtag_h
]] .. hashtag_h_str

fragments.hashtag = hashtag_str
fragments.hashtag_h = hashtag_h_str
```
### handle

```lua
local handle_h_str = [[

  `handle_h`  ← "@" (!gap 1)+
]]

local handle_str = [[

   handle  ←  handle_h
]] .. handle_h_str

fragments.handle = handle_str
fragments.handle_h = handle_h_str
```
### symbol

This is a hidden rule.


It's pretty bog-standard in programming circles, but I don't know how useful
it will actually be in Orb, where we tend to be more permissive about naming
things.


I can imagine circumstances where we might want to constrain a handle to only
be followed by a symbol (the handle rule is currently written that way, but
this will change).  An obvious example is if the name is going to be used in
source code, where (with the exception of the dark-horse hyphen) this is a
pretty standard definition.


In which case, we'd give the handle a different rule name, and the same
metatable with the same ``.id`` of ``handle``.

```lua
local symbol_str = [[

   `symbol`  <-  (([a-z]/[A-Z]) ([a-z]/[A-Z]/[0-9]/"-"/"_")*)
]]
fragments.symbol = symbol_str
```
### t

``t`` because ``term`` sounds like, well, a term, and ``terminal`` is too long for
the place in rules which this occupies.


This rule matches something which stops a contiguous sequence of characters.
Loosely, it's anything which might end a word in a sentence.


It's uniformly invoked as ``&t`` or ``!t``, depending, but we hide it just in
case we do need to consume it.

```lua
local term_str = [[

   `t` = { \n.,:;?!)(][\"} / -1
]]
fragments.t = term_str
```
### utf8

Represents a single valid utf8 code point.

```lua
local utf8_str = [[
   `utf8`  ←  [\x00-\x7f]
           /  [\xc2-\xdf] [\x80-\xbf]
           /  [\xe0-\xef] [\x80-\xbf] [\x80-\xbf]
           /  [\xf0-\xf4] [\x80-\xbf] [\x80-\xbf] [\x80-\xbf]
]]
```
```lua
return fragments
```
