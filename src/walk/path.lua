



















































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














































local function clone(path)
  local new_path = {}
  for k,v in pairs(path) do
    new_path[k] = v
  end
  setmetatable(new_path, getmetatable(path))
  return new_path
end









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









local function __concat(head_path, tail_path)
  local new_path = clone(head_path)
  if type(tail_path) == 'string' then
    -- use the stringbuilder
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

    return new_path
  else
    s:complain("NYI", "can only concatenate string at present")
  end
end
















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










local function __tostring(path)
  return path.str
end









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












local PathCall = setmetatable({}, {__call = new})
Path.isPath = new
return new
