

--AST tools
local lpeg = require "lpeg"
--local clu = require "clu/prelude"

local u = require "lib/util"

local ansi = require "ansi"
local walker = require "peg/walker"
local Forest = require "peg/forest"
local cyan = tostring(ansi.cyan)
local blue = tostring(ansi.blue)
local magenta = tostring(ansi.magenta)
local clear = tostring(ansi.clear)
local green = tostring(ansi.green)
local red = tostring(ansi.red)
local grey = tostring(ansi.dim)..tostring(ansi.white)




local function ast_range(node)
   local root = node:root()
   local first, last, _ =  root.index(node)
   return root.index, first, last
end





local function _ast_range(node)
   local root = node:root()
   return root.index, node.first, node.last
end

local c = { id = magenta,
         range = grey,
         str = red,
         num = blue,
         span = clear,
         val = green,}

local function node_pr(node, depth, str)
   if node.isnode then
      local phrase = ""
      local prefix = ("  "):rep(depth)
      if node.isrecursive then 
         phrase = red.."*"..prefix:sub(1,-2)..clear
      else 
         phrase = prefix
      end
      if node.last then 
         phrase = phrase..
         c.id..node.id.." "..
         c.range..node.first..
         "-"..c.range..node.last..clear.."\n"
      end
      if node.val then
          phrase = phrase..prefix..'"'..c.val..node.val..clear..'"'.."\n"
      end 
      return phrase
   end
end


local function ast_tostring(ast, depth, og, phrase)
   local depth = depth or 0
   local og = og or ast.str
   local phrase = phrase or ""
   if ast.isnode then
      phrase = phrase..node_pr(ast,depth,og)
   end
   for i,v in ipairs(ast) do
      phrase = ast_tostring(v,depth+1,og,phrase)
   end
   return phrase
end


local function ast_pr(ast)
   io.write(ast_tostring(ast))
end

local function deepcopy(orig) -- from luafun
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' and orig.isnode then
        copy = setmetatable({},getmetatable(orig))
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
    elseif orig_type ~= "function" then
            copy = orig
    end
    return copy
end

local function ast_copy(ast)
   local clone = deepcopy(ast)
   return walker.walk_ast(clone)
end

local forest = {}

local function select_node (ast, pred, catcher)
   local catch = catcher or {}
   catch = setmetatable(catch,Forest)
   if type(pred) == "string" then
      if ast.id == pred then 
         catch[#catch+1] = ast
      end
      for _,v in ipairs(ast) do
         catch = select_node(v, pred, catch)
      end
   elseif type(pred) == "function" then
      if pred(ast) then
         catch[#catch+1] = ast
      end
      for _,v in ipairse(ast) do
         catch = select_node(v, pred, catch)
      end
   end
   return catch   
end

function forest.select(grove,id)
   local catch = setmetatable({},Forest)
   for i = 1, #grove do
      local nursery = select_node(grove[i],id)
      for j = 1, #nursery do
         catch[#catch+1] = nursery[1]
      end
   end
   return catch 
end

local function select_rule(ast,id)
   local catch = {}
   if type(ast) == "table" and ast.isnode then
      catch = select_node(ast,id)
   elseif type(ast) == "table" and ast.isforest then
      catch = forest.select(ast,id)
   else error "select: First argument must be of type Node or Forest" end
   return catch
end

local function select_with_node(ast,pred)
   local catch = setmetatable({},Forest)
   local ndx, first, last = ast:range()
   if type(pred) == "string" then
      for i = first, last do
         if ndx[i].id == pred then
            catch[#catch+1] = ndx[first]
         end
      end
   elseif type(pred) == "function" then
      for i = first, last do
         if pred(ndx[i]) then
            catch[#catch+1] = ndx[first]
         end
      end
   end
   return catch
end

function forest.select_with (ast,id)
   local catch = setmetatable({},Forest)
   for i = 1, #ast do
      local nursery = select_with_node(ast[i],id)
      for j = 1, #nursery do
         catch[#catch+1] = nursery[1]
      end
   end
   return catch
end 

local function select_with(ast,id)
   local catch = {}
   if type(ast) == "table" and ast.isnode then
      catch = select_with_node(ast,id)
   elseif type(ast) == "table" and ast.isforest then
      catch = forest.select_with(ast,id)
   else
      error "with: First argument must be of type Node or Forest" 
   end
   return catch
end





local function pick_tostring(table)
   local phrase = ""
   for i,v in ipairs(table) do 
      phrase = phrase..tostring(v)
   end
   return phrase 
end

local function toks_tostring(table)
   local phrase = "["
   for i,v in ipairs(table) do
      phrase = phrase..
                grey.."'"..clear..
                tostring(v):gsub("\n",blue.."\\n"..clear)..
                grey.."'"..red..","..clear
   end
   return phrase.."]".."\n"
end

local function tokenize(ast)
   if ast.tok then return ast.tok end
   local ndx, first, last = ast:range()
   local tokens = setmetatable({},{__tostring = toks_tostring})
   for i = first, last do    -- reap leaves
      if ndx[i].val then
         tokens[#tokens+1] = ndx[i].val
         ndx[i].val = nil
      elseif ndx[i].tok then
         for j = 1, #ndx[i].tok do
            tokens[#tokens+1] = ndx[i].tok[j]
         end
         ndx[i].tok = nil
      end
   end
   for i,v in ipairs(ast) do -- destroy children
      ast[i] = nil 
   end
   ast.tok = tokens
   walker.walk_ast(ast:root()) -- this should be triggered by 
                        -- next index operation
   return tokens
end

local function flatten(ast)
   local phrase = ""
   ast:tokens()
   if ast.tok then
      for i = 1, #ast.tok do
         phrase = phrase..ast.tok[i]
      end
   else error "auto-tokenizing has failed"
   end
   ast.flat = phrase
   return phrase
end

function forest.pick(ast,id)






   local catch = setmetatable({},{["__tostring"] = pick_tostring})
   for i = 1, #ast do
      catch[#catch+1] = select_node(ast[i],id)
   end
   return catch 
end

local function walk(ast)
end

Forest["select"] = select_rule
Forest["with"]   = forest.select_with
Forest["pick"]   = forest.pick

--- Parses a string with a given grammar,






local function parse(grammar, str)
   if grammar == nil then
      error "grammar failed to generate"
   end
   -- grammar, input, starting point, input for Carg(1), root node Carg(2)
   local root = {} -- closed under parse
   local root_fn = function()
                        local root_node = root -- closed under root fn 
                        return root_node
                   end
   local ast = lpeg.match(grammar, str, 1, str, root_fn)
   if type(ast) == "table" then
      for k, v in pairs(ast) do
         root[k] = v
      end   
      root.str = str
      root.grammar = grammar
      setmetatable(root,getmetatable(ast))
      return walker.walk_ast(root)
   else
      error "lpeg did not match grammar"
   end
end








local function dotLabel(ast)
   return ast.id
end

local function toMarkdown(ast)
   u.freeze("No toMarkdown method for " .. ast.id)
end

return {
   select = select_rule,
   __select_with_node = select_with_node,
   __select_node = select_node, 
   with = select_with ,
   tostring = ast_tostring,
   pr = ast_pr,
   lift = walker.lift,
   --root = root,
   tokenize = tokenize,
   flatten = flatten,
   range= ast_range,
   copy = ast_copy,
   walk = walker.walk_ast,
   dotLabel = dotLabel,
   toMarkdown = toMarkdown,
   parse = parse
}
