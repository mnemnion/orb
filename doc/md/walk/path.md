# Path #Todo

Let's make a little Path class that isn't just a string.


They need to be:


-  Immutable. Adding to a path or substituting within it
   produces a new path; a path can't be changed once it's
   established.


-  Stringy.  ``tostring`` gives us the literal string rep of
   the Path, __concat works (but immutably), and so on.


## Fields

The array portion of Path tables is entirely strings.


Special characters, notably "/", are represented, by themselves,
as strings.


- Prototype


  -  divider:  The dividing character, ``/`` in all sensible realms.


  -  div_patt:  This is ``%/``, in a quirk of Lua.


  -  parent_dir, same_dir:  Not currently used.


  -  isPath:  Always equal to the Path table.


- Instance


  -  filename:  If present, the name of the file.


  -  isDir:  If ``true``, indicates the Path is structured to be a directory.
        It does **not** indicate that there is a real directory at this path.


  -  str:  The string form of the path.


```lua
local Path = {}
local s = require "status" ()
s.angry = true

Path.__index = Path
Path.isPath = Path

Path.divider = "/"
Path.div_patt = "%/"
Path.parent_dir = ".."
Path.same_dir = "."
```
## Methods


## __concat

Concat returns a new path that is the synthesis of either a
string or another path.

```lua
local new      -- function
```
### clone(path)

This returns a copy of the path with the metatable stolen.

```lua
local function clone(path)
  local new_path = {}
  for k,v in pairs(path) do
    new_path[k] = v
  end
  setmetatable(new_path, getmetatable(path))
  return new_path
end

```
### stringAwk

This is used twice, once to build new paths, and once to add to them.

```lua
local function stringAwk(path, str)
  local div, div_patt = Path.divider, Path.div_patt
  local phrase = ""
  local remain = string.sub(str, 2)
  path[1] = div
    -- chew the string like Pac Man
  while remain  do
    local dir_index = string.find(remain, div_patt)
    if dir_index then
      -- add the handle minus div
      path[#path + 1] = string.sub(remain, 1, dir_index - 1)
      -- then the div
      path[#path + 1] = div
      local new_remain = string.sub(remain, dir_index + 1)
      assert(#new_remain < #remain, "remain must decrease")
      remain = new_remain
      if remain == "" then
        remain = nil
      end
    else
      -- file
      path[#path + 1] = remain
      path.filename = remain
      remain = nil
    end
  end
  if not path.filename then
    path.isDir = true
  end

  return path
end
```
```lua
local function __eq(left, right)
  local isEq = false
  for i = 1, #left do
    isEq = isEq and left[i] == right[i]
  end
  return isEq
end

```
```lua
local function __concat(head_path, tail_path)
  local new_path = clone(head_path)
  if type(tail_path) == 'string' then
    -- use the stringbuilder
    local path_parts = stringAwk({}, tail_path)
    for _, v in ipairs(path_parts) do
      new_path[#new_path + 1] = v
    end

    new_path.str = new_path.str .. tail_path
    if path_parts.isDir then
      new_path.isDir = true
    else
      new_path.filename = path_parts.filename
    end

    return new_path
  else
    s:complain("NYI", "can only concatenate string at present")
  end
end
```
## __tostring

Since we always have a path as a string, we simply return it.

```lua
local function __tostring(path)
  return path.str
end
```
### fromString(str)

This is a builder function and hence private.

```lua
local function fromString(path, str)
  local div, div_patt = Path.divider, Path.div_patt
  if string.sub(str, 1, 1) ~= div and not catting then
    local msg = "Paths must be absolute and start with " .. div
    s:complain("validation error", msg)
    return nil, msg
  else
    return stringAwk(path, str, div, div_patt)
  end
end
```
### new

Builds a Path from, currently, a string.


This is the important use case.

```lua
new = function (Path, path_seed)
  local path = setmetatable({}, {__index = Path,
                               __concat = __concat,
                               __eq  = __eq,
                               __tostring = __tostring})
  if type(path_seed) == 'string' then
    path.str = path_seed
    path =  fromString(path, path_seed)
  elseif type(path_seed) == 'table' then
    s:complain("NYI", 'construction from a Path or other table is not yet implemented')
  end

  return path
end
```

This is complex and worse, it isn't working.

```lua
function Path.spec(path)
  local a = new(_, "/core/build/")
  assert(#a == 5, "a must equal 5 not" .. #a)
  assert(a[1] == "/", "a must start with /")
  local b = clone(a)
  assert(#b == 5, "b must equal 5")
  assert(b[1] == "/", "b must start with /")
  assert(a.str == b.str, "a and b must have the same str")
  local c = a .. "/bar"
end
Path.spec()
```
```lua
return setmetatable({}, {__call = new})
```
