# Concordance

  This contains the SQLite for a **concordance**, which is in essence the
co-product of a ``Doc``.

## SQL for concordance

This file is being handled specially since we lack both transclusion and a way
to handle non-Lua languages in the ``knit`` phase.


The luajit script to translate this to [[concordance.orb]
[@concordance/concordance]] is found at [[sql-strip.lua]
[@/etc/sql-strip.lua]].

### codepoint

This decribes an ``ortho`` codepoint in ``utf`` space.


Since this descends from Unicode and will stay compatible with that,
it defines a version, so a given codepoint is not unique except within a
version.


Orb documents will be in ``utf``, no exceptions, but ``ggg`` is in ``Latin-1``
encoding, which is quite different.

```sql
CREATE TABLE IF NOT EXISTS codepoint (
   codepoint_id INTEGER PRIMARY KEY AUTOINCREMENT,
   codevalue NOT NULL,
   utf INTEGER default 1,
   category STRING NOT NULL DEFAULT 'utf',
   version STRING UNIQUE NOT NULL,
   destription STRING NOT NULL,
   FOREIGN KEY version
      REFERENCES versin (version_ID)
);
```

- Schema fields :


   - codepoint_id :  Primary key for codepoint.
                     Note that this includes more code schemes than just
                     ``utf``, we intend to represent e.g. ``EBCDIC`` and =Latin-1.


   - codevalue    :  Exact numeric value of a given codepoint.


   - utf          :  Boolean identifying a codepoint as ``utf`` or otherwise.


   - category     :  This is the actual codepoint category and ``utf`` is the
                     default.


   - description  :  Somewhat of a misnomer, this is a unique string that
                     defines the codepoint.  In ``utf`` an example would be
                     «∞ INFINITY utf: U+221E, utf: E2 88 9E».


                     Note the use of double guillemets: «», they are required.


                     Latin-1 would say something like
                     «¬ NOT SIGN Latin-1: etc» but the not sign and
                     description would all be Latin-1, not ``utf``.


   - version      :  Foreign key to a ``version`` table. Not sure we actually
                     need this come to think of it.


### codepoint_in

This defines the placement of a codepoint within a single ``document``, another
table we'll get to later.

```sql
CREATE TABLE IF NOT EXISTS codepoint_in (
   codepoint_in_id INTEGER PRIMARY KEY AUTOINCREMENT,
   codepoint UNIQUE NOT NULL,
   document UNIQUE, NOT NULL,
   disp INTEGER NOT NULL,
   wid INTEGER NOT NULL DEFAULT 1,
   line_num INTEGER NOT NULL,
   col_num INTEGER NOT NULL,
   FOREIGN KEY codepoint
      REFERENCES codepoint (codepoint_id),
   FOREGN KEY document
      REFERENCES document (document_id),
```

- Schema fields


   - codepoint :  The codepoint in question


   - document  :  Doccument foreign key to one version of a document.


   - disp      :  Number of bytes into the document where the codepoint is
                  found.


   - wid       :  Width of the codepoint in bytes.


   - line_num  :  Number of lines into the document.


   - col_num   :  Number of columns into the document.


### word

```sql
CREATE TABLE IF NOT EXISTS word (
   word_id INTEGER PRIMARY KEY AUTOINCREMENT,
   word UNIQUE NOT NULL ON CONFLICT DO NOTHING,
   -- JSON array of codepoint_ids
   spelling BLOB NOT NULL ON CONFLICT DO NOTHING,
   thesaurus INTEGER
   FOREIGN KEY thesaurus
      REFERENCES thesaurus (thesaurus_id)
);
```
### word_in

```sql
CREATE TABLE IF NOT EXISTS word_in (
   word_in_id INTEGER PRIMARY KEY AUTOINCREMENT,
   word UNIQUE NOT NULL,
   document UNIQUE, NOT NULL,
   disp INTEGER NOT NULL,
   wid INTEGER NOT NULL DEFAULT 1,
   line_num INTEGER NOT NULL,
   col_num INTEGER NOT NULL,
   FOREIGN KEY word
      REFERENCES word (word_id),
   FOREGN KEY document
      REFERENCES document (document_id),
```
### phrase

Unlike ``word`` there's no good or linear algorithm for phrase recognition,
populating this is a matter of natural languag processing and making these
concordances is moderately expensive and should be saved for editions rather
than just any orb run.


### phrase_in


### line

### line_in

### sentence

### sentence_in


### block


### block_in

### section

### section_in

