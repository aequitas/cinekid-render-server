#!/usr/bin/env bash

# renderer which doesn't perform a render

# fail on first error
set -vex

# get filenames from args
base=$1
in_file=$3
tmp=$4

# perform render to tmp file
cp "${in_file}" "${tmp}"
