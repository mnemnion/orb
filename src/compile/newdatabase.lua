

















local Dir = require "fs:directory"
local File = require "fs:file"
local s = require "status:status"
s.verbose = false

local unwrapKey, toRow = assert(sql.unwrapKey), assert(sql.toRow)






local database = {}
















local new_project = [[
INSERT INTO project (name, repo, repo_alternates, home, website)
VALUES (:name, :repo, :repo_alternates, :home, :website)
;
]]






local get_project = [[
SELECT * FROM project
WHERE project.name = ?
;
]]






local update_project = [[
UPDATE project
SET
   repo = :repo,
   repo_alternates = :repo_alternates,
   home = :home,
   website = :website
WHERE
   name = :name
;
]]









local latest_version = [[
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.project = ?
ORDER BY major DESC, minor DESC, patch DESC
LIMIT 1
;
]]






local get_version = [[
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.project = :project
AND version.major = :major
AND version.minor = :minor
AND version.patch = :patch
AND version.edition = :edition
AND version.stage = :stage
;
]]






local new_version_snapshot = [[
INSERT INTO version (edition, project)
VALUES (:edition, :project)
;
]]






local new_version = [[
INSERT INTO version (edition, stage, project, major, minor, patch)
VALUES (:edition, :stage, :project, :major, :minor, :patch)
;
]]






local insert, concat = assert(table.insert), assert(table.concat)

local function _updateProjectInfo(conn, db_project, codex_project)
   -- determine if we need to do an update
   local update = false
   for k, v in pairs(codex_project) do
      if db_project[k] ~= v then
         update = true
      end
   end
   if update then
      local stmt = conn:prepare(update_project)
      stmt:bindkv(codex_project):step()
   end
end



function database.project(conn, codex_info)
   local db_info = conn:prepare(get_project):bind(codex_info.name):resultset()
   db_info = toRow(db_info) or {}
   local project_id = db_info.project_id
   if project_id then
      s:verb("project_id is " .. project_id)
      -- update information if there are any changes
      _updateProjectInfo(conn, db_info, codex_info)
   else
      conn:prepare(new_project):bindkv(codex_info):step()
      project_id = conn:prepare(get_project):bind(codex_info.name):step()
      if not project_id then
         error ("failed to create project " .. codex.project)
      else
         project_id = project_id[1]
      end
   end
   return project_id
end






function database.version(conn, version_info, project_id)
   local version_id
   if not version_info.is_versioned then
      version_id = conn:prepare(latest_version):bind(project_id):step()
      if not version_id then
         conn : prepare(new_version_snapshot) : bindkv
              { edition = "",
                project = project_id }
              : step()
         version_id = conn:prepare(latest_version):bind(project_id):step()
         if not version_id then
            error "didn't make a SNAPSHOT"
         else
            version_id = version_id[1]
         end
      else
         version_id = version_id[1]
      end
   else
      version_info.project = project_id
      conn:prepare(new_version):bindkv(version_info):step()
      version_id = conn:prepare(get_version):bindkv(version_info):step()
      if not version_id then
         error "failed to create version"
      end
      version_id = version_id[1]
   end
   s:verb("version_id is " .. version_id)
   return version_id
end




return database
