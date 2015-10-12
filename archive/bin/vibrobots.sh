#!/bin/sh
# This script recursively checks $SRCDIR for new videos and re-encodes them if no other host is already doing it
# 20120926 Maarten te Paske <mtp@renice.nl>

SRCDIR="/srv/samba"
DSTDIR="/srv/results"

STARTDATE="17"		# start of the festival
TODAY=$(date +%d)
# TODAY=19

error_exit() {
	echo "error, $1"
	exit 1
}

[ -x $(which seq) ]		|| error_exit "seq binary does not exist"
[ -x $(which basename) ]	|| error_exit "basename binary does not exist"
[ -x $(which sed) ]		|| error_exit "sed binary does not exist"
[ -x $(which ffmpeg) ]		|| error_exit "ffmpeg binary does not exist"

# ck7: vibrobots
# alleen jpegs

WERKJE=vibrobots

rsync -av $SRCDIR/$WERKJE/ $DSTDIR/$WERKJE/
