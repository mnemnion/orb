-- The Node metatable 

local ast = require "peg/ast-node"
local transform = require "peg/transform"


local meta = {}
meta["__call"] = function ()
  io.write "Cannot call Node without evaluator"
end
meta["__index"] = meta
meta["__tostring"] = ast.tostring
meta["isnode"] = true
meta["root"] = ast.root
meta["range"] = ast.range
meta["copy"] = ast.copy
meta["lift"]  = ast.lift
meta["tokens"] = ast.tokenize
meta["flatten"] = ast.flatten
meta["select"] = ast.__select_node
meta["with"] = ast.__select_with_node
meta["dot"] = transform.dot
meta["dotLabel"] = ast.dotLabel

return meta
