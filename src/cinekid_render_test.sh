#!/usr/bin/env bash

# fail on first error
set -vex

# get filenames from args
in_file=$3
tmp=$4
injpg=$6
tmpjpg=$7

# perform render to tmp file
cp "${in_file}" "${tmp}"
cp "${injpg}" "${tmpjpg}"
sleep 15
