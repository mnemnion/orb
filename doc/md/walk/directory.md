# Directory


This is our object for directory management.


Like everything written during this phase of the operation, it is no doubt
needlessly complex.  For now I intend to document this.


```lua
local s = require "status" ()
s.chatty = true
s.verbose = false

local pl_mini = require "util/plmini"
local lfs = require "lfs"
local attributes = lfs.attributes
local isdir, basename  = pl_mini.path.isdir, pl_mini.path.basename
local getfiles, getdirectories = pl_mini.dir.getfiles, pl_mini.dir.getdirectories
local mkdir = lfs.mkdir

local Path = require "orb:walk/path"
local File = require "orb:walk/file"
```
```lua
local new
```
```lua
local Dir = {}
Dir.isDir = Dir
Dir.it = require "singletons/check"

local __Dirs = {} -- Cache to keep each Dir unique by path name
```
### Dir:exists()

```lua
function Dir.exists(dir)
  return isdir(dir.path.str)
end
```
```lua
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
```
## Dir.parentDir(dir)

```lua
function Dir.parentDir(dir)
  return new(dir.path:parentDir())
end
```
## Dir.basename(dir)

```lua
function Dir.basename(dir)
  return basename(dir.path.str)
end
```
## Dir.subdirectories(dir)

```lua
function Dir.getsubdirs(dir)

  local subdir_strs = getdirectories(dir.path.str)
  dir.subdirs = {}
  for i,sub in ipairs(subdir_strs) do
    s:verb(sub)
    dir.subdirs[i] = new(sub)
  end
  return dir.subdirs
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
  dir.attr = attributes(dir.path.str)
  return dir.attr
end
```
### Dir.getfiles(dir)

Our ``getfiles`` sorts the files alphabetically.  When I want a directory
full of files, it's either for comparison or iteration over, in either
case a defined order is helpful.

```lua
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
```
```lua
local function __tostring(dir)
  return dir.path.str
end
```
```lua
local function __concat(dir, path)
    if type(dir) == "string" then
        return new(dir .. path)
    end
    return new(dir.path.str .. tostring(path))
end
```
```lua
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
```
```lua
Dir.idEst = new
return new
```
