








local Dir = require "orb:walk/directory"
local File = require "orb:walk/file"
local s = require "singletons/status"

local unwrapKey, toRow = sql.unwrapKey, sql.toRow



local database = {}











local create_project_table = [[
CREATE TABLE IF NOT EXISTS project (
   project_id INTEGER PRIMARY KEY,
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
   version_id INTEGER PRIMARY KEY,
   stage STRING DEFAULT 'SNAPSHOT' COLLATE NOCASE,
   edition STRING default '',
   special STRING DEFAULT 'no' COLLATE NOCASE,
   major INTEGER DEFAULT 0,
   minor INTEGER DEFAULT 0,
   patch INTEGER DEFAULT 0,
   project INTEGER NOT NULL,
   UNIQUE (project, stage, edition, special, major, minor, patch)
      ON CONFLICT IGNORE,
   FOREIGN KEY (project)
      REFERENCES project (project_id)
);
]]






local create_bundle_table = [[
CREATE TABLE IF NOT EXISTS bundle (
   bundle_id INTEGER PRIMARY KEY,
   time DATETIME DEFAULT CURRENT_TIMESTAMP,
   project INTEGER NOT NULL,
   version INTEGER NOT NULL,
   FOREIGN KEY (project)
      REFERENCES project (project_id)
   FOREIGN KEY (version)
      REFERENCES version (version_id)
);
]]






local create_code_table = [[
CREATE TABLE IF NOT EXISTS code (
   code_id INTEGER PRIMARY KEY,
   hash TEXT UNIQUE ON CONFLICT IGNORE NOT NULL,
   binary BLOB NOT NULL
);
]]






local create_module_table = [[
CREATE TABLE IF NOT EXISTS module (
   module_id INTEGER PRIMARY KEY,
   time DATETIME DEFAULT CURRENT_TIMESTAMP,
   name STRING NOT NULL,
   type STRING DEFAULT 'luaJIT-2.1-bytecode',
   branch STRING,
   vc_hash STRING,
   project INTEGER NOT NULL,
   version INTEGER NOT NULL,
   bundle INTEGER,
   code INTEGER NOT NULL,
   FOREIGN KEY (project)
      REFERENCES project (project_id)
      ON DELETE RESTRICT
   FOREIGN KEY (version)
      REFERENCES version (version_id)
   FOREIGN KEY (bundle)
      REFERENCES bundle (bundle_id)
      ON DELETE CASCADE
   FOREIGN KEY (code)
      REFERENCES code (code_id)
);
]]









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
WHERE version.edition = :edition
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





















local function _module_path()
   local home_dir = os.getenv "HOME"
   local bridge_modules = os.getenv "BRIDGE_MODULES"
   if bridge_modules then
      return bridge_modules
   end
   local bridge_home = os.getenv "BRIDGE_HOME"
   if bridge_home then
      return bridge_home .. "/bridge.modules"
   end
   local xdg_data_home = os.getenv "XDG_DATA_HOME"
   if xdg_data_home then
      Dir(xdg_data_home .. "/bridge/") : mkdir()
      return xdg_data_home .. "/bridge/bridge.modules"
   end
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
   return bridge_modules
end

database.module_path = _module_path






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



local toRow = assert(sql.toRow)

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
              { edition = "SNAPSHOT",
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
   end
   s:verb("version_id is " .. version_id)
   return version_id
end








function database.open()
   local mod_path = _module_path()
   local new = not (File(mod_path) : exists())
   if new then
      s:verb"creating new bridge.modules"
   end
   local conn = sql.open(mod_path)
   --conn.pragma.foreign_keys(true)
   conn.pragma.journal_mode "wal"
   if new then
      conn:exec(create_version_table)
      conn:exec(create_project_table)
      conn:exec(create_code_table)
      conn:exec(create_module_table)
      conn:exec(create_bundle_table)
   end
   return conn
end




return database
