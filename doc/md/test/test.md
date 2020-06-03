# Test


``test`` is an Orb verb which runs tests.


They are performed in this order: first ``check`` is executed for each
instantiated class which has it (this entails running the code) and
then, ``session`` is run using ``femto``.  This entails running the code a
second time.


For ease of use, each project with ``check``ed classes should have a ``/check/``
directory, containing the entry point ``/check/check.orb``.


This needs to setup and execute all checks on the class, and then print a
report.


Things like level of detail are setup in building the ``check`` instance.


After this, presuming no red flags (which short-circuits out to the command
line with ``os.exit(n)`` where ``n`` is the number of failures), we run
``session``.


``session`` is unwritten but it is a series of named call-and-response tests
executed at the REPL; each ``session`` preserves no state, which given our
strict state management can be accomplished by putting each session in its own
``_G``.


We can think of ``check`` as the unit tests and ``session`` as the integration
tests, I suppose.  I prefer to think of them as two ways of composing
invariants of the system, complementary in purpose and devastating in their
effect: namely, preventing bugs from creeping back in during refactorings of
various and sundry sorts.
