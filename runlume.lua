core = require "core"
lume = require "orb:lume"
s = require "status:status"
uv = require "luv"
print(uv.loop_alive())
s:chat "hi"



lume(uv.cwd(), "", true):run()
