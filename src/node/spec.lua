







local u = require "util"

local Grammar = require "node/grammar"
local Node = require "node/node"
local epnf = require "peg/epnf"
local pnf = require "node/define"
local L = require "lpeg"
local P = L.P
local V = L.V
local C = L.C





local Spec = {}









local function epsilon(_ENV)
  START "any"
  any = C(V"anything" + V"other")
  anything = P(1)
  other = P(1)^1
end 

local function a(_ENV)
  START "A"
  A = C(P"a" + P"A")
end

local function ab(_ENV)
  START "AB"
  AB = V"B" + V"A"  
  A = C(P"a" + P"A")
  B = V"bmatch" + (V"A" * V"bmatch")
  bmatch = P"b" + P"B"
end





Spec.trivial = Grammar(epsilon)
Spec.a = Grammar(a)






local metas = {}

local AMt, amt = u.inherit(Node)

local function Anew(A, t, str)
  local a = setmetatable(t, AMt)
  a.id = "A"
  
  return a
end

metas["A"] = u.export(amt, Anew)



Spec.ab = Grammar(ab, metas)



return Spec
