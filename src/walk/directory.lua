









local uv = require "luv"
local s = require "singletons/status" ()
s.chatty = true
s.verbose = false

local pl_mini = require "orb:util/plmini"
local sh = require "orb:util/sh"
local lfs = require "lfs"
local attributes = lfs.attributes
local basename  = pl_mini.path.basename
local getdirectories = pl_mini.dir.getdirectories

local Path = require "orb:walk/path"
local File = require "orb:walk/file"



local new



local Dir = {}
Dir.isDir = Dir
Dir.it = require "singletons/check"

-- Cache to keep each Dir unique by path name
local __Dirs = setmetatable({}, {__mode = "v"})






function Dir.exists(dir)
  local stat = uv.fs_stat(tostring(dir.path))
  if stat and stat.type == "directory" then
    return true
  elseif stat and stat.type ~= "directory" then
    return false, tostring(dir.path) .. " is a " .. stat.type
  else
    return false
  end
end















local function mkdir(dir, mode)
  if mode then
     if type(mode) == 'string' then
       mode = tonumber(mode, 8)
    elseif type(mode) ~= 'number' then
      error("bad argument #1 to mkdir method: expected string or number"
           .. "got " ..type(mode))
    end
  else
    mode = 416 -- drwxr-----
  end

  local exists, msg = dir:exists()
  if exists or msg then
    return false, msg or "directory already exists"
  else
    -- There is no good way to do recursive mkdir with primitives.
     -- the filesystem will happily open, stat, etc. from memory, without
     -- writing to disk; unless the directory actually exists on disk, mkdir
     -- for the subdirectory will fail.
     --
     -- So, we shell out.
     local parent = new(dir.path:parentDir())
      if parent and (not parent:exists()) then
        return sh.mkdir("-p", "'" .. dir.path.str:gsub("'", "'\\''") .. "'")
    else
      local success, msg, code = uv.fs_mkdir(dir.path.str, mode)
      if success then
        return success
      else
        code = tostring(code)
        s:complain("mkdir failure # " .. code, msg, dir)
        return false, msg
      end
    end
  end
end

Dir.mkdir = mkdir





function Dir.basename(dir)
  return basename(dir.path.str)
end





function Dir.parentDir(dir)
  return new(dir.path:parentDir())
end






local insert, sort = assert(table.insert), assert(table.sort)
local sub = assert(string.sub)

local div = Path "" . divider

function Dir.getsubdirs(dir)
  local dir_str = tostring(dir)
  if sub(dir_str, -1) == div then
    dir_str = sub(dir_str, 1, -2)
  end
  local uv_fs_t = uv.fs_opendir(dir_str)
  local subdirs, done = {}, false
  repeat
    local file_obj = uv.fs_readdir(uv_fs_t)
    if file_obj then
      if file_obj[1].type == "directory" then
         insert(subdirs, dir_str .. div .. file_obj[1].name)
      end
    else
      done = true
    end
   until done
   uv.fs_closedir(uv_fs_t)
   sort(subdirs)
   for i, subdir in ipairs(subdirs) do
      subdirs[i] = new(subdir)
   end
   return subdirs
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
  local dir_str = tostring(dir)
  local uv_fs_t = uv.fs_opendir(dir_str)
  local files, done = {}, false
  repeat
    local file_obj = uv.fs_readdir(uv_fs_t)
    if file_obj then
      if file_obj[1].type == "file" then
         insert(files, dir_str .. div .. file_obj[1].name)
      end
    else
      done = true
    end
   until done
   uv.fs_closedir(uv_fs_t)
   sort(files)
   for i, file in ipairs(files) do
      files[i] = File(file)
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








local function __eq(a, b)
   local stat_a, stat_b = uv.fs_stat(a.path.str), uv.fs_stat(b.path.str)
   if (not stat_a) or (not stat_b) then
     -- same premise as NaN ~= NaN
      return false
   end
   return stat_a.ino == stat_b.ino
end




local Dir_M = { __index    = Dir,
              __tostring = __tostring,
              __concat   = __concat,
              __eq       = __eq }

new = function(path)
  local path_str = tostring(path)
  -- bail on empty string
  if path_str == "" then
    return nil, "can't make directory from empty string"
  end
  -- I believe it's safe to say that path is a sufficient, but not
   -- necessary, guarantee of uniqueness:
  if __Dirs[path_str] then
    return __Dirs[path_str]
  end
  local stat = uv.fs_stat(path_str)
  if stat and stat.type ~= "directory" then
    return nil, path_str .. " is a " .. stat.type .. ", not a directory"
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
