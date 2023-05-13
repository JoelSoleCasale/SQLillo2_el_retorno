#!/bin/bash

N=10
FILE="files/dummy.lua"
COMMAND="docker run -v $(pwd)/files:/files --rm -it tarasyarema/sqlillo"

# Generate the repeated file arguments
FILE_ARGUMENTS="files/test_joel.lua"
for ((i=1; i<=$N; i++))
do
    FILE_ARGUMENTS+=" $FILE"
done

# Run the Docker command
eval "$COMMAND $FILE_ARGUMENTS"
