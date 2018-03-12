-- * Status
--
--   This is going to migrate toward the =bridge= process containing a 
-- running bettertools instance.
--
-- In the meantime, here's our collection of state-dependent exception
-- handlers.

local status = {}


-- ** Status:halt(message)
--
--   This dies in pipeline modes.
--
-- In the fleshed-out Lun/Clu environment, this will pause execution
-- and present as much of a debugger as it can.

function status.halt(statusQuo, message, exitCode)
    local bye = exitCode or 1
    io.write(message.. "\n")
    os.exit(bye)
end


return status