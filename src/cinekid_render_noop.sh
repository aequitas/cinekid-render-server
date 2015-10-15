#!/usr/bin/env bash

# renderer which doesn't perform a render

# fail on first error
set -vex

# get filenames from args
base=$1
in_file=$3
tmp=$4
injpg=$6
tmpjpg=$7

# do not render file, but hardlink to output directory
ln -f "${in_file}" "${tmp}"

ln -f "${injpg}" "${tmpjpg}"
