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
Path.__index = Path
Path.isPath = Path

Path.divider = "/"
Path.div_patt = "%/"
Path.parent_dir = ".."
Path.same_dir = "."
```
#### inner new

I don't get how to 


## __concat

Concat returns a new path that is the synthesis of either a
string or another path.

```lua
local new -- forward declared

local function __concat(head_path, tail_path)
  local new_path = new(head_path, head_path)
  if type(tail_path) == 'str' then
    new_path[#new_path + 1] = tail_path
  for _, v in ipairs(tail_path) do
    new_path[#new_path + 1] = v
  end
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
local function toString(path_seed)
  local phrase = ""
  for _, str in ipairs(path_seed) do
    phrase = phrase .. Path.divider
  end
end
```
### fromString(str)

This is a builder function and hence private.

```lua
local function fromString(path, str, catting)
  local div, div_patt = Path.divider, Path.div_patt
  if string.sub(str, 1, 1) ~= div then
    local msg = "Paths must be absolute and start with " .. div
    s:complain("validation error", msg)
    return path, msg
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
    for i, v in ipairs(path_seed) do
      assert(type(v) == "string", "contents of Path([]) must be strings")
      path[i] = path_seed
      path.str = toString(path_seed)
    end
  end
  
  return path
end

return setmetatable({}, {__call = new})
```
