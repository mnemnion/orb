# Links


The basic syntax of a link is straightforward: ``[[description][link]]``,
although there are many variations, based on ``org-mode``.


Here are some Orb distinction link syntaxes.


### httk://

This is a ``#todo``, a promise that a link needs to be resolved.


``orb publish`` will warn against these and replace them with
``https://example.com`` if the warning is ignored.

## @

The character ``@`` refers to the current document.


## ~, ~~

``~`` is the ``orb`` directory, while ``~~`` is the root codex.


So ``~/doc`` and ``~~/orb/doc`` are equivalent, the ``.orb`` extension is never
needed though anything else needs an extension.

## #

``#`` refers to a section, and is resolved in the exact same way as Markdown.
