# Ops


It turns out I've got circular dependencies with some of the methods in the
main ``walk`` module and ``codex`` where we're putting the server.


Let's factor those out into their own thing.

```lua
local a = require "singletons/anterm"
local s = require "singletons/status" ()
local pl_mini = require "orb:util/plmini"
local write = pl_mini.file.write
local delete = pl_mini.file.delete
```
```lua
local function writeOnChange(newest, current, out_file, depth)
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

return writeOnChange
```
