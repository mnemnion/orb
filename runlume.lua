core = require "core"
lume = require "orb:lume"

uv = require "luv"

lume(uv.cwd()):run()