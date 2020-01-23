# Doc

The parser will proceed outside-in, taking advantage of the fact that we can
assign functions as 'metatables' for Nodes, and the Grammar will obligingly
call that function on the semi-constructed table.


That function may in turn be a Grammar, which we can call with an offset, so
that the secondary parsing boundaries line up with the overall document
string.


We also have the ability to post-process a Grammar, which is handy, since a
few operations, notably making a heirarchy out of Sections, are better
performed once parsing is completed.  We're not _using_ that ability, but
that's why I put it there.


#### imports

```lua
local Peg = require "espalier:peg"
local Node = require "espalier:node"
```
```lua
local Header = require "orb:orb/header"
```
```lua
local Doc_str = [[
            doc  ←  first-section* section+
`first-section`  ←  blocks

        section  ←  header line-end blocks*
         header  ←  "*"+ " " (!"\n" 1)* ; this is one which we subclass
                   / "*"+ &"\n"

       `blocks`  ←  block (block-sep block)* block-sep*
          block  ←  codeblock / table / list / (!"\n\n" !header 1)+
    `block-sep`  ←  "\n\n" "\n"*

     codeblock   ←  code-start (!code-end 1)* code-end
   `code-start`  ←  "#" ("!"+)@codelevel code-name@code_c (!"\n" 1)* "\n"
     `code-end`  ←  "\n" "#" ("/"+)@(#codelevel) code-name@(code_c)
                     (!"\n" 1)* line-end
    `code-name`  ←  (([a-z]/[A-Z]) ([a-z]/[A-Z]/[0-9]/"-"/"_")*)*

          table  ←  "placeholder"
           list  ←  "placeholder"

     `line-end`  ←  (block-sep / "\n" / -1)
]]
```
```lua
local DocMetas = { header = Header}
```
```lua
return Peg(Doc_str):toGrammar(DocMetas)
```
