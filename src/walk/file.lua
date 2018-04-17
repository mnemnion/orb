



local Path = require "walk/path"
local lfs = require "lfs"
local pl_path = require "pl.path"
local pl_file = require "pl.file"
local read, write = pl_file.read, pl_file.write
local extension = pl_path.extension
local isfile = pl_path.isfile



local new



local function __tostring(file)
   return file.path.str
end




local File = {}
local __Files = {}
File.it = require "core/check"



function File.parentPath(file)
   return file.path:parentDir()
end



function File.exists(file)
   return isfile(file.path.str)
end



function File.extension(file)
   return extension(file.path.str)
end



function File.read(file)
   return read(file.path.str)
end





function File.write(file, doc)
   return write(file.path.str, tostring(doc))
end




local FileMeta = { __index = File,
                   __tostring = __tostring}

new = function (file_path)
   file_str = tostring(file_path)
   if __Files[file_str] then
      return nil, "won't make the same file twice"
   end

   local file = setmetatable({}, FileMeta)
   if type(file_path) == "string" then
      file.path = Path(file_path)
   elseif file_path.idEst == Path
      and not file_path.isDir then
      file.path = file_path
   end
   __Files[file_str] = true

   return file
end




File.idEst = new
return new
