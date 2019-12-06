








local Dir = require "orb:walk/directory"
local File = require "orb:walk/file"



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
   edition STRING DEFAULT 'SNAPSHOT' COLLATE NOCASE,
   major INTEGER DEFAULT 0,
   minor INTEGER DEFAULT 0,
   patch STRING DEFAULT '0',
   project INTEGER NOT NULL,
   UNIQUE(project, edition, major, minor, patch) ON CONFLICT IGNORE,
   FOREIGN KEY (project)
      REFERENCES project (project_id)
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
   FOREIGN KEY (project)
      REFERENCES project (project_id)
      ON DELETE RESTRICT
   FOREIGN KEY (code)
      REFERENCES code (code_id)
);
]]












local function _module_path()
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
   return bridge_modules
end

database.module_path = _module_path








function database.open()
   local mod_path = _module_path()
   local new = not (File(mod_path) : exists())
   if new then
      s:verb"creating new bridge.modules"
   end
   local conn = sql.open(mod_path)
   conn.pragma.foreign_keys(true)
   if new then
      conn:exec(create_version_table)
      conn:exec(create_project_table)
      conn:exec(create_code_table)
      conn:exec(create_module_table)
   end
   return conn
end




return database
