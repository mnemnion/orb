-- Forest module

-- Provides tools for working with vectors of borrowed Nodes
 
local function forest_tostring(forest)
	local top_phrase = "[ "
	for i,v in ipairs(forest) do 
		top_phrase = top_phrase..v.id.." "
	end
	top_phrase = top_phrase.."]\n"
	local node_phrase = ""
	for i,v in ipairs(forest) do
		node_phrase = node_phrase..tostring(v)
	end
	return top_phrase..node_phrase
end

local function F ()
-- <Forest> metatable
	local meta = {}
	meta["__index"] = meta
	meta["__tostring"] = forest_tostring
  	meta["isforest"] = true
  	--the below are added to F in ast.lua 
  	--meta["select"] = ast.forest.select
  	--meta["with"]   = ast.forest.select_with
  	--meta["pick"]   = ast.forest.pick
	return meta
end

local F = F()

return F