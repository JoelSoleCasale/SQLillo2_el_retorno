#!/bin/bash

N=8
FILE="files/dummy.lua"
COMMAND="docker run -v $(pwd)/files:/files --rm -it tarasyarema/sqlillo"

# Generate the repeated file arguments
FILE_ARGUMENTS="files/dodger.lua"
for ((i=1; i<=$N; i++))
do
    FILE_ARGUMENTS+=" $FILE"
done

# Run the Docker command
eval "$COMMAND $FILE_ARGUMENTS | grep ?"
