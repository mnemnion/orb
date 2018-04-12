# Path #Todo

Let's make a little Path class that isn't just a string.


They need to be:


-  Immutable. Adding to a path or substituting within it
   produces a new path; a path can't be changed once it's
   established. 


-  Stringy.  ``tostring`` gives us the literal string rep of
   the Path, __concat works (but immutably), and so on.

```lua
local Path = setmetatable({}, {__index = Path})
Path.divider = "/"
Path.parent_dir = ".."
Path.same_dir = "."
```
## __concat

Concat returns a new path that is the synthesis of either a
string or another path.

```lua
function Path.__concat(head_path, tail_path)
  local new_path = new(_, head_path)
  if type(tail_path) == 'str' then
    new_path[#new_path + 1] = tail_path
  for _, v in ipairs(tail_path) do
    new_path[#new_path + 1] = v
  end
    return new_path
end
```
## __tostring

Since we normally supply a path as a string, we just keep it around.

```lua
function Path.__tostring(path)
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
```lua
local function new(Path, path_seed)
  local path = setmetatable({}, Path)
  if type(path_seed) == 'string' then
    path.str = path_seed
    path =  fromString(path_seed)
  else
    for i, v ipairs(path_seed) do
      assert(type(v) == "string", "contents of Path([]) must be strings")
      path[i] = path_seed
      path.str = toString(path_seed)
    end
  end
  
  return path
end

return Path
```
