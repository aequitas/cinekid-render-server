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

echo "starting video conversion"

/usr/bin/avconv -y -i "${in_file}" \
  -acodec aac \
  -strict experimental \
  -ar 44100 \
  -ab 96k \
  -vcodec libx264 \
  -maxrate:v 15000k \
  -bufsize:v 30000k \
  -threads 0 \
  "${tmp}"

echo "finished video conversion"

echo "starting generating jpg at 5 seconds"
/usr/bin/avconv -i "${in_file}" -ss 00:00:05.0 \
    -vcodec mjpeg -vframes 1 -f image2 "${tmpjpg}"
if test -f "${tmpjpg}";then
    echo "finished generating jpg at 5 second"
else
    echo "failed generating jpg at 5 seconds (video to short?)"
    echo "starting generating jpg at 0 seconds"
    /usr/bin/avconv -i "${in_file}" -ss 00:00:00.0 -vcodec mjpeg -vframes 1 -f image2 "${tmpjpg}"
    if test -f "${tmpjpg}";then
        echo "finished generating jpg at 0 second"
    else
        echo "failed to generate jpg at 1 second or 5 seconds"
    fi
fi
