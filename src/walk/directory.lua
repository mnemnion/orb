












local Dir = {}
Dir.isDir = Dir
Dir.it = require "core/check"

local __Dirs = {} -- Cache to keep each Dir unique by Path



local pl_path = require "pl.path" -- Favor lfs directly
local lfs = require "lfs"
local attributes = lfs.attributes
local Path = require "walk/path"
local isdir  = pl_path.isdir
local mkdir = lfs.mkdir



local new





function Dir.exists(dir)
  return isdir(dir.path.str)
end



function Dir.mkdir(dir)
  if dir:exists() then
    return false, "directory already exists"
  else
    local success, msg, code = mkdir(dir.path.str)
    if success then
      return success
    else
      code = tostring(code)
      s:complain("mkdir failure # " .. code, msg, dir)
      return false, msg
    end
  end
end























function Dir.swapDirFor(dir, nestDir, newNest)
  local dir_str, nest_str = tostring(dir), tostring(nestDir)
  local first, last = string.find(dir_str, nest_str)
  if first == 1 then
    -- swap out
    return new(Path(tostring(newNest) .. string.sub(dir_str, last + 1)))
  else
    return nil, nest_str.. " not found in " .. dir_str
  end
end




function Dir.attributes(dir)
  return attributes(dir.path.str)
end



local function __tostring(dir)
  return dir.path.str
end




function new(path)
  if __Dirs[tostring(path)] then
    return __Dirs[tostring(path)]
  end
  local dir = setmetatable({}, {__index = Dir,
                               __tostring = __tostring})
  local path_str = ""
  if path.isPath then
    assert(path.isDir, "fatal: " .. tostring(path) .. " is not a directory")
    dir.path = path
  else
    local new_path = Path(path)
    assert(new_path.isDir, "fatal: " .. tostring(path) .. " is not a directory")
    dir.path = new_path
  end
  __Dirs[tostring(path)] = dir

  return dir
end



return new
