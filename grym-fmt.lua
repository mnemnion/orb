-- Formatting


grymfmt = {}

-- Algorithm:

-- Open a file, given the handle

-- Iterate through the lines: 

function grymfmt.format(filename)
	for line in io.lines(filename) do
		-- simple print test
		io.write(line.."\n")
	end
end
-- Replace all tabs with four spaces (configurable (much) later)

-- Strip all trailing whitespace

-- Return table of lines

return grymfmt