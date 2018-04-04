







local s = require "status"
local dot = require "node/dot"










local N = {}
N.__index = N
N.isNode = true














N.line_first = -1
N.line_last  = -1
















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
  if node.__VALUE then
    return node.__VALUE
  end
  if node.str then
    return node.str:sub(node.first,node.last)
  else
    s:halt("no str on node " .. node.id)
  end
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







function N.walk(node)
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











function N.select(node, pred)
   local function qualifies(node, pred)
      if type(pred) == 'string' then
         if type(node) == 'table' 
          and node.id and node.id == pred then
            return true
         else
            return false
         end
      elseif type(pred) == 'function' then
         return pred(node)
      else
         s:halt("cannot select on predicate of type " .. type(pred))
      end
   end

   local function traverse(ast)
      -- depth first
      if qualifies(ast, pred) then
         coroutine.yield(ast)
      end
      if ast.isNode then
         for _, v in ipairs(ast) do
            traverse(v)
         end
      end
   end

   return coroutine.wrap(function() traverse(node) end)
end








function N.tokens(node)
  local function traverse(ast)
    for node in N.walk(ast) do
      if not node[1] then
        coroutine.yield(node:toValue())
      end
    end
  end

  return coroutine.wrap(function() traverse(node) end)
end  










function N.gather(node, pred)
  local gathered = {}
  for ast in N.select(node, pred) do
    gathered[#gathered + 1] = ast
  end
  
  return gathered
end




























































































return N
