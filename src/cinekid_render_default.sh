#!/usr/bin/env bash

# fail on first error
set -vex

# get filenames from args
base=$1
in_file=$3
tmp=$4

# perform render to tmp file
cp "${in_file}" "${tmp}"
sleep 15
