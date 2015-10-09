#!/usr/bin/env bash

# get renderer name from first arg, and strip it from args list
renderer=$1
shift

# get filenames from remaining args
base=$1
lock=$2
in_file=$3
tmp=$4
out=$5

jpg=${out/%.mp4/.jpg}

now=$(date +%s)

logfile=${base}/logs/${in_file//[^0-9a-zA-Z]/_}.${now}.log
echo "logging to: ${logfile}" 1>&2

# redirect output log logfile
exec > ${logfile} 2>&1

# fail on first error
set -vex

echo "starting conversion"

# start specified renderer with remaining args
/usr/local/bin/cinekid_render_${renderer}.sh "$1" "$2" "$3" "$4" "$5"

# check if tmp output file has been created
test -f "${tmp}"

echo "finished conversion"

echo "starting generating jpg"
avconv -i "${in_file}" -ss 00:00:10.0 -vcodec mjpeg -vframes 1 -loglevel error -f image2 "${jpg}"
echo "finished generating jpg"

mv "${tmp}" "${out}"

rm "${lock}"
