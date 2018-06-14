#!/bin/sh
here=$(pwd)

# replace the below with your directory of choice
cd ~/code/orb/src/

br orb "$here" "$@"

exit_state=$?

cd "$here"

exit "$exit_state"
