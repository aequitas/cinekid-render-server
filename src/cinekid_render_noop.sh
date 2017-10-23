#!/usr/bin/env bash

# renderer which doesn't perform a render

# fail on first error
set -vex

# get filenames from args
in_file=$3
tmp=$4
injpg=$6
tmpjpg=$7

if ! test -f "${tmpjpg}"; then
  echo "Missing jpg thumbnail ${tmpjpg} for file ${in_file}!"
fi

# do not render file, but hardlink to output directory
ln -f "${in_file}" "${tmp}"

if test -f "${tmpjpg}"; then
  ln -f "${injpg}" "${tmpjpg}"
fi
