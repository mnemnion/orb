# Blockquote


This is an unusual function metatable, because we need to parse it as though
it doesn't have any `>` characters at the left\.

Then place that parse at the appropriate offset for the actual string, and
make sure that `.str` is the correct document string, while decorating with
the modified string so that we can use appropriate methods for weaving etc\.
without having to work around the `>`\.

\#NYI
