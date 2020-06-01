# Watcher


Actual, re-entrant event response is inherently similar to callbacks.


First-class continuations are arguably the best way to model this.


Registered callbacks are a) usable from stock LuaJIT and b) more dynamic than
continuations.  If you want that dynamicism with continuations, you can of
course have it, but you still have to write it.


Since we do want to be able to update handlers, we don't need the extra layer.


To set up a watcher, register ``watcher:onchange(fname)`` and/or
``watcher:onrename(fname)``.  That's ``function onchange(watcher,fname)``!


This can be done on creation, after creation, or after setting the watch.


To stop watching, call ``watcher:stop()``.

```lua
local uv = require "luv"

local function watch(watcher, dir, recur)
    watcher.dir = dir
    -- default to a recursive watch
    if recur == nil then
        recur = true
    end
    local fse = uv.new_fs_event()
    watcher.fse = fse
    uv.fs_event_start(fse, dir,{recursive = recur},function (err,fname,status)
        if(err) then
            print("Error "..err)
        else
            local ev = nil
            for k,v in pairs(status) do
                ev = k
            end
            if ev == "change" then
               watcher:onchange(fname)
            elseif ev == "rename" then
               watcher:onrename(fname)
            else
               print("Unrecognized event in watch(" .. dir .. "): " ..ev)
            end
        end
    end)
end
```
```lua
local function stop(watcher)
   uv.fs_event_stop(watcher.fse)
end
```
```lua
local _W = {__call = watch}
_W.__index = _W

function _W.run(watcher)
   uv.run()
end

local function Watcher(handlers)
   handlers = handlers or {}
   local watcher = {}
   watcher.onchange = handlers.onchange or function() end
   watcher.onrename = handlers.onrename or function() end
   watcher.stop = stop
   return setmetatable(watcher, _W)
end

_W.idEst = _W
```
```lua
return Watcher
```
