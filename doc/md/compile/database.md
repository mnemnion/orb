# Database


  Database handler for compiling projects.


#### imports

```lua
local s = require "singletons/status"
s.verbose = false
local sql = assert(sql, "must have sql in bridge _G")
local Dir = require "orb:walk/directory"
local File = require "orb:walk/file"

local sha = require "compile/sha2" . sha3_512

local status = require "singletons/status" ()
```
```lua
local Database = {}
```
### SQL code

Everything we need to create and manipulate the database.


#### SQL Database.open()

```lua
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
```
#### local create_code_table

```lua
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
```
#### SQL Database.commitDeck(conn, deck)

```lua
local new_project = [[
INSERT INTO project (name, repo, home, website)
VALUES (:name, :repo, :home, :website)
]]

local new_code = [[
INSERT INTO code (hash, binary)
VALUES (:hash, :binary);
]]

local new_version_snapshot = [[
INSERT INTO version (edition, project)
VALUES (:edition, :project);
]]

local add_module = [[
INSERT INTO module (snapshot, version, name,
                    branch, vc_hash, project, code)
VALUES (:snapshot, :version, :name, :branch,
        :vc_hash, :project, :code);
]]

local get_snapshot_version = [[
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.edition = 'SNAPSHOT';
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
```
```lua
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
```
### Environment Variables

  Following the [XDG Standard](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html),
we place the ``bridge.modules`` database in a place defined first by a user
environment variable, then by ``XDG_DATA_HOME``, and if neither is defined,
attempt to put it in the default location of ``XDG_DATA_HOME``, creating it if
necessary.

```lua
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
```
#### _unwrapForeignKey(result)

Just peeling off layers here.  I realize there are more sophisticated ways to
do almost everything but for now this will get us where we're going.

```lua
local function _unwrapForeignKey(result)
   if result and result[1] and result[1][1] then
      return result[1][1]
   else
      return nil
   end
end
```
### Database.open()

Loads the ``bridge.modules`` database and returns the SQLite connection.

```lua
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
```
### Database.commitModule(conn, bytecode, deck)

Commits a single module and associated bytecode.


It might be smarter to fetch all hashes associated with the project first, and
only commit ones which aren't on the list, but it's definitely easier to just
commit everything and let the ``ON CONFLICT IGNORE`` prevent duplication.

```lua
local function commitModule(conn, bytecode, project_id, version_id)
   -- upsert code.binary and code.hash
   conn:prepare(new_code):bindkv(bytecode):step()
   -- select code_id
   local code_id = _unwrapForeignKey(conn:exec(
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
                    vc_hash = "",
                    version = version_id }
   conn:prepare(add_module):bindkv(mod):step()
end

Database.commitModule = commitModule
```
#### _newProject(conn, project)

```lua
local function _newProject(conn, project)
   assert(project.name, "project must have a name")
   project.repo = project.repo or ""
   project.home = project.home or ""
   project.website = project.website or ""
   conn:prepare(new_project):bindkv(project):step()
   return true
end
```
### Database.commitCodex(conn, codex)

```lua
function Database.commitCodex(conn, codex)
   -- begin transaction
   conn:exec "BEGIN TRANSACTION;"
   -- currently we're only making snapshots, so let's create the
   -- snapshot version if we don't have it.
   local version_id = _unwrapForeignKey(conn:exec(get_snapshot_version))
   if not version_id then
      conn : prepare(new_version_snapshot) : bindkv { edition = "SNAPSHOT",
                                                      version = version_id }
           : step()
      version_id = _unwrapForeignKey(conn:exec(get_snapshot_version))
      if not version_id then
         error "didn't make a SNAPSHOT"
      end
   end
   -- upsert project
   -- select project_id
   local get_proj = sql.format(get_project_id, codex.project)
   local project_id = _unwrapForeignKey(conn:exec(get_proj))
   if project_id then
      s:verb("project_id is " .. project_id)
   else
      _newProject(conn, {name = codex.project})
      project_id = _unwrapForeignKey(conn:exec(get_proj))
      if not project_id then
         error ("failed to create project " .. codex.project)
      end
   end
   -- This for now will just
   s:verb("version_id is " .. version_id)
   for _, bytecode in pairs(codex.bytecodes) do
      commitModule(conn, bytecode, project_id, version_id)
   end
   -- commit transaction
   conn:exec "COMMIT;"
   return conn
end
```
```lua
return Database
```
