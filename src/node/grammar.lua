



local L = require "lpeg"

local s = require "status" 
local define = require "node/define"
local Root = require "node/root"






local function new(grammar_template, metas)
  if type(grammar_template) == 'function' then
    local metas = metas or {isMetas = true}
    local grammar = define.define(grammar_template, nil, metas)
    local parse = function(str)
      local root = Root(str)
      return L.match(grammar, str, 1, root, metas) -- other 
    end
    return parse
  else
    s:halt("no way to build grammar out of " .. type(template))
  end
end



return new
