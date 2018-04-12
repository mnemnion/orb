# Path #Todo

Let's make a little Path class that isn't just a string.


They need to be:


-  Immutable. Adding to a path or substituting within it
   produces a new path; a path can't be changed once it's
   established. 


-  Stringy.  ``tostring`` gives us the literal string rep of
   the Path, __concat works (but immutably), and so on.

```lua
local Path = {}
local s = require "status" ()
s.angry = false

Path.__index = Path
Path.isPath = Path

Path.divider = "/"
Path.div_patt = "%/"
Path.parent_dir = ".."
Path.same_dir = "."
```
## __concat

Concat returns a new path that is the synthesis of either a
string or another path.

```lua
local new      -- function
local fromString -- function

local function __concat(head_path, tail_path)
    local new_path = new(Path, head_path, catting)
  if type(tail_path) == 'string' then
    new_path[#new_path + 1] = tail_path
    local phrase = new_path.str or ""
    new_path.str = phrase .. tail_path
    return new_path
  else
    local phrase = head_path.str or ""
    for _, v in ipairs(tail_path) do
      new_path[#new_path + 1] = v
      phrase = phrase .. v
    end
    new_path = fromString(new_path, new_path.str .. phrase, true)
    return new_path
  end
end
```
## __tostring

Since we normally supply a path as a string, we just keep it around.

```lua
local function __tostring(path)
  return path.str
end
```
### toString(path_seed)

We want to accept any old array of strings whether it's a Path or not,
so we can't count on the path_seed having a ``.str`` field.


- [ ] #todo  This will always produce a directory, which isn't what
             we want. 

```lua
toString = function (path_seed)
  local phrase = ""
  for _, str in ipairs(path_seed) do
    phrase = Path.divider .. phrase
  end
  return phrase
end
```
### fromString(str)

This is a builder function and hence private.

```lua
local function fromString(path, str, catting)
  local div, div_patt = Path.divider, Path.div_patt
  if string.sub(str, 1, 1) ~= div and not catting then
    local msg = "Paths must be absolute and start with " .. div
    s:complain("validation error", msg)
    return nil, msg
  else
    local phrase = ""
    local remain = string.sub(str, 2)
    while remain  do
      local dir_index = string.find(remain, div_patt)
      if dir_index then
        -- add the handle minus div
        path[#path + 1] = string.sub(remain, 1, dir_index - 1)
        local new_remain = string.sub(remain, dir_index + 1)
        assert(#new_remain < #remain, "remain must decrease")
        remain = new_remain

      else
        -- file
        path[#path + 1] = remain
        remain = nil  
      end
    end
    return path
  end
end
```
```lua
new = function (Path, path_seed)
  local path = setmetatable({}, {__index = Path,
                               __concat = __concat,
                               __tostring = __tostring})
  if type(path_seed) == 'string' then
    path.str = path_seed
    path =  fromString(path, path_seed)
  else
      io.write("building from table of length " .. #path_seed .. "\n")
      if not path_seed.isPath then
        io.write("path_seed is Path\n")
      else 
        io.write("path_seed is not Path, instead: " 
                .. tostring(path_seed) .. "\n")
       end
      local phrase = ""
    for i, v in ipairs(path_seed) do
      assert(type(v) == "string", "contents of Path([]) must be strings, not"
             .. type(v) .. " with flag .isPath: " .. tostring(v.isPath))
      io.write("adding " .. v  .. "\n") 
      path[i] = path_seed
      phrase = phrase .. v
    end
    path.str = fromString(path, phrase)
  end
  
  return path
end

return setmetatable({}, {__call = new})
```
