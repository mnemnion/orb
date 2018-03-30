







local Grammar = require "grammar"
local Node = require "node"
local L = require "elpeg"











local function epsilon(_ENV)
  START = "any"
  any = P(1)^1 
end 
