
















local sql = require "sqlayer"
local Dir = require "walk/directory"

local sha = require "sha3" . sha512

local status = require "status" ()



local Loader = {}











local create_project_table = [[
CREATE TABLE IF NOT EXISTS project (
   project_id INTEGER PRIMARY KEY AUTOINCREMENT,
   name STRING UNIQUE NOT NULL,
   repo STRING,
   repo_type STRING DEFAULT 'git',
   repo_alternates STRING,
   home STRING,
   website STRING
);
]]

local create_code_table = [[
CREATE TABLE IF NOT EXISTS code (
   code_id INTEGER PRIMARY KEY AUTOINCREMENT,
   hash TEXT UNIQUE NOT NULL,
   binary BLOB NOT NULL
);
]]

local create_module_table = [[
CREATE TABLE IF NOT EXISTS module (
   module_id INTEGER PRIMARY KEY AUTOINCREMENT,
   time DATETIME DEFAULT CURRENT_TIMESTAMP,
   snapshot INTEGER DEFAULT 1,
   version STRING DEFAULT 'SNAPSHOT',
   name STRING NOT NULL,
   type STRING DEFAULT 'luaJIT-bytecode',
   branch STRING,
   vc_hash STRING,
   project_id INTEGER NOT NULL,
   code_id INTEGER,
   FOREIGN KEY (project_id)
      REFERENCES project (project_id)
      ON DELETE RESTRICT
   FOREIGN KEY (code_id)
      REFERENCES code (code_id)
);
]]






local new_project = [[
INSERT INTO project (name, repo, home, website, repo_type, repo_alternates)
VALUES (:name, :repo, :home, :website, :repo_type, :repo_alternates);
ON CONFLICT IGNORE;
]]

local new_code = [[
INSERT INTO code (hash, binary)
VALUES (:hash, :binary)
ON CONFLICT IGNORE;
]]

local add_module = [[
INSERT INTO module (snapshot, version, name,
                    branch, vc_hash, project_id, code_id)
VALUES (:snapshot, :version, :name, :branch, :vc_hash, :project_id, :code_id);
]]

local get_project_id = [[
SELECT CAST (project.project_id AS REAL) FROM project
WHERE project.name = %s;
]]

local get_code_id_by_hash = [[
SELECT CAST (code.code_id AS REAL) FROM code
WHERE code.hash = %s;
]]

local get_latest_module_code_id = [[
SELECT CAST (module.code_id AS REAL) FROM module
WHERE module.project_id = %d
   AND module.name = %s
ORDER BY module.time DESC LIMIT 1;
]]

local get_latest_module_bytecode = [[
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
      -- build the whole shebang from scratch, just in case
      -- =mkdir= runs =exists= as the first command so this is
      -- sufficiently clear
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









local function _unwrapForeignKey(result)
   if result and result[1] and result[1][1] then
      return result[1][1]
   else
      return nil
   end
end








function Loader.load()
   local new = not (File(bridge_modules) : exists())
   if new then
      print "creating new bridge.modules"
   end
   local conn = sql.open(bridge_modules)
   -- #todo: turn on foreign_keys pragma when we add sqlayer
   if new then
      conn:exec(create_project_table)
      conn:exec(create_code_table)
      conn:exec(create_module_table)
   end
   return conn
end








function Loader.commitModule(conn, bytecode, deck)
   local get_proj = sql.format(get_project_id, deck.codex.project)
   local project_id = _unwrapForeignKey(conn:exec(get_proj))
end







function Loader.commitDeck(conn, deck)
   -- begin transaction
   conn:exec "BEGIN TRANSACTION;"
   -- upsert project
   -- select project_id
   for name, bytecode in pairs(deck.bytecodes) do
      -- upsert code.binary and code.hash
      -- select code_id
      -- upsert module
   end
   -- commit transaction
   conn:exec "COMMIT;"
   -- return conn
end




return Loader
