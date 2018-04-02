







local s = require "status"
local dot = require "node/dot"










local N = {}
N.__index = N
N.isNode = true















function N.toString(node, depth)
   local depth = depth or 0
   local phrase = ""
   phrase = ("  "):rep(depth) .. "id: " .. node.id .. ",  "
      .. "first: " .. node.first .. ", last: " .. node.last .. "\n"
   if node[1] then
    for _,v in ipairs(node) do
      if(v.isNode) then
        phrase = phrase .. N.toString(v, depth + 1)
      end
    end
  end 
   return phrase
end



function N.dotLabel(node)
  return node.id
end

function N.toMarkdown(node)
  if not node[1] then
    return string.sub(node.str, node.first, node.last)
  else
    s:halt("no toMarkdown for " .. node.id)
  end
end

function N.dot(node)
  return dot.dot(node)
end

function N.toValue(node)
  if not node.val then
    node.val = node.str:sub(node.first,node.last)
  end
  return node.val
end






function N.walkDeep(node)
    local function traverse(ast)
        if not ast.isNode then return nil end

        for _, v in ipairs(ast) do
            if type(v) == 'table' and v.isNode then
              traverse(v)
            end
        end
        coroutine.yield(ast)
    end

    return coroutine.wrap(function() traverse(node) end)
end





function N.walkBroad(node)
  local function traverse(ast)
    if not ast.isNode then return nil end
    coroutine.yield(ast)
    for _, v in ipairs(ast) do
      if type(v) == 'table' and v.isNode then
        traverse(v)
      end
    end
  end

  return coroutine.wrap(function() traverse(node) end)
end





























































































return N
