


















local t = {}

local dot_header = [=[
digraph lpegNode {

node [fontname=Helvetica]
edge [style=dashed]

]=]

local dot_footer = [=[

}
]=]

local leaf_font  = "Inconsolata"
local leaf_color = "Gray"

local function sanitize_string(str)
   -- filter \ and "
   local phrase = str:gsub("\\", "\\\\"):gsub('"', '\\"')
   if phrase:sub(-1,-1) == "\n" then
      return phrase:sub(1, -2)
   else
      return phrase
   end
end

local function ast_to_label(ast, leaf_count)
   -- nodes need unique names, so we append a leaf_count and increment it
   local label      = ast.id.. "_" .. leaf_count 
   local label_line = label .. " [label=\""
      .. sanitize_string(ast:dotLabel()) .. "\"]\n"
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
   local value = sanitize_string(value)
   local name  = "leaf_"..leaf_count
   local label = " [color="..leaf_color..",shape=rectangle,fontname="
         ..leaf_font..",label=\""..value.."\"]\n"

   return name, label, leaf_count + 1
end









local function dot_ranks(ast, phrase, leaf_count, ast_label)
   local leaf_count = leaf_count or 0

   -- Add the node we're working on
   if ast.isNode then
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
         if v.isNode then
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

      local leaf_val = nil

      if ast.val then
         leaf_val = ast.val
      elseif ast.toValue then
         leaf_val = ast:toValue()
      end

      -- Document value of leaf nodes
      if (not ast[1]) and leaf_val then
         local name = "" ; local val_label = ""
         name, val_label, leaf_count = value_to_label(leaf_val, leaf_count)
         phrase = phrase..label.." -> "..name.."\n"
         phrase = phrase..name.." "..val_label
      end

      local separator = "// END RANK " .. label .. "\n\n"
      phrase = phrase .. separator

      -- Execute recursively for all nodes
      for i, v in ipairs(ast) do
         if v.isNode  then
            phrase, leaf_count = dot_ranks(v, phrase, leaf_count, child_labels[i])
         end
      end
   end

   return phrase, leaf_count
end





function t.dot(ast)
   local phrase = dot_header

   return  dot_ranks(ast, phrase) .. dot_footer
end

return t
