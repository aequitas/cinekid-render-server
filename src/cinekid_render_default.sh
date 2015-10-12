#!/usr/bin/env bash

# fail on first error
set -vex

# get filenames from args
base=$1
in_file=$3
tmp=$4

# perform render to tmp file
# -y overwrite output
# -i input filenames
# -acodec libfaac force codec
# -ar 44100 audio sample rate
# -ab ???
# -vcodec force video codec

/usr/bin/avconv -y -i "${in_file}" -acodec aac -strict experimental -ar 44100 -ab 96k \
    -vcodec libx264 -b:v 1600k -bt 1600k -threads 0 "${tmp}"
