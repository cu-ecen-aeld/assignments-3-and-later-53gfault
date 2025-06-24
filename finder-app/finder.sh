#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Need two arguments - path to a directory, and a string."
    exit 1
elif [ ! -d "$1" ]; then
    echo "First argument has to be a path to a directory on the filesystem."
    exit 1
else
    NUM_FILES=$(find "$1" -type f | wc -l)
    NUM_MATCHES=$(grep -rn "$1" -e "$2" | wc -l)
    echo "The number of files are $NUM_FILES and the number of matching lines are $NUM_MATCHES"
fi
