# Compiler


I decided awhile back that the best format for storing libraries and
applications is as a SQLite database full of blobs and metadata.


Dependencies in ``bridgetools`` are getting out of control, so it's time to
actually make this happen.


The actual process of compiling is admirably straightforward; we ``load`` a
string, giving it a name, and then use ``string.dump`` to create bytecode of it.


Another invocation of ``load`` turns this back into a function, which we
execute.  Simple as that.


Here I intend to design the database table structure, and continue to flesh
out the full system, while hopefully avoiding my lamentable tendency to
overspecify.


## SQLite tables


### code

  The ``code`` table has a key ``id``, a ``blob`` field ``binary``, and a
``hash`` field.  I think the ``hash`` field should be SHA3, just as a
best-practices sort of thing. As it turns out, after running a test, SHA512 is
substantially faster.  Now, this may or may not be true of SHA512 in pure
LuaJIT, but that's less important.


So we want to open/create with:

```sql
CREATE TABLE IF NOT EXISTS code (
   code_id INTEGER PRIMARY KEY AUTOINCREMENT,
   hash TEXT UNIQUE NOT NULL,
   binary BLOB NOT NULL
);
```

strictly speaking ``blob`` should also be UNIQUE but that's comparatively
expensive to check and guaranteed by the hash.


### module

  The ``modules`` table has all the metadata about a given blob. Let's mock it
up first.

```sql
CREATE TABLE IF NOT EXISTS module (
   module_id INTEGER PRIMARY KEY AUTOINCREMENT,
   time DATETIME DEFAULT CURRENT_TIMESTAMP,
   snapshot INTEGER DEFAULT 1,
   version STRING DEFAULT 'SNAPSHOT',
   name STRING NOT NULL,
   project INTEGER,
   code INTEGER,
   FOREIGN KEY (project)
      REFERENCES project (project_id)
      ON DELETE RESTRICT
   FOREIGN KEY (code)
      REFERENCES code (code_id)
);

Most of this is self-describing. =snapshot= is a boolean, if false this is a
versioned module.  We'll be adding that later, so everything is configured so
that by default we have a snapshot.  =version= is expected to be set to
something if =version= is true.

=name= is the string used to =require= the module, stripped of any project
header.  =name= is not unique except when combined with a =project=, which
is.

=project= is the foreign key to the =project= table, described next.

We don't want to delete any projects which still have modules, so we use
=ON DELETE RESTRICT= to prevent this from succeeding.

=code= is, of course, the key for the actual binary blob and its hash.

Not sure whether to de-normalize the hash, and since I'm not sure, we won't
for now.  It doesn't seem necessary since we'll =JOIN= against the =code=
table in all cases.


*** project

This table describes projects.

Our =require= will, at first, just add a function to =package.loader=.
Additionally we'll use some sort of manifest to resolve dependencies,
but that comes later.

I /think/ the best way to separate fully-qualified from relative module names
is like so: =modname/submod=, =fully.qualified.project:modname/submod=.

Any =fully.qualified.project= needs to be *globally* unique across all bridge
projects.  There has never in the history of ever been a good way to do this.
Having project manifests at least keeps this from leaking into codebases.






```
