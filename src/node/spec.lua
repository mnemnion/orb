







local Grammar = require "node/grammar"
local Node = require "node/node"
local L = require "node/elpeg"











local function epsilon(_ENV)
  START = "any"
  any = P(1)^1 
end 
