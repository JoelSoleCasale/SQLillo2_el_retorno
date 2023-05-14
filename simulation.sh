#!/bin/bash

N=20
DUMMY="files/dummy.lua"
PREV_VER="files/dodger.lua files/move_and_attack.lua files/move_with_dash.lua files/test_joel.lua"
COMMAND="docker run -v $(pwd)/files:/files --rm -it tarasyarema/sqlillo"

FILE_ARGUMENTS="files/def1_linearShoot.lua"
M=2 # number of previous versions
for ((i=1; i<=$M; i++))
do
    FILE_ARGUMENTS+=" $PREV_VER"
done

# Generate the repeated file arguments
for ((i=1; i<=$N; i++))
do
    FILE_ARGUMENTS+=" $DUMMY"
done

# Run the Docker command
eval "$COMMAND $FILE_ARGUMENTS"
