# Maki roll


A small purring tamagotcha hwitch follows Sam-sama around about,


Capturing captivating traces,


of fossil,


& git


.


<3


.


## Rationale

The careful squirrel leaves nuts where decoy nuts are not when no one is
looking.


Programmers, otoh...


commit, instead.


Then,


talk about it during standup.


### Implementation.

When in the course of living Events,


It becomes Necessary,


for the Butlers to Become Robotic,


&


Whereas,


I,

@man,
Being of Sound Mind and Body,


The Rest,


Being,


None Of Your Beeswax,


Doth,


do declare,


that:



I AM


CAPABLE


&


WILLING


& EAGER, EVEN


2


FLOSSurate,


that is,


gratis,


hax0rz there fromme.



**TAKE THY STANDUPS PRONE IF THOU BEEIST TIRED!!!**


#### A useful bit of SQLite fancy

This sequence will extract a timeline from fossil repos.


For git repos, we're going to have to do dumb stuff.


So we're mocking it up in Python, the official language of doing dumb stuff.

```sql
SELECT
  blob.rid AS rid,
  uuid,
  datetime(event.mtime,toLocal()) AS mDateTime,
  coalesce(ecomment,comment)
    || ' (user: ' || coalesce(euser,user,'?')
    || (SELECT case when length(x)>0 then ' tags: ' || x else '' end
          FROM (SELECT group_concat(substr(tagname,5), ', ') AS x
                  FROM tag, tagxref
                 WHERE tagname GLOB 'sym-*' AND tag.tagid=tagxref.tagid
                   AND tagxref.rid=blob.rid AND tagxref.tagtype>0))
    || ')' as comment,
  (SELECT count(*) FROM plink WHERE pid=blob.rid AND isprim)
       AS primPlinkCount,
  (SELECT count(*) FROM plink WHERE cid=blob.rid) AS plinkCount,
  event.mtime AS mtime,
  tagxref.value AS branch
FROM tag CROSS JOIN event CROSS JOIN blob
     LEFT JOIN tagxref ON tagxref.tagid=tag.tagid
  AND tagxref.tagtype>0
  AND tagxref.rid=blob.rid
WHERE blob.rid=event.objid
  AND tag.tagname='branch'

  AND event.mtime <= (SELECT datetime('now'))
ORDER BY event.mtime DESC
```
## Implementation

...let's not get, say, wayyyy ahead of ourselves or anything.

```lua
local Maki = meta {}
local _s = require "status"
local ss = require "singletons"
```
##### fin

```lua
return Maki
```
