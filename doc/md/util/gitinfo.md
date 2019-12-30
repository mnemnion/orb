# gitInfo

A function which gets info from the local git repository

```lua
local core = require "singletons/core"
local sh = require "orb:util/sh"
local pl = require "orb:util/plmini"
local isdir = assert(pl.path.isdir)
local lines = assert(core.lines)
local insert = assert(table.insert)

local function gitInfo(path)
   local git_info = {}
   if isdir(path.."/.git") then
      local git = sh.command ("cd " .. path .. " && git")
      git_info.is_repo = true
      local branches = tostring(git "branch")
      for branch in lines(branches) do
         if branch:sub(1,1) == "*" then
            git_info.branch = branch:sub(3)
         end
      end
      local remotes = tostring(git "remote")
      if remotes then
         git_info.remotes = {}
         for remote in lines(remotes) do
            local url = tostring(git("remote", "get-url", remote))
            if remote == "origin" then
               git_info.url = url
            end
            insert(git_info.remotes, {remote, url})
         end
         if not git_info.url then
            git_info.url = git_info.remotes[1] and git_info.remotes[1][2]
         end
      end
      git_info.commit_hash = tostring(git("rev-parse", "HEAD"))
   else
      git_info.is_repo = false
   end
   return git_info
end

return gitInfo
```
