--- Transform Module
-- @module transform
--
--
-- #TODO: 
--
--  - [ ] Make header and footer configurable values of t
--  - [ ] Make leaf_font and leaf_color configurable values of t

local t = {}

local dot_header = [=[
digraph hierarchy {

node [fontname=Helvetica]
edge [style=dashed]

]=]

local dot_footer = [=[

}
]=]

local leaf_font  = "Inconsolata"
local leaf_color = "Gray"

local function ast_to_label(ast, leaf_count)
	-- nodes need unique names, so we append a leaf_count and increment it
	local label      = ast.id.. "_" .. leaf_count 
	local label_line = label .. " [label=\""
		.. ast:dotLabel():gsub('"', '\\"') .. "\"]"
	return label, label_line, leaf_count + 1
end

local function list_from_table(tab)
	local table_list = ""
	for _,v in ipairs(tab) do
		table_list = table_list.." "..v
	end
	return table_list
end

local function value_to_label(value, leaf_count)
	-- Generates a name and label for a leaf node.
	-- Returns these with an incremented leaf_count.
	local value = value:gsub('"', '\\"')
	local name  = "leaf_"..leaf_count
	local label = " [color="..leaf_color..",shape=rectangle,fontname="
			..leaf_font..",label=\""..value.."\"]"
			
	return name, label, leaf_count + 1
end

-- Recursively walk an AST, concatenating dot descriptions
-- to the phrase. 
local function dot_ranks(ast, phrase, leaf_count, ast_label)
	local leaf_count = leaf_count or 0

	-- Add the node we're working on
	if ast.isnode then
		local label = ""
		local label_line = ""
		local child_labels = {}
		local child_label_lines = {}

		-- Handle anonymous nodes
		if not ast_label then
			label, label_line, leaf_count = ast_to_label(ast, leaf_count)
			phrase = phrase .. label_line .. "\n\n"
		else 
			label = ast_label 
		end

		-- Document child nodes
		for i,v in ipairs(ast) do
			-- assemble labels and label lines for all child nodes
			if v.isnode then
				child_labels[i], child_label_lines[i], leaf_count = 
					ast_to_label(v, leaf_count)
			end
		end

		local child_list = list_from_table(child_labels)

		if next(child_labels) ~= nil then
			phrase = phrase..label.." -> {"..child_list.."}\n"
			phrase = phrase.."{rank=same;"..list_from_table(child_labels).."}\n\n"
		end

		-- Concatenate child label lines
		for _, v in ipairs(child_label_lines) do
			phrase = phrase..v.."\n"
		end

		if next(child_labels) ~= nil then
			phrase = phrase.."\n"
		end

		-- Execute recursively for all nodes
		for i,v in ipairs(ast) do
			if v.isnode then
				phrase, leaf_count = dot_ranks(v, phrase, leaf_count, child_labels[i])
			end
		end

		-- Document value of Node (aka span)
		if ast.val then
			local name = "" ; local val_label = ""
			name, val_label, leaf_count = value_to_label(ast.val, leaf_count)
			phrase = phrase.."\n"..label.." -> "..name.."\n"
			phrase = phrase..name.." "..val_label
		end
	end

	return phrase, leaf_count
end

-- turn an AST into a dotfile string. 
function t.dot(ast)
	local phrase = dot_header
	
	return  dot_ranks(ast, phrase) .. dot_footer
end

return t
