#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Need two arguments - path to a file, and a string."
    exit 1
else
    mkdir -p $(dirname "$1")
    echo "$2" >"$1"
fi
