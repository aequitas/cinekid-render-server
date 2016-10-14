#!/usr/bin/env bash

base=$2
in_file=$4

# generate logfile name and output before redirecting
now=$(date +%s)
logfile=${base}/logs/${in_file//[^0-9a-zA-Z]/_}.${now}.log
echo "$in_file: logging to: $logfile" 1>&2
# redirect output log logfile
exec 3>&2
exec > "$logfile" 2>&1

function finish {
  echo "$in_file: log last line: $(tail -n6 "$logfile"|head -n1)" 1>&3
}
trap finish EXIT

# fail on first error, print executing command and interpretation of command
set -vex

# get renderer name from first arg, and strip it from args list
renderer=$1
shift

# get filenames from remaining args
base=$1
lock=$2
in_file=$3
tmp=$4
out=$5

injpg=$(echo "$in_file"|sed -E 's/\.....?$/'.jpg/)
tmpjpg=$(echo "$tmp"|sed -E 's/\.....?$/'.jpg/)
jpg=$(echo "$out"|sed -E 's/\.....?$/'.jpg/)

echo "starting conversion"

# start specified renderer with remaining args
"${base}/renderers/cinekid_render_${renderer}.sh" "$1" "$2" "$3" "$4" "$5" "${injpg}" "${tmpjpg}"

# check if tmp output file has been created
test -f "${tmp}"

echo "finished conversion"

mv "${tmpjpg}" "${jpg}"

# make file 'done'
mv "${tmp}" "${out}"

# remove lock status
rm "${lock}"

# done
