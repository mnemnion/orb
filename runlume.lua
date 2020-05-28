core = require "core"
lume = require "orb:lume"
s = require "status:status"
print(s.print)
s:chat "hi"

uv = require "luv"

lume(uv.cwd(), ""):run()