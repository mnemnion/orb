















































































local uv = require "luv"
local Path = require "walk/path"
local running, resume, yield = assert(coroutine.running),
                               assert(coroutine.resume),
                               assert(coroutine.yield)



local File = {}
local _Files = setmetatable({}, {__mode = "v"})




function File.parentPath(file)
end




function File.exists(file)
end




function File.basename(file)
end




function File.extension(file)
end








function File.read(file)
   local co, main = running()
   if main or (not uv.loop_alive()) then
      local f = io.open(file.path.str, "r")
      if not f then
         return nil, "cannot open for read: " .. file.path.str
      end
      local content = f:read("*a")
      f:close()
      return content
   else
      -- 420 == tonumber('644', 8)
      local path = tostring(file.path)
      local stat, err = uv.fs_stat(path)
      if not stat then
         return resume(co, nil, "error opening file: " .. err)
      end
      uv.fs_open(file.path.str, "r", 420, function(err, fd)
         if err then
            return resume(co, nil, "error opening file: " .. err)
         end
         local stat = uv.fs_fstat(fd)
         local content = uv.fs_read(fd, stat.size, 0)
         uv.fs_close(fd)
         return resume(co, content)
      end)
      return yield()
   end
end










local function _withMode(mode)
   return function (file, doc)
      if uv.loop_alive() then
         uv.fs_open(file.path.str, mode, 420, function(err, fd)
            if err then
               error("unable to open for write: " .. file.path.str)
            end
            uv.fs_write(fd, tostring(doc), -1, function()
               uv.fs_close(fd)
            end)
         end)
      else
         local f = io.open(file.path.str, mode)
         if not f then
            error("cannot open for write: " .. file.path.str)
         end
         f:write(tostring(doc))
         f:close()
      end
   end
end

File.write = _withMode "w"
File.append = _withMode "a"






local FileMeta = { __index = File }

local function new (file_path)
   local file_str = tostring(file_path)
   -- #nb this is a naive and frankly dangerous guarantee of uniqueness
   -- and is serving in place of something real since filesystems... yeah
   if _Files[file_str] then
      return _Files[file_str]
   end

   local file = setmetatable({}, FileMeta)
   if type(file_path) == "string" then
      file_path = Path(file_path)
   end
   if file_path.isDir then
      error("cannot make file: " .. file_path.str .. " is a directory")
   end
   file.path = file_path
   _Files[file_str] = file

   return file
end

File.idEst = new



return new
