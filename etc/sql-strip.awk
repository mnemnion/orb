# A Script To Elaborate A Dynamic Database

# Because we don't yet have transclusion, this specialty script captures
# documentation and Orb files written in a specific one-to-one fashion.

# First we have to match a section which is [*}+ [ ] .^
/[*]+/    { print }

# Next, SQLite code blocks, =[#!]+sql= and =[#/]+sql
/#!+sql/  { print }

/#\/+sql/  { print }