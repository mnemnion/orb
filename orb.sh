#!/bin/sh
here=$(pwd)

# replace the below with your directory of choice
cd ~/code/orb/src/ 

export LUA_PATH="./?.lua;./?/?.lua;./lib/?.lua;./lib/?/?.lua;./lib/?/src/?.lua;./lib/?/src/?/?.lua;$LUA_PATH"

lua -i orb.lua "$here" "$@"

exit_state=$?

cd "$here"

exit "$exit_state"
