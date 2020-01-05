









local s = require "singletons/status" ()
s.chatty = true
s.verbose = false

local pl_mini = require "orb:util/plmini"
local lfs = require "lfs"
local attributes = lfs.attributes
local isdir, basename  = pl_mini.path.isdir,
                         pl_mini.path.basename
local getfiles, getdirectories = pl_mini.dir.getfiles,
                                 pl_mini.dir.getdirectories
local mkdir = lfs.mkdir

local Path = require "orb:walk/path"
local File = require "orb:walk/file"



local new



local Dir = {}
Dir.isDir = Dir
Dir.it = require "singletons/check"

local __Dirs = {} -- Cache to keep each Dir unique by path name





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





function Dir.basename(dir)
  return basename(dir.path.str)
end





function Dir.getsubdirs(dir)

  local subdir_strs = getdirectories(dir.path.str)
  dir.subdirs = {}
  for i,sub in ipairs(subdir_strs) do
    s:verb(sub)
    dir.subdirs[i] = new(sub)
  end
  return dir.subdirs
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
  dir.attr = attributes(dir.path.str)
  return dir.attr
end










function Dir.getfiles(dir)
  local file_strs = getfiles(dir.path.str)
  s:verb("got files from " .. dir.path.str)
  s:verb("# files: " .. #file_strs)
  table.sort(file_strs)
  s:verb("after sort: " .. #file_strs)
  local files = {}
  for i, file in ipairs(file_strs) do
    s:verb("file: " .. file)
    files[i] = File(file)
  end
  dir.files = files
  s:verb("# of files: " .. #dir.files)
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








local function __eq(a,b)
   local stat_a, stat_b = uv.fs_stat(a.path.str), uv.fs_stat(b.path.str)
   if (not stat_a) or (not stat_b) then
      return false
   end
   return stat_a.ino == stat_b.ino
end




local Dir_M = { __index    = Dir,
              __tostring = __tostring,
              __concat   = __concat,
              __eq       = __eq }

function new(path)
  if __Dirs[tostring(path)] then
    return __Dirs[tostring(path)]
  end
  local dir = setmetatable({}, Dir_M)
  if type(path) == "string" then
    local new_path = Path(path)
    dir.path = new_path
  elseif path.idEst == Path then
    dir.path = path
  else
    assert(false, "bad path constructor provided: " .. type(path))
  end

  __Dirs[tostring(path)] = dir

  return dir
end



Dir.idEst = new
return new
