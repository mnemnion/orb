








local a = require "lib/ansi"
local s = require "status"
local pl_file = require "pl.file"
local write = pl_file.write
local delete = pl_file.delete



local ops = {}

function ops.writeOnChange(newest, current, out_file, depth)
    -- If the text has changed, write it
    depth = depth or 1
    if newest ~= current then
        s:chat(a.green(("  "):rep(depth) .. "  - " .. out_file))
        write(out_file, newest)
        return true
    -- If the new text is blank, delete the old file
    elseif current ~= "" and newest == "" then
        s:chat(a.red(("  "):rep(depth) .. "  - " .. out_file))
        delete(out_file)
        return false
    else
    -- Otherwise do nothing

        return nil
    end
end

return ops
