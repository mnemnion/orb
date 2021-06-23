# Concordance

  This contains the SQLite for a **concordance**, which is in essence the
co\-product of a `Doc`\.

This describes two distinct `SQLite` databases, one held in common throughout
`bridge` and another which is personal and depends on the documents on the
computer in question\.

These are merged and queried in common, so the schema are interleaved\.  The
basic distinction is that `table` is in `bridge.cyclopedia`, and `table_in`
is in `bridge.concordance`\.


## SQL for concordance

This file is being handled specially since we lack both transclusion and a way
to handle non\-Lua languages in the `knit` phase\.

The luajit script to translate this to [concordance.orb](~/concordance/concordance) is found at [sql-strip.lua](~~/etc/sql-strip.lua)\.

### codepoint

This decribes an `ortho` codepoint in `utf` space\.

Since this descends from Unicode and will stay compatible with that,
it defines a version, so a given codepoint is not unique except within a
version\.

Orb documents will be in `utf`, no exceptions, but `ggg` is in `Latin-1`
encoding, which is quite different\.

```lua
local create_codepoint = [[
CREATE TABLE IF NOT EXISTS codepoint (
   codepoint_id INTEGER PRIMARY KEY AUTOINCREMENT,
   codevalue NOT NULL,
   utf INTEGER default 1,
   category STRING NOT NULL DEFAULT 'utf',
   version STRING NOT NULL DEFAULT 'official',
   destription STRING NOT NULL,
);
]]
```


- Schema fields :

   - codepoint\_id :  Primary key for codepoint\.
       Note that this includes more code schemes than just
       `utf`, we intend to represent e\.g\. `EBCDIC` and =Latin\-1\.

   - codevalue    :  Exact numeric value of a given codepoint\.

   - utf          :  Boolean identifying a codepoint as `utf` or otherwise\.

   - category     :  This is the actual codepoint category and `utf` is the
       default\.

   - version      :  Some schema come with versions, many do not\. Example, the
       code for 'a' in ASCII/utf will never change, so that
       version is 'official'\.

   - description  :  Somewhat of a misnomer, this is a unique string that
       defines the codepoint\.  In `utf` an example would be
       «∞ INFINITY utf: U\+221E, utf: E2 88 9E»\. ¶
       Note the use of double guillemets: «»,
       they are required\. ¶
       Latin\-1 would say something like
       «¬ NOT SIGN Latin\-1: etc» but the not sign and
       description would all be Latin\-1, not `utf`\.¶

### codepoint\_in

This defines the placement of a codepoint within a single `document`, another
table we'll get to later\.

```lua
local create_codepoint = [[
CREATE TABLE IF NOT EXISTS codepoint_in (
   codepoint_in_id INTEGER PRIMARY KEY AUTOINCREMENT,
   document UNIQUE, NOT NULL,
   disp INTEGER NOT NULL,
   wid INTEGER NOT NULL DEFAULT 1,
   line_num INTEGER NOT NULL,
   col_num INTEGER NOT NULL,
   codepoint INTEGER NOT NULL,
   doc INTEGER NOT NULL,
   document INTEGER NOT NULL,
   FOREIGN KEY codepoint
      REFERENCES codepoint (codepoint_id),
   FOREIGN KEY document
      REFERENCES document (document_id),
   FOREIGN KEY document
      REFERENCES document (document_id),
]]
```


- Schema fields

   - document  :  Doccument foreign key to one version of a document\.

   - disp      :  Number of bytes into the document where the codepoint is
       found\.

   - wid       :  Width of the codepoint in bytes\.

   - line\_num  :  Number of lines into the document\.

   - col\_num   :  Number of columns into the document\.

   - codepoint :  Foreign key to the codepoint entry\.

   - doc       :  Foreign key to the doc \(revision\)\.

   - document  :  Foreign key to the entire document, all revisions included\.

### word

A `word` is what is says, an entry for a single word\.

Note that this concept is very much differently defined for different
languages, but it's coherent and modular enough to work with them smoothly,
granting that the name itself will be inaccurate when considering, say,
Semitic roots\.

```lua
local create_word = [[
CREATE TABLE IF NOT EXISTS word (
   word_id INTEGER PRIMARY KEY AUTOINCREMENT,
   word STRING UNIQUE NOT NULL ON CONFLICT DO NOTHING,
   -- JSON array of codepoint_ids
   spelling BLOB NOT NULL ON CONFLICT DO NOTHING,
   thesaurus INTEGER,
   FOREIGN KEY thesaurus
      REFERENCES thesaurus (thesaurus_id)
);
]]
```


- Schema fields

   - word : A **string** representing the word\.

   - spelling : JSON array of the numeric codepoints specifying the spelling\.

   - thesaurus :  Key to a thesaurus entry for the word\.
       The thesaurus will have dictionary fields and is intended
       for translation across languages as well as within them\.
       Basically a personal wiktionary\.


word is fairly straightforward to populate as we go, although the exact
rules for what constitutes a word and what punctuation and whitespace vary
somewhat, the differences are well defined by the `utf` standard, wo we merely
 aad new ones as we find them\.


### word\_in

Table representing a single word in a given `Doc`\.

```lua
local create_word = [[
CREATE TABLE IF NOT EXISTS word_in (
   word_in_id INTEGER PRIMARY KEY AUTOINCREMENT,
   word_repr STRING NOT NULL,
   disp INTEGER NOT NULL,
   wid INTEGER NOT NULL DEFAULT 1,
   line_num INTEGER NOT NULL,
   col_num INTEGER NOT NULL,
   word INTEGER,
   doc INTEGER,
   document INTEGER,
   FOREIGN KEY word
      REFERENCES word (word_id),
   FOREIGN KEY doc
      REFERENCE doc (doc_id)
   FOREIGN KEY document
      REFERENCES document (document_id),
]]
```


- Schema fields

   - word\_repr :  A **string** representing the word\.
       Important because we don't consider zebra and zebras two
       different words\.

   - disp      :  Number of bytes into the document where the codepoint is
       found\.

   - wid       :  Width of the codepoint in bytes\.

   - line\_num  :  Number of lines into the document\.

   - col\_num   :  Number of columns into the document\.

   - word      :  Foreign key to the word entry\.

   - doc       :  Foreign key to the doc \(revision\)\.

   - document  :  Foreign key to the entire document, all revisions included\.


This table should be deduplicated between editions of documents to save
storage space; adding one word should cause one line's worth of changes\.


### phrase

Unlike `word` there's no good or linear algorithm for phrase recognition,
populating this is a matter of natural languag processing and making these
concordances is moderately expensive and should be saved for editions rather
than just any orb run\.


### phrase\_in

Lorem ipsum dolor sit amet\.

Lorem ipsum dolor sit amet\.

### line

Starting with `line` these are all part of a personal `bridge.concordance`,
except [section](https://gitlab.com/special-circumstance/orb/-/blob/trunk/doc/md/.md#section), which only uses the section header and can be
used to cross\-reference any two sections with the same name, such as
`Introduction` or `Rationale`\.

### line\_in

### sentence

### sentence\_in


### block


### block\_in

### section

### section\_in
