--- Transform Module
-- @module transform
--

-- this module is begging for a nice tight macro.

local pretty = require "pl.pretty"

local t = {}

local debug = true

local function bug(value) 
	if debug then
		if type(value) == "table" then
			print(pretty.write(value))
		else
			print(tostring(value))
		end
	end
end

local dot_header = [=[
digraph hierarchy {

nodesep=1.0 // increases the separation between nodes

node [color=Red,fontname=Courier]
edge [color=Blue, style=dashed] //setup options

]=]

local dot_footer = [=[

}
]=]

local function name_to_label(name, leaf_count)
	-- nodes need unique names, so we append a leaf_count and increment it
	local label= name .. "_" .. leaf_count 
	local label_line = label .. " [label=\""
		.. name .. "\"]"
	return label, label_line, leaf_count + 1
end

local function list_from_table(tab)
	local table_list = ""
	for _,v in ipairs(tab) do
		table_list = table_list.." "..v
	end
	return table_list
end

-- Recursively walk an AST, concatenating dot descriptions
-- to the phrase. 
local function dot_ranks(ast, phrase, leaf_count)
	local leaf_count = leaf_count or 0
	-- add the node we're working on
	if ast.isnode then
		local label = ""
		local label_line = ""
		local child_labels = {}
		local child_label_lines = {}
		label, label_line, leaf_count = name_to_label(ast.id, leaf_count)
		phrase = phrase .. label_line .. "\n"
		for i,v in ipairs(ast) do
			-- assemble labels and label lines for all child nodes
			if v.isnode then
				bug (v.id)
				child_labels[i], child_label_lines[i], leaf_count = 
					name_to_label(v.id, leaf_count)
			end
		end
		local child_list = list_from_table(child_labels)
		phrase = phrase..label.." -> {"..child_list.."}\n"
		phrase = phrase.."{rank=same;"..list_from_table(child_labels).."}\n"
		for _, v in ipairs(child_label_lines) do
			phrase = phrase..v.."\n"
		end
	else
		-- leaf node
	end
	return phrase
end

-- turn an AST into a dotfile string. 
function t.dot(ast)
	local phrase = dot_header
	
	return  dot_ranks(ast, phrase) .. dot_footer
end

return t
