--- Transform Module
-- @module transform
--

-- this module is begging for a nice tight macro.


local sort = require "peg/rule-sort"

local roshambo = require "roshambo"

local t = {}

function t.whitespace(ast)
	local whites = ast:select"atom":with"ws"
	for i = 1, #whites do
		whites[i].val = "WS"
		whites[i][1] = nil
	end
end

function t.isrecursive(node)
	if node.isrecursive then
		return true
	else
		return false
	end
end

function t.notrecursive(node)
	if node.id == "rule" and not node.isrecursive then
		return true
	else
		return false
	end
end

function t.cursives(ast)
--	local cursors = ast:root().cursors
--	print (cursors)
	local atoms = ast:select"atom"
	--if cursors then
		for i = 1, #atoms do
		--	if cursors[atoms[i].val] then 
--				print ("Transforming: ", atoms[i].val)
				atoms[i].val = 'V"'..atoms[i].val..'"'
		--	end
		end
	--end
end

function t.optional(ast)
	local optionals = ast:select"optional":select"atom"
	for i = 1, #optionals do
		--print(optionals[i].val)
		optionals[i].val = optionals[i].val.."^0"
	end
end

function t.more_than_one(ast)
	local mto = ast:select"more_than_one":select"atom"
	for i = 1, #mto do
		mto[i].val = mto[i].val.."^1"
	end
end

function t.maybe(ast)
	local maybe = ast:select"maybe":select"atom"
	for i = 1, #maybe do
		maybe[i].val = maybe[i].val.."^-1"
	end
end

function t.some_number(ast)
	-- moderately complex, write later
end

function t.suffix(ast)
	t.optional(ast)
	t.more_than_one(ast)
	t.maybe(ast)
	t.some_number(ast)
	--t.with_suffix(ast)
end

function t.if_not_this(ast)
	local atoms = ast:select"if_not_this":select"atom"
	for i = 1, #atoms do
		atoms[i].val = "-"..atoms[i].val
	end
end

function t.if_and_this(ast)
		local atoms = ast:select"if_and_this":select"atom"
	for i = 1, #atoms do
		atoms[i].val = "#"..atoms[i].val
	end
end 

function t.prefix(ast)
	t.if_not_this(ast)
	t.if_and_this(ast)
end

function t.literal(ast)
	local lits = ast:select"literal"
	for i = 1, #lits do
		lits[i].val = 'Csp'..lits[i].val
	end 
end 

function t.hidden_literal(ast)
	local lits = ast:select"hidden_literal"
	for i = 1, #lits do
		lits[i].val = 'P"'..lits[i].val:gsub('"','\\"'):gsub("\\`","`")..'"'
	end 
end  

function t.range(ast)
	local ranges = ast:select"range"
	for i = 1, #ranges do
		ranges[i].val = 'R"'..ranges[i].val:gsub("-","")..'"'
	end
end

function t.set(ast)
	local sets = ast:select"set"
	for i = 1, #sets do
		sets[i].val = 'S"'..sets[i].val..'"'
	end
end

function t.enclosed(ast)
	t.literal(ast)
	t.hidden_literal(ast)
	t.range(ast)
	t.set(ast)
end

function t.cat(ast)
	local gatos = ast:select"cat"
	for i = 1, #gatos do
		gatos[i].val = " * "
	end
end

function t.choice(ast)
	local choices = ast:select"choice"
	for i= 1, #choices do
		choices[i].val = " + "
	end
end

local function lhs_pred(node)
	if node.id == "pattern" and node.val then
		return true
	elseif node.id == "hidden_pattern" then
		return true
	else 
		return false
	end 	
end 


function t.lhs(ast)
	local lhs = ast:select(lhs_pred)
	local imports = ""
	lhs[1]:root().start_rule = "  START "..'"'..lhs[1].val..'"\n'
	local nocurse = ast:select(t.notrecursive):select(lhs_pred)
	for i = 1, #lhs do
		lhs[i].val = lhs[i].val.." =  "
	end
	lhs[1]:root().imports = imports.."\n"
end

function t.rhs(ast)
	local rhs = ast:select"rhs"
	for i = 1, #rhs do
		rhs[i]:tokens()
		rhs[i].tok[#rhs[i].tok+1] = "\n"
	end
end

function t.comment(ast)
	local commentary = ast:select"comment"
	for i = 1, #commentary do
		-- remove superfluous cat
		commentary[i].parent().id = "comment"
		commentary[i].parent().val = "  -- "..commentary[i].val
		commentary[i].parent()[1] = nil 
	end 
end

function t.capture_group(ast)
	local pels = ast:select"capture_group":select"PEL"
	for i = 1, #pels do
		pels[i].val = "C("
	end 
end



---Transforms rules into LPEG form. 
-- @param ast root Node of a PEGylated grammar. 
-- @return a collection containing the transformed strings.
function t.transform(ast)
    t.whitespace(ast) -- currently required to fix ast :(
	sort.sort(ast)
	t.cursives(ast)
	t.comment(ast)
	t.prefix(ast)
	t.suffix(ast)
	t.enclosed(ast)
	t.capture_group(ast)
	t.cat(ast)
	t.choice(ast)
	t.lhs(ast)
	t.rhs(ast)
	return ast
end

return t
