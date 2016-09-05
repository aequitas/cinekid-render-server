#!/usr/bin/env bash

# fail on first error
set -vex

# get filenames from args
in_file=$3
tmp=$4
tmpjpg=$7

# perform render to tmp file
# -y overwrite output
# -i input filenames
# -acodec libfaac force codec
# -ar 44100 audio sample rate
# -ab ???
# -vcodec force video codec

avconv -y -i "${in_file}" -ar 44100 -ab 96k -b:v 1600k -bt 1600k \
    -deblock 0:0 -bufsize 20000k -maxrate 25000k -threads 0 \
    "${tmp}"

/usr/bin/avconv -i "${in_file}" -ss 00:00:10.0 -vcodec mjpeg -vframes 1 -f image2 "${tmpjpg}"
