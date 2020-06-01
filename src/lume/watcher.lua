




















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



local function stop(watcher)
   uv.fs_event_stop(watcher.fse)
end



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



return Watcher
