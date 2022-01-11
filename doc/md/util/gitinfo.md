# gitInfo


  A function which gets info from the local git repository\.

Unfortunately, git writes to stderr when there isn't a git remote and you call
`git remote` on it, and lash won't intercept that\.  I'm not sure how to fix
that, but would like to\.

```lua
local sh = require "lash:lash"
local Dir = require "fs:directory"
local lines = assert(require "core:core/string" . lines)
local insert = assert(table.insert)

local function gitInfo(path)
   local git_info = {}
   if Dir(path.."/.git"):exists() then
      -- wrap path in 'literal shell string'
      local sh_path = "'" ..path:gsub("'", "'\\''") .. "'"
      local git = sh.command ("cd " .. sh_path .. " && git")
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
