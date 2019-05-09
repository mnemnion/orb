# loader


I'm less than convinced that I've given this the right name.


Among other things this will have a function for ``package.loaders``, but this
file will contain everything needed to manipulate modules, including things
needed only by the compiler.

### imports

For now, I'm going to use a copy of the sqlite bindings currently living in
``femto``.  There's a ``sqlayer`` as well but I don't want to copy-paste generated
code if I can avoid it; the whole point of this exercise is to get the
codebase to where I can reuse projects across modules.

```lua
local sql = assert(sql, "must have sql in bridge _G")
local Dir = require "walk/directory"

local sha = require "sha3" . sha512

local status = require "status" ()
```
```lua
local Loader = {}
```
### SQL code

Everything we need to create and manipulate the database.


#### SQL Loader.open()

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
      ON DELETE CASCADE
);
]]
```
#### SQL Loader.commitDeck(conn, deck)

```lua
local new_project = [[
INSERT INTO project (name, repo, home, website)
VALUES (:name, :repo, :home, :website)
]]

local new_code = [[
INSERT INTO code (hash, binary)
VALUES (:hash, :binary);
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

local get_all_module_ids = [[
SELECT CAST (module.code_id AS REAL),
       CAST (module.project_id AS REAL)
FROM module
WHERE module.name = %s
ORDER BY module.time DESC;
]]

local get_latest_module_bytecode = [[
SELECT code.binary FROM code
WHERE code.code_id = %d ;
]]
```
### SQL loader.load(conn, mod_name)

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
### Loader.open()

Loads the ``bridge.modules`` database and returns the SQLite connection.

```lua
function Loader.open()
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
```
### Loader.commitModule(conn, bytecode, deck)

Commits a single module and associated bytecode.


It might be smarter to fetch all hashes associated with the project first, and
only commit ones which aren't on the list, but it's definitely easier to just
commit everything and let the ``ON CONFLICT IGNORE`` prevent duplication.

```lua
local function commitModule(conn, bytecode, project_id)
   -- upsert code.binary and code.hash
   conn:prepare(new_code):bindkv(bytecode):step()
   -- select code_id
   local code_id = _unwrapForeignKey(conn:exec(
                                        sql.format(get_code_id_by_hash,
                                                   bytecode.hash)))
   if not code_id then
      error("code_id not found for " .. bytecode.name)
   end
   local mod = { name = bytecode.name,
                    project_id = project_id,
                    code_id = code_id,
                    snapshot = 1,
                    vc_hash = "",
                    version = "SNAPSHOT" }
   conn:prepare(add_module):bindkv(mod):step()
end

Loader.commitModule = commitModule
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
### Loader.commitCodex(conn, codex)

```lua
function Loader.commitCodex(conn, codex)
   -- begin transaction
   conn:exec "BEGIN TRANSACTION;"
   -- upsert project
   -- select project_id
   local get_proj = sql.format(get_project_id, codex.project)
   local project_id = _unwrapForeignKey(conn:exec(get_proj))
   if project_id then
      print ("project_id is " .. project_id)
   else
      _newProject(conn, {name = codex.project})
      project_id = _unwrapForeignKey(conn:exec(get_proj))
      if not project_id then
         error ("failed to create project " .. codex.project)
      end
   end
   for _, bytecode in pairs(codex.bytecodes) do
      commitModule(conn, bytecode, project_id)
   end
   -- commit transaction
   conn:exec "COMMIT;"
   -- let's check Loader.load
   assert(type(Loader.load(conn, "orb:walk/walk")) == "function")
   return conn
end
```
### Loader.load(conn, mod_name)

Load a module given its name and a given database conn.


None of the ``error`` calls in here belong, once I'm confident that the logic
works I'll remove them.

```lua
local match = string.match

local function _loadModule(conn, mod_name)
   assert(type(mod_name) == "string", "mod_name must be a string")
   -- split the module into project and modname
   local project, mod = match(mod_name, "(.*):(.*)")
   if not mod then
      mod = mod_name
   end
   local code_id = nil
   if project then
      -- retrieve module name by project
      local project_id = _unwrapForeignKey(
                            conn:exec(
                            sql.format(get_project_id, project)))
      if not project_id then
         error("project not found in bridge.modules: " .. project)
      end
      code_id = _unwrapForeignKey(
                         conn:exec(
                         sql.format(get_code_id_for_module_project,
                                    project_id, mod)))
   else
      -- retrieve by bare module name
      local foreign_keys = conn:exec(sql.format(get_all_module_ids, mod))
      if foreign_keys == nil then
         error("can't retrieve any modules named " .. mod_name)
      else
         -- iterate through project_ids to check if we have more than one
         -- project with the same module name
         local p_id = foreign_keys[2][1]
         local same_project = true
         for i = 2, #foreign_keys[2] do
            same_project = same_project and p_id == foreign_keys[2][i]
         end
         if not same_project then
            package.warning = package.warning or {}
            table.insert(package.warning,
               "warning: multiple projects contain a module called " .. mod)
         end
         code_id = foreign_keys[1][1]
      end
   end
   if not code_id then
      error("bytecode not found in bridge.modules: " .. mod_name)
   end
   local bytecode = _unwrapForeignKey(
                           conn:exec(
                           sql.format(get_bytecode, code_id)))
   if bytecode then
      return load(bytecode)
   else
      error("no bytecode in " .. mod_name)
   end
end

Loader.load = _loadModule
```
### Loader.loaderGen()

Closes over the conn and returns a loader which can use it.

#Todo for best code hygeine, we should add the equivalent of a =__gc=
exit, and setting this up in LuaJIT is moderately complex, so just going to
punt on this for now.

```lua
function Loader.loaderGen()
   local conn = Loader.open()
   return function(mod_name)
      return _loadModule(conn, mod_name)
   end
end
```
```lua
return Loader
```
