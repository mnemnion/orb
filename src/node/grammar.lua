



local L = require "lpeg"

local s = require "status" 
local define = require "node/define"
local Node = require "node/node"



local function refineMetas(metas)
  for _,v in pairs(metas) do
    if not v["__tostring"] then
      v["__tostring"] = Node.toString
    end
  end
  return metas
end




local function new(grammar_template, metas)
  if type(grammar_template) == 'function' then
    local metas = metas or {}
    local grammar = define.define(grammar_template, nil, metas)
    local parse = function(str)
      return L.match(grammar, str, 1, str, metas) -- other 
    end
    return parse
  else
    s:halt("no way to build grammar out of " .. type(template))
  end
end



return new
