# Concordance

## SQL for concordance


***

```sql
CREATE TABLE IF NOT EXISTS codepoint (
   codepoint_id INTEGER PRIMARY KEY AUTOINCREMENT,
   codevalue UNIQUE NOT NULL ON CONFLICT DO NOTHING,
   utf STRING UNIQUE NOT NULL ON CONFLICT DO NOTHING,
   category NOT NULL ON CONFLICT DO NOTHING,
   version STRING UNIQUE NOT NULL,
   destription STRING NOT NULL,
   FOREIGN KEY version REFERENCES (version)
);
```
