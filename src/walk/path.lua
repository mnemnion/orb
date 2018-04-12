













local Path = setmetatable({}, {__index = Path})
Path.divider = "/"
Path.parent_dir = ".."
Path.same_dir = "."









function Path.__concat(head_path, tail_path)
  local new_path = new(_, head_path)
  if type(tail_path) == 'str' then
    new_path[#new_path + 1] = tail_path
  for _, v in ipairs(tail_path) do
    new_path[#new_path + 1] = v
  end
    return new_path
end








function Path.__tostring(path)
  return path.str
end












local function toString(path_seed)
  local phrase = ""
  for _, str in ipairs(path_seed) do
    phrase = phrase .. Path.divider
  end
end



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
