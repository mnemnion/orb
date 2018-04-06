-- * Status
--
--   This is going to migrate toward the =bridge= process containing a 
-- running bettertools instance.
--
-- In the meantime, here's our collection of state-dependent exception
-- handlers.

local a = require "ansi"

local status = {}

status.chatty = true
status.verbose = false 
status.grumpy = true
status.angry = true

-- ** Status:halt(message)
--
--   This dies in pipeline modes.
--
-- In the fleshed-out Lun/Clu environment, this will pause execution
-- and present as much of a debugger as it can.

function status.halt(statusQuo, message, exitCode)
    local bye = exitCode or 1
    io.write(message.. "\n")
    assert(false)
    os.exit(bye)
end

function status.chat(statusQuo, message)
    if statusQuo.chatty then
        io.write(message .. "\n")
    end
end

function status.verb(statusQuo, message)
    if statusQuo.verbose then
        io.write(message .. "\n")
    end
end


-- Complaints are recoverable problems that still shouldn't happeen.
function status.complain(statusQuo, topic, message)
    if not message then
        message = topic
    else
        topic = a.red(topic)
    end
    if statusQuo.grumpy then
        io.write(topic .. ": " .. message .. "\n")
    end
    if statusQuo.angry then
        os.exit(1)
    end
end

local function call(statusQuo)
    return setmetatable({}, {__index = statusQuo})
end


return setmetatable(status, {__call = call})