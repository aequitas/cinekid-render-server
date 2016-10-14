#!/usr/bin/env bash

# renderer which doesn't perform a render, copy png file and generate jpg thumbnail

# fail on first error
set -vex

# get filenames from args
in_file=$3
tmp=$4
injpg=$6
tmpjpg=$7

if ! test -f "${injpg}"; then
  echo "Missing jpg thumbnail ${injpg} for file ${in_file}!"
fi

# do not render file, but hardlink to output directory
ln -f "${in_file}" "${tmp}"

# generate jpg from png
convert "${in_file}" "${tmpjpg}"
