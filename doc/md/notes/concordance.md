# Concordance## SQL for concordance### codepoint```sql
CREATE TABLE IF NOT EXISTS codepoint (
   codepoint_id INTEGER PRIMARY KEY AUTOINCREMENT,
   codevalue NOT NULL,
   utf INTEGER default 1,
   category STRING NOT NULL DEFAULT 'utf',
   version STRING NOT NULL DEFAULT 'official',
   destription STRING NOT NULL,
);
```
### codepoint_in```sql
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
```
### word```sql
CREATE TABLE IF NOT EXISTS word (
   word_id INTEGER PRIMARY KEY AUTOINCREMENT,
   word STRING UNIQUE NOT NULL ON CONFLICT DO NOTHING,
   -- JSON array of codepoint_ids
   spelling BLOB NOT NULL ON CONFLICT DO NOTHING,
   thesaurus INTEGER,
   FOREIGN KEY thesaurus
      REFERENCES thesaurus (thesaurus_id)
);
```
### word_in```sql
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
```
### phrase### phrase_in### line### line_in### sentence### sentence_in### block### block_in### section### section_in