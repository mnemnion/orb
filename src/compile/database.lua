








local s = require "singletons/status"
s.verbose = false
local sql = assert(sql, "must have sql in bridge _G")
local sqltools = require "orb:compile/sqltools"
local Dir = require "orb:walk/directory"
local File = require "orb:walk/file"

local sha = require "compile/sha2" . sha3_512

local status = require "singletons/status" ()



local Database = {}











local create_project_table = [[
CREATE TABLE IF NOT EXISTS project (
   project_id INTEGER PRIMARY KEY AUTOINCREMENT,
   name STRING UNIQUE NOT NULL ON CONFLICT IGNORE,
   repo STRING,
   repo_type STRING DEFAULT 'git',
   repo_alternates STRING,
   home STRING,
   website STRING
);
]]

local create_version_table = [[
CREATE TABLE IF NOT EXISTS version (
   version_id INTEGER PRIMARY KEY AUTOINCREMENT,
   edition STRING DEFAULT 'SNAPSHOT',
   major INTEGER DEFAULT 0,
   minor INTEGER DEFAULT 0,
   patch STRING DEFAULT '0',
   project INTEGER,
   FOREIGN KEY (project)
      REFERENCES project (project_id)
);
]]






local create_code_table = [[
CREATE TABLE IF NOT EXISTS code (
   code_id INTEGER PRIMARY KEY AUTOINCREMENT,
   hash TEXT UNIQUE ON CONFLICT IGNORE NOT NULL,
   binary BLOB NOT NULL
);
]]

local create_module_table = [[
CREATE TABLE IF NOT EXISTS module (
   module_id INTEGER PRIMARY KEY AUTOINCREMENT,
   time DATETIME DEFAULT CURRENT_TIMESTAMP,
   snapshot INTEGER DEFAULT 1,
   name STRING NOT NULL,
   type STRING DEFAULT 'luaJIT-2.1-bytecode',
   branch STRING,
   vc_hash STRING,
   project INTEGER NOT NULL,
   code INTEGER,
   version INTEGER NOT NULL,
   FOREIGN KEY (version)
      REFERENCES version (version_id)
      -- ON DELETE RESTRICT
   FOREIGN KEY (project)
      REFERENCES project (project_id)
      ON DELETE RESTRICT
   FOREIGN KEY (code)
      REFERENCES code (code_id)
);
]]






local new_project = [[
INSERT INTO project (name, repo, repo_alternates, home, website)
VALUES (:name, :repo, :repo_alternates, :home, :website)
;
]]

local new_code = [[
INSERT INTO code (hash, binary)
VALUES (:hash, :binary)
;
]]

local new_version_snapshot = [[
INSERT INTO version (edition, project)
VALUES (:edition, :project)
;
]]

local new_version = [[
INSERT INTO version (edition, project, major, minor, patch)
VALUES (:edition, :project, :major, :minor, :patch)
;
]]

local add_module = [[
INSERT INTO module (snapshot, version, name,
                    branch, vc_hash, project, code)
VALUES (:snapshot, :version, :name, :branch,
        :vc_hash, :project, :code)
;
]]

local update_project_head = [[
UPDATE project
SET
]]

local update_project_foot = [[
WHERE
  name = %s
;
]]

local update_project_params = { repo = 'repo = %s',
                                repo_alternates = 'repo_alternates = %s',
                                home = 'home = %s',
                                website = 'website = %s' }

local get_snapshot_version = [[
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.edition = 'SNAPSHOT'
;
]]

local get_project_id = [[
SELECT CAST (project.project_id AS REAL) FROM project
WHERE project.name = %s
;
]]

local get_project = [[
SELECT * FROM project
WHERE project.name = %s
;
]]

local get_code_id_by_hash = [[
SELECT CAST (code.code_id AS REAL) FROM code
WHERE code.hash = %s;
]]

local get_latest_module_code_id = [[
SELECT CAST (module.code AS REAL) FROM module
WHERE module.project = %d
   AND module.name = %s
ORDER BY module.time DESC LIMIT 1;
]]

local get_all_module_ids = [[
SELECT CAST (module.code AS REAL),
       CAST (module.project AS REAL)
FROM module
WHERE module.name = %s
ORDER BY module.time DESC;
]]

local get_latest_module_bytecode = [[
SELECT code.binary FROM code
WHERE code.code_id = %d ;
]]



local get_code_id_for_module_project = [[
SELECT
   CAST (module.code_id AS REAL) FROM module
WHERE module.project_id = %d
   AND module.name = %s
ORDER BY module.time DESC LIMIT 1;
]]

local get_bytecode = [[
SELECT code.binary FROM code
WHERE code.code_id = %d ;
]]












local home_dir = os.getenv "HOME"
local bridge_modules = os.getenv "BRIDGE_MODULES"

if not bridge_modules then
   local xdg_data_home = os.getenv "XDG_DATA_HOME"
   if xdg_data_home then
      Dir(xdg_data_home .. "/bridge/") : mkdir()
      bridge_modules = xdg_data_home .. "/bridge/bridge.modules"
   else
      -- build the whole shebang from scratch, just in case;
      -- =mkdir= runs =exists= as the first command so this is
      -- harmless
      Dir(home_dir .. "/.local") : mkdir()
      Dir(home_dir .. "/.local/share") : mkdir()
      Dir(home_dir .. "/.local/share/bridge/") : mkdir()
      bridge_modules = home_dir .. "/.local/share/bridge/bridge.modules"
      -- error out if we haven't made the directory
      local bridge_dir = Dir(home_dir .. "/.local/share/bridge/")
      if not bridge_dir:exists() then
         error ("Could not create ~/.local/share/bridge/," ..
               "consider defining $BRIDGE_MODULES")
      end
   end
end







function Database.open()
   local new = not (File(bridge_modules) : exists())
   if new then
      s:verb"creating new bridge.modules"
   end
   local conn = sql.open(bridge_modules)
   conn.pragma.foreign_keys(true)
   if new then
      conn:exec(create_version_table)
      conn:exec(create_project_table)
      conn:exec(create_code_table)
      conn:exec(create_module_table)
   end
   return conn
end












local unwrapKey, toRow = sqltools.unwrapKey, sqltools.toRow

local function commitModule(conn, bytecode, project_id, version_id, git_info)
   -- upsert code.binary and code.hash
   conn:prepare(new_code):bindkv(bytecode):step()
   -- select code_id
   local code_id = unwrapKey(conn:exec(
                                        sql.format(get_code_id_by_hash,
                                                   bytecode.hash)))
   s:verb("code ID is " .. code_id)
   s:verb("module name is " .. bytecode.name)
   if not code_id then
      error("code_id not found for " .. bytecode.name)
   end
   local mod = { name = bytecode.name,
                 project = project_id,
                 code = code_id,
                 snapshot = version_id,
                 version = version_id }
   if git_info.is_repo then
      mod.vc_hash = git_info.commit_hash
      mod.branch  = git_info.branch
   end
   conn:prepare(add_module):bindkv(mod):step()
end

Database.commitModule = commitModule






local function _newProject(conn, project)
   assert(project.name, "project must have a name")
   project.repo = project.repo or ""
   project.repo_alternates = project.repo_alternates or ""
   project.home = project.home or ""
   project.website = project.website or ""
   conn:prepare(new_project):bindkv(project):step()
   return true
end






local insert = assert(table.insert)
local function _updateProjectInfo(conn, db_project, codex_project)
   -- determine if we need to do this
   local update = false
   for k, v in pairs(codex_project) do
      if db_project[k] ~= v then
         update = true
      end
   end
   if update then
      local stmt = {update_project_head}
      for k, v in pairs(codex_project) do
         if update_project_params[k] then
            insert(stmt, sql.format(update_project_params[k], v))
            insert(stmt, ",\n")
         end
      end
      -- drop final comma
      table.remove(stmt)
      insert(stmt, "\n")
      insert(stmt, sql.format(update_project_foot, db_project.name))
      stmt = table.concat(stmt)
      conn:exec(stmt)
   end
end






function Database.commitCodex(conn, codex)
   -- begin transaction
   conn:exec "BEGIN TRANSACTION;"
   -- if we don't have a specific version, make a snapshot:
   local version_id
   if not codex.version then
      version_id = unwrapKey(conn:exec(get_snapshot_version))
      if not version_id then
         conn : prepare(new_version_snapshot) : bindkv { edition = "SNAPSHOT",
                                                         version = version_id }
              : step()
         version_id = unwrapKey(conn:exec(get_snapshot_version))
         if not version_id then
            error "didn't make a SNAPSHOT"
         end
      end
   else
      -- Add a version insert here
   end
   -- upsert project
   -- select project_id
   local project_info = conn:exec(sql.format(get_project, codex.project))
   project_info = toRow(project_info)
   local project_id = project_info.project_id
   if project_id then
      s:verb("project_id is " .. project_id)
      _updateProjectInfo(conn, project_info, codex:projectInfo())
   else
      _newProject(conn, codex:projectInfo())
      project_id = unwrapKey(conn:exec(get_proj))
      if not project_id then
         error ("failed to create project " .. codex.project)
      end
   end
   -- This for now will just
   s:verb("version_id is " .. version_id)
   for _, bytecode in pairs(codex.bytecodes) do
      commitModule(conn, bytecode, project_id, version_id, codex.git_info)
   end
   -- commit transaction
   conn:exec "COMMIT;"
   return conn
end




return Database
