







local Grammar = require "node/grammar"
local Node = require "node/node"
local epnf = require "peg/epnf"
local pnf = require "peg/pnf"
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
Spec.a_ = pnf.define(a)
Spec.ab = Grammar(ab)
Spec.ab_ = pnf.define(ab)




for k, v in pairs(Spec.a_) do
  io.write("k   " .. tostring(k) .. " v " .. tostring(v))
end



return Spec
