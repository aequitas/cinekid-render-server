#!/usr/bin/env bash

# determine files
base=$1
in_file=$2
tmp=$3
out=${4/%.../flv}
jpg=${out/%.flv/.jpg}

now=$(date +%s)

logfile=${base}/logs/${in_file//[^0-9a-zA-Z]/_}.${now}.log
echo "logging to: ${logfile}" 1>&2

# redirect output log logfile
exec > >(tee ${logfile}) 2>&1

# fail on first error
set -vex

echo "starting conversion to flv"

avconv -y -i "${in_file}" -acodec libmp3lame -ar 44100 -ab 96k \
	-vcodec libx264 -level 41 -crf 25 -bufsize 20000k -maxrate 25000k \
	-g 250 -coder 1 -flags +loop -cmp +chroma -partitions \
	+parti4x4+partp8x8+partb8x8 -pre slow \
	-subq 7 -me_range 16 -keyint_min 25 -sc_threshold 40 \
	-i_qfactor 0.71 -rc_eq 'blurCplx^(1-qComp)' -bf 16 -b_strategy 1 \
	-bidir_refine 1 -refs 6 -deblock 0:0 \
	-b:v 1600k -bt 1600k -threads 0 \
	"${tmp}"
echo "finished conversion to flv"

echo "starting generating jpg"
avconv -i "$VIDEO" -ss 00:00:10.0 -vcodec mjpeg -vframes 1 -loglevel debug \
	-f image2 "${jpg}"
echo "finished generating jpg"

mv "${tmp}" "${out}"
