











local uv = require "luv"
local Watcher = require "femto/watcher"

local Server = {}
Server.__index = Server


function Server.serve(server, pwd)
   print ("serving " .. pwd)
end

local function onchange(server, fname)
   if type(fname) == 'string' then
      print ("Changed " .. fname)
   end
end


function Server.start(server)
   server(server.dir)
   uv.run("default")
end


function Server.stop(server)
   server:stop()
   uv.stop()
end

local function new(dir)
   local serve = Watcher {onchange = onchange}
   return serve
end

return new
