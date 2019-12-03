




local core = require "singletons/core"
local sh = require "orb:util/sh"
local pl = require "orb:util/plmini"
local git = sh.command "git"
local isdir = pl.path.isdir
local lines = core.lines
local insert = assert(table.insert)

local function gitInfo(path)
   local git_info = {}
   if isdir(path.."/.git") then
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
            insert(git_info.remotes,
                  { [remote] = tostring(git ("remote get-url " .. remote)) })
         end
      end
   else
      git_info.is_repo = false
   end
   return git_info
end

return gitInfo
