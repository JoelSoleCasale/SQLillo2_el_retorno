#!/bin/bash

N=20
FILE="files/dummy_move.lua"
COMMAND="docker run -v $(pwd)/files:/files --rm -it tarasyarema/sqlillo"

# Generate the repeated file arguments
FILE_ARGUMENTS=""
for ((i=1; i<=$N; i++))
do
    FILE_ARGUMENTS+=" $FILE"
done

# Run the Docker command
eval "$COMMAND $FILE_ARGUMENTS"
