# Directory


This is our object for directory management.


Like everything written during this phase of the operation, it is no doubt
needlessly complex.  For now I intend to document this.


```lua
local uv = require "luv"
local s = require "status:status" ()
s.chatty = true
s.verbose = false

local sh = require "orb:util/sh"

local Path = require "fs:path"
local File = require "fs:file"
```
```lua
local new
```
```lua
local Dir = {}
Dir.isDir = Dir
Dir.it = require "singletons/check"

-- Cache to keep each Dir unique by path name
local __Dirs = setmetatable({}, {__mode = "v"})
```
### Dir:exists()

```lua
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
```
### Dir:mkdir(mode)

Makes a directory. ``mode`` is either a chmod-style mode string or a decimal
number.

#NB this method currently crashes if one tries to make a subdirectory when```lua
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
```
## Dir.basename(dir)

```lua
function Dir.basename(dir)
  return dir.path:basename()
end
```
## Dir.parentDir(dir)

```lua
function Dir.parentDir(dir)
  return new(dir.path:parentDir())
end
```
## Dir.getsubdirs(dir)

```lua
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
```
### Dir.swapDirFor(dir, nestDir, newNest)

The nomenclature isn't great here, which is my ignorance of
directory handling showing. But let's get through it.


It's easiest to illustrate:

```lua-example
a = Dir "/usr/local/bin/"
b = a:swapDirFor("/usr/", "/tmp")
tostring(b)
-- "/tmp/local/bin/"
```

It has to be a proper absolute path, which is currently enforced everywhere
a Path is used and will be until I start to add link resolution, since it's
the correct way to treat paths to things that happen to exist.  This is my
need at the moment.

```lua
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
```
```lua
function Dir.attributes(dir)
  local stat = uv.fs_stat(tostring(dir.path))
  return stat
end
```
### Dir.getfiles(dir)

Our ``getfiles`` sorts the files alphabetically.  When I want a directory
full of files, it's either for comparison or iteration over, in either
case a defined order is helpful.

```lua
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
```
```lua
local function __tostring(dir)
  return dir.path.str
end
```
### __concat(dir, path)

This implementation is terrible:


It assumes that the Directory is on the left, that the right is either a
path(?) or a string(?), and I really hope I don't use it because I want to
tear it out.


It is of course **very** challenging to search for uses... blah.


A good implementation would check which side is what, and handle Paths,
strings, and Files.

```lua
local function __concat(dir, path)
    if type(dir) == "string" then
        return new(dir .. path)
    end
    return new(dir.path.str .. tostring(path))
end
```
### __eq

We fstat both directories and get the ino, and compare this, rather than the
pathname.

```lua
local function __eq(a, b)
   local stat_a, stat_b = uv.fs_stat(a.path.str), uv.fs_stat(b.path.str)
   if (not stat_a) or (not stat_b) then
     -- same premise as NaN ~= NaN
      return false
   end
   return stat_a.ino == stat_b.ino
end
```
```lua
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
  -- strip trailing "/"
  if sub(path_str, -1) == div then
    path_str = sub(path_str, 1, -2)
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
  dir.path = Path(path_str)

  __Dirs[tostring(path)] = dir

  return dir
end
```
```lua
Dir.idEst = new
return new
```
