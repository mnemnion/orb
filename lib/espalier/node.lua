









local s = require "status" ()
local a = require "ansi"
local dot = require "espalier/dot"









local Node = {}
Node.__index = Node
Node.isNode = Node


























function Node.toLua(node)
  s:halt("No toLua method for " .. node.id)
end











function Node.toString(node, depth)
   local depth = depth or 0
   local phrase = ""
   phrase = ("  "):rep(depth) .. a.bright(node.id) .. "    "
      .. a.cyan(node.first) .. "-" .. a.cyan(node.last)
   if node[1] then
      local extra = "    "
      if Node.len(node) > 56 then
         --  Truncate in the middle
         local span = Node.span(node)
         local pre, post = string.sub(span, 1, 26), string.sub(span, -26, -1)
         extra = extra .. a.dim(pre) .. a.bright("………") .. a.dim(post)
         extra = extra:gsub("\n", "◼︎")
      else
         extra = extra .. a.dim(Node.span(node):gsub("\n", "◼︎"))
      end
      phrase = phrase .. extra .. "\n"
      for _,v in ipairs(node) do
         if (v.isNode) then
            phrase = phrase .. Node.toString(v, depth + 1)
         end
      end
   else
      local val = node.str:sub(node.first, node.last)
                          :gsub(" ", a.clear() .. a.dim("_") .. a.green())
      val = a.green(val)
      phrase = phrase .. "    " .. val  .. "\n"
   end
   return phrase
end








function Node.span(node)
   return string.sub(node.str, node.first, node.last)
end








function Node.len(node)
    return 1 + node.last - node.first
end



























function Node.gap(left, right)
  assert(left.last, "no left.last")
  assert(right.first, "no right.first")
  assert(right.last, "no right.last")
  assert(left.first, "no left.first")
  if left.first >= right.last then
    local left, right = right, left
  elseif left.last > right.first then
    s:halt("overlapping regions or str issue")
  end
  local gap = left
  if gap >= 0 then
    return gap
  else
    s:halt("some kind of situation where gap is " .. tostring(gap))
  end

  return nil
end




function Node.dotLabel(node)
  return node.id
end

function Node.toMarkdown(node)
  if not node[1] then
    return string.sub(node.str, node.first, node.last)
  else
    s:halt("no toMarkdown for " .. node.id)
  end
end

function Node.dot(node)
  return dot.dot(node)
end

function Node.toValue(node)
  if node.__VALUE then
    return node.__VALUE
  end
  if node.str then
    return node.str:sub(node.first,node.last)
  else
    s:halt("no str on node " .. node.id)
  end
end








function Node.walkPost(node)
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







function Node.walk(node)
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











function Node.select(node, pred)
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
      -- breadth first
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








function Node.tokens(node)
  local function traverse(ast)
    for node in Node.walk(ast) do
      if not node[1] then
        coroutine.yield(node:toValue())
      end
    end
  end

  return coroutine.wrap(function() traverse(node) end)
end














function Node.lines(node)
  local function yieldLines(node, linum)
     for _, str in ipairs(node.__lines) do
        coroutine.yield(str)
      end
  end

  if node.__lines then
     return coroutine.wrap(function ()
                              yieldLines(node)
                           end)
  else
     node.__lines = {}
  end

  local function buildLines(str)
      if str == nil then
        return nil
      end
      local rest = ""
      local first, last = string.find(str, "\n")
      if first == nil then
        return nil
      else
        local line = string.sub(str, 1, first - 1) -- no newline
        rest       = string.sub(str, last + 1)    -- skip newline
        node.__lines[#node.__lines + 1] = line
        coroutine.yield(line)
      end
      buildLines(rest)
  end

  return coroutine.wrap(function ()
                           buildLines(node.str)
                        end)
end



















function Node.linePos(node, position)
   if not node.__lines then
      for _ in node:lines() do
        -- nothing, this generates the line map
      end
   end
   local offset = 0
   local position = position
   local linum = nil
   for i, v in ipairs(node.__lines) do
       linum = i
       local len = #v + 1 -- for nl
       local offset = offset + len
       if offset > position then
          return linum, position
       elseif offset == position then
          return linum, len
       else
          position = position - #v - 1
       end
   end
   return nil -- this position is off the end of the string
end










function Node.lastLeaf(node)
  if #node == 0 then
    return node
  else
    return Node.lastLeaf(node[#node])
  end
end











function Node.gather(node, pred)
  local gathered = {}
  for ast in node:select(pred) do
    gathered[#gathered + 1] = ast
  end

  return gathered
end











function Node.isValid(node)
  assert(node.isNode == Node, "isNode flag must be Node metatable, id: "
         .. node.id .. " " .. tostring(node))
  assert(node.first, "node must have first")
  assert(type(node.first) == "number", "node.first must be of type number")
  assert(node.last, "node must have last")
  assert(type(node.last) == "number", "node.last must be of type number")
  assert(node.str, "node must have str")
  assert(type(node.str) == "string" or node.str.isPhrase, "str must be string or phrase")
  assert(node.parent, "node must have parent")
  assert(type(node:span()) == "string", "span() must yield string")
  return true
end

function Node.validate(node)
  for twig in node:walk() do
    twig:isValid()
  end
  return true
end









function Node.inherit(node)
  local Meta = setmetatable({}, node)
  Meta.__index = Meta
  local meta = setmetatable({}, Meta)
  meta.__index = meta
  return Meta, meta
end

function Node.export(_, mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
end





























return Node
