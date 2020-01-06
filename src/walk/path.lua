




















































































local pl_mini = require "orb:util/plmini"
local isdir, relpath = pl_mini.path.isdir, pl_mini.path.relpath

local core = require "singletons/core"



local new
local Path = {}
Path.__index = Path

local __Paths = {} -- one Path per real Path

local s = require "singletons/status" ()
s.angry = false

Path.it = require "singletons/check"

Path.divider = "/"
Path.div_patt = "%/"
Path.dir_sep = ":"
Path.parent_dir = ".."
Path.same_dir = "."
local sub, find = assert(string.sub), assert(string.find)














































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
   local head_b = sub(head, -2, -1)
   local tail_b = sub(tail, 1, 1)
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
    local dir_index = find(remain, div_patt)
    if dir_index then
      -- add the handle minus div
      path[#path + 1] = sub(remain, 1, dir_index - 1)
      -- then the div
      path[#path + 1] = div
      local new_remain = sub(remain, dir_index + 1)
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
   local parent_offset
   if path[#path] == Path.divider then
      parent_offset = #path[#path-1] + 2
   else
      parent_offset = #path[#path] + 1
   end
   local parent = sub(path.str, 1, - parent_offset)
   local p_last = sub(parent, -1)
   -- This shouldn't be needful but <shrug>
   if p_last == Path.divider then
      return new(sub(parent, 1, -2))
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










local litpat = core.litpat
local extension -- defined below

function Path.subFor(path, base, newbase, ext)
   local path, base, newbase = tostring(path),
                               tostring(base),
                               tostring(newbase)
   if find(path, litpat(base)) then
      local rel = sub(path, #base + 1)
      if ext then
         if sub(ext, 1, 1) ~= "." then
            ext = "." .. ext
         end
         local old_ext = extension(path)
         rel = sub(rel, 1, - #old_ext - 1) .. ext
      end
      return new(newbase .. rel)
   else
      s:complain("path error", "cannot sub " .. newbase .. " for " .. base
                 .. " in " .. path)
   end
end








local function splitext(path)
    local i = #path
    local ch = sub(path, i, i)
    while i > 0 and ch ~= '.' do
        if ch == Path.divider or ch == Path.dir_sep then
            return path, ''
        end
        i = i - 1
        ch = sub(path, i, i)
    end
    if i == 0 then
        return path, ''
    else
        return sub(path, 1, i-1), sub(path, i)
    end
end

local function splitpath(path)
    local i = #path
    local ch = sub(path, i, i)
    while i > 0 and ch ~= Path.divider and ch ~= Path.dir_sep do
        i = i - 1
        ch = sub(path,i, i)
    end
    if i == 0 then
        return '', path
    else
        return sub(path, 1, i-1), sub(path, i+1)
    end
end



function Path.extension(path)
   local _ , ext = splitext(tostring(path))
  return ext
end

extension = Path.extension





function Path.basename(path)
   local _, base = splitpath(tostring(path))
   return base
end








function Path.dirname(path)
   local dir = splitpath(tostring(path))
   return dir
end













function Path.barename(path)
   return sub(path:basename(), 1, -(#path:extension() + 1))
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

Path.idEst = new












return new
