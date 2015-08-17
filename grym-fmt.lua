-- Formatting


grymfmt = {}

-- Algorithm:

-- Open a file, given the handle

-- Iterate through the lines: 

function grymfmt.format(filename)
	local stanzas = {}
	local iter = 1 -- must be a better way
	for line in io.lines(filename) do	
		-- substitute four spaces for tabs
		stanzas[iter] = string.gsub(line, "\t", "    ")
		io.write(stanzas[iter].."\n")
		iter = iter + 1 
	end
end
-- Replace all tabs with four spaces (configurable (much) later)

-- Strip all trailing whitespace

-- Return table of lines

return grymfmt