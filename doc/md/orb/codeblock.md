# Codeblock


  Inner parser for code blocks.


This is a good example of how we can extract different syntactic information
at different levels.


For example: we know that the last line will be a ``code-end``, so we don't have
to detect a matching number of ``!`` and ``/``, and we don't have to check that
the closing line is flush with the margin, only that it's the final non-blank
line in the block.


In this instance, we're partially working around a limitation of the Lpeg
engine: any capture will reset named captures, so back references don't work
across rule boundaries.


Even if I'm able to fix this, and I have some ideas there, this is still a
good strategy (IMHO) for parsing complex documents.


For example, we might eventually add Lua parsing to Lua code blocks, and so
on for other languages.  This would make for a tediously long definition of
a Doc, and one in which the parsers are less composable.

```lua
local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local fragments = require "orb:orb/fragments"
```
```lua
local code_str = [[
    codeblock  ←  code-start code-body  code-end
   code-start  ←  "#" "!"+ code-type* (" "+ name)* rest* "\n"
    code-body  ←  (!code-end 1)+
     code-end  ←  "#" "/"+ code-type* execute* (!"\n" 1)* line-end
               /  -1
    code-type  ←  symbol
   `line-end`  ←  ("\n\n" "\n"* / "\n")* (-1)
         name  ←  handle
      execute  ←  "(" " "* ")"
       `rest`  ←  (handle / hashtag / raw)+
         raw   ←  (!handle !hashtag !"\n" 1)+
]] .. fragments.symbol .. fragments.handle .. fragments.hashtag
```
```lua
local code_peg = Peg(code_str)
```
```lua
return subGrammar(code_peg.parse, "code-nomatch")
```