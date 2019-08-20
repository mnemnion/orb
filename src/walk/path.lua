


































































local pl_mini = require "util/plmini"
local isdir, relpath = pl_mini.path.isdir, pl_mini.path.relpath



local new
local Path = {}
Path.__index = Path

local __Paths = {} -- one Path per real Path

local s = require "status" ()
s.angry = false

Path.it = require "kore/check"

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
   local ps = path.str and path.str or str
  if isdir(ps) then
    path.isDir = true
      path.filename = nil
  end

  return path
end




local function __concat(head_path, tail_path)
  local new_path = clone(head_path)
  if type(tail_path) == 'string' then
    -- use the stringbuilder
      if not endsMatch(head_path[#head_path], tail_path) then
         return nil, "cannot build path from " .. tostring(head_path)
                     .. " and " .. tostring(tail_path)
      end
    local path_parts = stringAwk({}, tail_path)
    for _, v in ipairs(path_parts) do
      new_path[#new_path + 1] = v
    end

    new_path.str = new_path.str .. tail_path
    if isdir(new_path.str) then
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








function Path.parentDir(path)
   local parent = string.sub(path.str, 1, - (#path[#path] + 1))
   local p_last = string.sub(parent, -1)
   -- This shouldn't be needful but <shrug>
   if p_last == "/" then
      return new(string.sub(parent, 1, -2))
   else
      return new(parent)
   end
end










local function __tostring(path)
  return path.str
end








local function fromString(path, str)
  local div, div_patt = Path.divider, Path.div_patt
  return stringAwk(path, str, div, div_patt)
end





function Path.relPath(path, rel)
   local rel = tostring(rel)
   local rel_str = relpath(path.str, rel)
   return new(rel_str)
end










function Path.subFor(path, base, newbase, ext)
   local path, base, newbase = tostring(path),
                               tostring(base),
                               tostring(newbase)
   if string.find(path, base) then
      local rel = string.sub(path, #base + 1)
      if ext then
         local old_ext = pl_mini.path.extension(path)
         rel = string.sub(rel, 1, - #old_ext - 1) .. ext
      end
      return new(newbase .. rel)
   else
      s:complain("path error", "cannot sub " .. newbase .. " for " .. base
                 .. " in " .. path)
   end
end








function Path.extension(path)
   return pl_mini.path.extension(path.str)
end





function Path.basename(path)
   return pl_mini.path.basename(path.str)
end












function Path.barename(path)
   return string.sub(path:basename(), 1, -(#path:extension() + 1))
end










function Path.has(path, substr)
   for _, v in ipairs(path) do
      if v == substr then
         return true
      end
   end

   return false
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
Path.idEst = new
return new
