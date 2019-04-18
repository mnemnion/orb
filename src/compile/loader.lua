















local sql = require "sqlite"
local Dir = require "walk/directory"



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
   commit STRING,
   project INTEGER NOT NULL,
   code INTEGER,
   FOREIGN KEY (project)
      REFERENCES project (project_id)
      ON DELETE RESTRICT
   FOREIGN KEY (code)
      REFERENCES code (code_id)
);
]]








local home_dir = os.getenv "HOME"
local bridge_modules = os.getenv "BRIDGE_MODULES"

if not bridge_modules then
   local xdg_data_home = os.getenv "XDG_DATA_HOME"
   if xdg_data_home then
      Dir(xdg_data_home .. "/bridge/") : mkdir()
      bridge_modules = xdg_data_home "/bridge/bridge.modules"
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








function Loader.load()

end




return Loader
