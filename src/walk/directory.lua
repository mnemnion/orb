







local Dir = setmetatable({}, {__index = Dir,
                isDir   = Dir})



function new(Dir, path)
  local dir = setmetatable({}, Dir)
  dir.path = path
  return dir
end



return setmetatable({}, {__call = new, __index = Dir})
