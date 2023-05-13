#!/bin/bash

N=10
FILE="files/test_joel.lua"
COMMAND="docker run -v $(pwd)/files:/files --rm -it tarasyarema/sqlillo"

# Generate the repeated file arguments
FILE_ARGUMENTS="files/move_with_dash2.lua"
for ((i=1; i<=$N; i++))
do
    FILE_ARGUMENTS+=" $FILE"
done

# Run the Docker command
eval "$COMMAND $FILE_ARGUMENTS"
