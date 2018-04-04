# Spec


  A small test harness to exercise our fresh Node class.

### includes

```lua
local u = require "util"
local m = require "grym/morphemes"

local Grammar = require "node/grammar"
local Node = require "node/node"
local pnf = require "node/define"
local L = require "lpeg"
local P = L.P
local V = L.V
local C = L.C


```
```lua
local Spec = {}
```
## Trivial Grammar

This should succeed under all circumstances.


I'd have to guess what it will return currently. 

```lua
local function epsilon(_ENV)
  START "any"
  any = V"anything" + V"other"
  anything = P(1)
  other = P(1)^1
end 

local function a(_ENV)
  START "A"
  A = P"a" + P"A"
end

local function ab(_ENV)
  START "AB"
  AB = V"B" + V"A"  
  A = P"a" + P"A"
  B = V"bmatch" + (V"A" * V"bmatch")
  bmatch = P"b" + P"B"
end

local function clu_gm(_ENV)
  local WS = P(m._ + m.NL)^0
  START "clu"
  SUPPRESS "form"
  clu = V"form"^1
  form = (V"number" * WS)
       + (V"atom" * WS) 
       + (V"expr" * WS)
  expr = m.pal * WS * V"form"^0 * WS * m.par
  atom = m.symbol
  number = m.number
end
```
## Easy mode

```lua
Spec.trivial = Grammar(epsilon)
Spec.a = Grammar(a)
Spec.clu = Grammar(clu_gm)
```
## With metas

```lua

local metas = {}

local AMt, amt = u.inherit(Node)

local function Anew(A, t, str)
  local a = setmetatable(t, AMt)
  a.id = "A"  
  return a
end

metas["A"] = u.export(amt, Anew)
```
```lua
Spec.ab = Grammar(ab, metas)
```
```lua
return Spec
```
