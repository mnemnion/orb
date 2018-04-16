# Path


Let's make a little Path class that isn't just a string.


They need to be:


-  Immutable. Adding to a path or substituting within it
   produces a new path; a path can't be changed once it's
   established.


-  Stringy.  ``tostring`` gives us the literal string rep of
   the Path, __concat works (but immutably), and so on.


Paths are going to be heavily re-used and extended, first by Directories
and Files, and then we'll want to take a pass a making them grammatical
and extending their properties to the URI class.


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


  -  filename:  If present, the name of the file.  This will always be
                ``nil`` for a directory.


  -  isDir:  If ``true``, indicates the Path is structured to be a directory.
        It does **not** indicate that there is a real directory at this path.


  -  str:  The string form of the path.  ``__tostring`` simply returns this,
           it is in-contract to read from this field.  Nothing but Path
           should write to it, which we won't enforce until we can do so
           at compile time.


- [ ] #todo   Check memoized ``__Path`` table during ``__concat``.

```lua
local new
local Path = setmetatable({}, {__index = Path})

local __Paths = {} -- one Path per real Path

local s = require "status" ()
s.angry = false

Path.it = require "core/check"

Path.divider = "/"
Path.div_patt = "%/"
Path.parent_dir = ".."
Path.same_dir = "."
```
## Methods


## __concat

Concat returns a new path that is the synthesis of either a
string or another path.


- params


  -  head_path:  A Path. Cloned before concatenation.


  -  tail_path:  If a String, this is concatenated.  If the result is
           not a structurally valid string, this is complained about
           and nil is returned.


           If it's another Path, we want to do the right thing, and not
           make developers guess what that might be, so:


           If it's two absolute Paths, then **iff** the tail_path nests in the
           head_path, the tail_path is returned.  So ``"/usr/" .. "/usr/bin/"``
           returns ``"/usr/bin"``.


           If the tail_path is relative, then it's flexibly applied to the
           head_path. For a path that _doesn't_ start with ``.``, ``..``, or ``*``,
           this is simple concatenation.


           Note that ``__concat`` refuses to make "foo//bar" from "foo/"
           and "/bar", and similarly won't make "/foobar" from "/foo" and "bar". Both
           of these will return ``nil``, and the malformed string as the error. #nyi




- return


  - A new Path.


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
#### endsMatch(head, tail)

Takes two strings. Returns true if they are heterosexual,
pathwise.

```lua
local function endsMatch(head, tail)
   local div = Path.divider
   head_b = string.sub(head, -2, -1)
   tail_b = string.sub(tail, 1, 1)
   if div == head_b
      and div == tail_b then
      return false
   elseif div ~= head_b
      and div ~= tail_b then
      return false
   end

   return true
end
```
### stringAwk

This is used twice, once to build new paths, and once to add to them.

```lua
local function stringAwk(path, str)
  local div, div_patt = Path.divider, Path.div_patt
  local phrase = ""
  local remain = str
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
local function __concat(head_path, tail_path)
  local new_path = clone(head_path)
  if type(tail_path) == 'string' then
    -- use the stringbuilder
      if not endsMatch(head_path[#head_path], tail_path) then
         return nil
      end
    local path_parts = stringAwk({}, tail_path)
    for _, v in ipairs(path_parts) do
      new_path[#new_path + 1] = v
    end

    new_path.str = new_path.str .. tail_path
    if string.sub(new_path.str, -1) == Path.divider then
      new_path.isDir = true
      new_path.filename = nil
    else
      new_path.filename = path_parts.filename
    end

    if __Paths[new_path.str] then
      return __Paths[new_path.str]
    end

      __Paths[new_path.str] = new_path
    return new_path
  else
    s:complain("NYI", "can only concatenate string at present")
  end
end
```
## Path.parentDir(path, dir)

Currently only accepts a string for ``dir``.


It proceeds backwards looking for "dir".  If it finds a match, it
returns a new path that has the full directory.


Example: if the path is "/usr/local/bin/", ``path:parentDir("local")`` will
return ``Path "/usr/local/"``.


Only valid for directories.  If called on a filename, or if the subdirectory

```lua
function Path.parentDir(path, dir)
  if not path.isDir then
    return nil
  end

  for i = #path, 1, -1 do
    if path[i] == dir then
      local path_phrase = ""
      for j = 1, i do
        path_phrase = path_phrase .. path[j]
      end
      return new(path_phrase .. "/")
    end
  end

  return nil
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
local PathMeta = {__index = Path,
                  __concat = __concat,
                  __tostring = __tostring}

new  = function (path_seed)
  if __Paths[path_seed] then
    return __Paths[path_seed]
  end
  local path = setmetatable({}, PathMeta)
  if type(path_seed) == 'string' then
    path.str = path_seed
    path =  fromString(path, path_seed)
  elseif type(path_seed) == 'table' then
    s:complain("NYI", 'construction from a Path or other table is not yet implemented')
  end

  __Paths[path_seed] = path

  return path
end
```
### Constructor and flag

I think this does what I want for this class: it generates a Path on call,
and provides a table for reference equality.


The idea is that some aspect of an instance object can be compared to the
module as produced from "require".

```lua
local PathCall = setmetatable({}, {__call = new})
Path.isPath = new
Path.idEst = new
return new
```
