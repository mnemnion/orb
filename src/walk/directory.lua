












local pl_path = require "pl.path"
local pl_dir  = require "pl.dir"
local pl_file = require "pl.file"
local lfs = require "lfs"
local attributes = lfs.attributes
local isdir  = pl_path.isdir
local getfiles = pl_dir.getfiles
local mkdir = lfs.mkdir

local Path = require "walk/path"
local File = require "walk/file"



local new



local Dir = {}
Dir.isDir = Dir
Dir.it = require "core/check"

local __Dirs = {} -- Cache to keep each Dir unique by Path





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





function Dir.parentDir(dir)
  return new(dir.path:parentDir())
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



function Dir.getfiles(dir)
  local files = getfiles(dir.path.str)
  table.sort(files)
  for i, f in ipairs(files) do
    files[i] = File(f)
  end

  return files
end




local function __tostring(dir)
  return dir.path.str
end



local function __concat(dir, path)
    if type(dir) == "string" then
        return new(dir .. path)
    end
    return new(dir.path.str .. tostring(path))
end




function new(path)
  if __Dirs[tostring(path)] then
    return __Dirs[tostring(path)]
  end
  local dir = setmetatable({}, {__index = Dir,
                               __tostring = __tostring,
                               __concat   = __concat})
  if type(path) == "string" then
    local new_path = Path(path)
    dir.path = new_path
  elseif path.idEst == Path then
    dir.path = path
  else
    assert(false, "bad path constructor provided")
  end

  __Dirs[tostring(path)] = dir

  return dir
end



Dir.idEst = new
return new
