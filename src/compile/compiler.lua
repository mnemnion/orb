

















local compiler, compilers = {}, {}
compiler.compilers = compilers






local sha512 = require "orb:compile/sha2" . sha3_512

local s = require "singletons/status" ()
s.verbose = false








local sub = assert(string.sub)
local function sha(str)
   return sub(sha512(str),1,64)
end





















local function _moduleName(path, project)
   local mod = {}
   local inMod = false
   for i, v in ipairs(path) do
      if v == project then
         inMod = true
      end
      if inMod then
         if i ~= #path then
            table.insert(mod, v)
          else
             table.insert(mod, path:barename())
         end
      end
   end
   -- drop the bits of the path we won't need
   --- awful kludge fix
   local weird_path = table.concat(mod)
   local good_path = string.gsub(weird_path, "%.%_", "")
   local _, cutpoint = string.find(good_path, "/src/")
   local good_path = string.sub(good_path, cutpoint + 1)
   return good_path
end








function compilers.lua(skein)
   local project = skein.codex.project
   skein.compiled = skein.compiled or {}
   local compiled = skein.compiled
   local path = skein.knitted.scrolls.lua.path
   local src = skein.knitted.scrolls.lua
   local mod_name = _moduleName(path, project)
   local bytecode, err = load (tostring(src), "@" .. mod_name)
   if bytecode then
      -- add to srcs
      local byte_str = tostring(src) -- #todo: parse and strip
      local byte_table = {binary = byte_str}
      byte_table.hash = sha(byte_str)
      byte_table.name = mod_name
      byte_table.err = false
      compiled.lua = byte_table
      s:verb("compiled: " .. project .. ":" .. byte_table.name)
   else
      s:chat "error:"
      s:chat(err)
      compiled.lua = { err = err }
   end
end











function compiler.compile(compiler, skein)
   for extension, scroll in pairs(skein.knitted.scrolls) do
      if compiler.compilers[extension] then
         compiler.compilers[extension](skein)
      end
   end
end








local unwrapKey, toRow, blob = sql.unwrapKey, sql.toRow, sql.blob

function compiler.commitModule(compiler, skein, stmt, project_id,
                               bundle_id, version_id, git_info, now)
   -- get code_id from the hash
   local code_id = unwrapKey(stmt.code_id:bindkv(bytecode):resultset())
   if not code_id then
      bytecode.binary = blob(bytecode.binary)
      stmt.new_code:bindkv(bytecode):step()
      stmt.code_id:reset()
      code_id = unwrapKey(stmt.code_id:bindkv(bytecode):resultset())
   end
   s:verb("code ID is " .. code_id)
   s:verb("module name is " .. bytecode.name)
   if not code_id then
      error("code_id not found for " .. bytecode.name)
   end
   local mod = { name    = bytecode.name,
                 project = project_id,
                 bundle  = bundle_id,
                 code    = code_id,
                 version = version_id,
                 time    = now }
   if git_info.is_repo then
      mod.vc_hash = git_info.commit_hash
      mod.branch  = git_info.branch
   end
   stmt.add_module:bindkv(mod):step()
   for _, st in pairs(stmt) do
      st:reset()
   end
end



return compiler
