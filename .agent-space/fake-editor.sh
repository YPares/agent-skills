#!/usr/bin/env sh

>&2 echo "THE PREVIOUS COMMAND TRIED TO OPEN $* IN AN INTERACTIVE EDITOR"
>&2 echo "This cannot work. Try to see if the command has flags to prevent this"
exit 1
