# Morphemes
 Morphemes are the basic structures of any language.


### Includes
```lua
local lpeg = require "lpeg"
local epeg = require "../peg/epeg"
local epnf = require "../peg/epnf"

local match = lpeg.match -- match a pattern against a string
local P = lpeg.P -- match a string literally
local S = lpeg.S  -- match anything in a set
local R = epeg.R  -- match anything in a range
local B = lpeg.B  -- match iff the pattern precedes the use of B
local C = lpeg.C  -- captures a match
local Csp = epeg.Csp -- captures start and end position of match
local Cg = lpeg.Cg -- named capture group (for **balanced highlighting**)
local Cb = lpeg.Cb -- Mysterious! TODO make not mysterious
local Cmt = lpeg.Cmt -- match-time capture
local Ct = lpeg.Ct -- a table with all captures from the pattern
local V = lpeg.V -- create a variable within a grammar
```
## Morpheme module
```lua
local m = {}
```
### Fundamentals
  These sequences are designed to be fundamental to several languages, Clu
in particular.

```lua
m.letter = R"AZ" + R"az"

m.digit = R"09"

m._ = P" "

m.WS = m._^0

m.NL = P"\n"

m.__TAB__ = P"\t" -- First thing we do is eliminate these
```
### Hoon layer
  I find mixing literals and token-likes in with variables distracting.
We use the Hoon names for ASCII tier glyphs.  It's one of the better urbit
innovations.

```lua
m.tar = P"*"
m.tars = P"*"^1
m.hax = P"#"
m.pat = P"@"
m.hep = P"-"
m.bar = P"|"
m.zap = P"!"
m.wut = P"?"
m.zaps = P"!"^1
m.fas = P"/"
m.fass = P"/"^1
m.dot = P"."
m.col = P":"

m.sel = P"["
m.ser = P"]"
m.pal = P"("
m.par = P")"
m.kel = P"{"
m.ker = P"}"
m.gal = P"<"
m.gar = P">"
```
### Compounds
```lua
m.symbol = m.letter * (m.letter + m.digit + m.hep + m.zap + m.wut)^0

m.hashtag = m.hax * m.symbol
m.handle = m.pat * m.symbol
```
## Lines
  These patterns are used in line detection.  Grimoire is designed such that
the first characters of a line are a reliable guide to the substance of what
is to follow. 


### Tagline
  Taglines begin with hashtags, which are system directives.

```lua
m.tagline_hash_p = #(m.WS * m.hax - (m.hax * m._))
m.tagline_handle_p = #(m.WS * m.pat - (m.pat * m._))
m.tagline_p = m.tagline_hash_p + m.tagline_hash_p
```
### Listline 
  Listlines are blocked into lists, our YAML-inspired arcical data
structure. 

```lua
m.listline_base_p = #(m.WS * m.hep * m._)
m.listline_num_p = #(m.WS * m.digit^1 * m.dot)
m.listline_p = m.listline_base_p + m.listline_num_p
```
### Tableline
  A table, our matrix data structure, is delineated by a =|=.  These
are blocked by whitespace in the familiar way. 

Tables, and lists for that matter, will support leading handles at 
some point.  I'm leaning towards hashtags behaving differently in that
respect.

```lua
m.tableline_p = #(m.WS * m.bar)

m.codestart_p = #(m.WS * m.hax * m.zaps)
m.codefinish_p = #(m.WS * m.hax * m.fass)

m.codestart = m.WS * m.hax * m.zaps * P(1)^1
m.codefinish = m.WS * m.hax * m.fass * P(1)^1

m.header = m.WS * m.tars * m._ * P(1)^1 
```
 The symbol rule will be made less restrictive eventually. 


## Structures
  These will ultimately need to be propertly recursive.  Prose in particular
has the inner markups as a mutual loop that always advances. 

```lua
m.url = m.letter * (m.symbol + m.dot + m.fas + m.col)^0 - m.ser -- This is definitely not right at all

m.prose = (m.symbol + m._)^1 -- Or this
m.link_prose = m.prose - m.ser -- accurate
```
### Links
```lua
m.inner_link = m.sel * m.url * m.ser
m.text_link = m.sel * m.link_prose * m.ser
m.link = m.sel * m.text_link * m.inner_link^-1 * m.ser 
```
```lua
return m
```
