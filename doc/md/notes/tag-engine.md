# Tag Engine


The tag engine is how we control custom behavior in Orb.


## Mechanism

We use a ``stator``, which is passed through all the documents down to the
smallest element during any ``knit`` or ``weave`` operation.


The rule is that a ``#Capital`` tag is inherited by everything underneath it,
while a ``#miniscule`` tag applies to the block which is tagged.


Determining what that block is, is moderately complex; it uses the cling rule,
such that a miniscule tag right under a header applies to that entire level,
but **not** to levels underneath it.


The basic algorithm for this is to create a new table for each step of a
traversal, and use a table on the ``stator`` to determine if a given attribute
still applies.


If not, we define that tag before proceeding as, e.g. ``state.todo = false``.


This means further redefinitions will get put where they belong, in the
latest stator table, and will be discarded when we exit that step of the
traversal.
