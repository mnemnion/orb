# Compiler#### a note on pronunciation## SQLite table CREATEs### code```sql
CREATE TABLE IF NOT EXISTS code (
   code_id INTEGER PRIMARY KEY AUTOINCREMENT,
   hash TEXT UNIQUE NOT NULL ON CONFLICT DO NOTHING,
   binary BLOB NOT NULL
);
```
### version```sql
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
```
### project```sql
CREATE TABLE IF NOT EXISTS project (
   project_id INTEGER PRIMARY KEY AUTOINCREMENT,
   name STRING UNIQUE NOT NULL ON CONFLICT IGNORE,
   repo STRING,
   repo_type STRING DEFAULT 'git',
   repo_alternates STRING,
   home STRING,
   website STRING
);
```
### module```sql
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
   FOREIGN KEY (project)
      REFERENCES project (project_id)
      ON DELETE RESTRICT
   FOREIGN KEY (code)
      REFERENCES code (code_id)
);
```
### INSERTs#### new project```sql
INSERT INTO project (name, repo, home, website)
VALUES (:name, :repo, :home, :website);
```
#### new version```sql
INSERT INTO version (edition)
VALUES (:edition);
```
#### new code```sql
INSERT INTO code (hash, binary)
VALUES (:hash, :binary);
```
#### add module```sql
INSERT INTO module (snapshot, version, name,
                    branch, vc_hash, project, code)
VALUES (:snapshot, :version, :name, :branch,
        :vc_hash, :project, :code);
```
### SELECTS#### get snapshot version```sql
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.edition = 'SNAPSHOT';
```
#### get project_id```sql
SELECT (CAST project.project_id AS REAL) FROM project
WHERE project.name = %s;
```
#### get code_id by hash```sql
SELECT (CAST code.code_id AS REAL) FROM code
WHERE code.hash = %s;
```
#### get latest module code_id```sql
SELECT CAST (module.code_id AS REAL) FROM module
WHERE module.project = %d
   AND module.name = %s
ORDER BY module.time DESC LIMIT 1;
```
#### get bare module code_id and project_id```sql
SELECT CAST (module.code AS REAL),
       CAST (module.project AS REAL)
FROM module
WHERE module.name = %s
ORDER BY module.time DESC;
```
#### get latest module bytecode```sql
SELECT code.binary FROM code
WHERE code.code_id = %d ;
```
## Future