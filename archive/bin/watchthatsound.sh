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

# watchthatsound

WERKJE=watchthatsound

cd $SRCDIR/$WERKJE		|| error_exit "directory $SRCDIR/$WERKJE does not exist"

for DAY in $(seq $STARTDATE $TODAY); do

		find $DAY -iname '[A-Za-z0-9]*.mov' | while read VIDEO; do

			if [ ! -f "$VIDEO.processing" ]; then

				echo "$WERKJE : $VIDEO"
		
				NAME=$(basename "$VIDEO" | sed -e "s/.mov$//" -e "s/.MOV$//")

				touch "$VIDEO.processing"

				# ( ffmpeg -y -i "$VIDEO" -acodec libfaac -ar 44100 -ab 96k \
				ffmpeg -y -i "$VIDEO" -acodec libfaac -ar 44100 -ab 96k \
					-vcodec libx264 -level 41 -crf 25 -bufsize 20000k -maxrate 25000k \
					-g 250 -coder 1 -flags +loop -cmp +chroma -partitions \
					+parti4x4+partp8x8+partb8x8 -vpre slow \
					-subq 7 -me_range 16 -keyint_min 25 -sc_threshold 40 \
					-i_qfactor 0.71 -rc_eq 'blurCplx^(1-qComp)' -bf 16 -b_strategy 1 \
					-bidir_refine 1 -refs 6 -deblockalpha 0 -deblockbeta 0 -loglevel quiet \
					-b:v 1600k -bt 1600k -threads 0 \
					"$DSTDIR/$WERKJE/$DAY/$NAME.flv" || \
				#	"$DSTDIR/$WERKJE/$DAY/$NAME.flv" 2>/dev/null && \
				# ffmpeg -i "$VIDEO" -ss 00:00:01.0 -vcodec mjpeg -vframes 1 -loglevel quiet \
				#	-f image2 "$DSTDIR/$WERKJE/$DAY/$NAME.jpg" 2>/dev/null ) || \
				( [ -f "$VIDEO.processing" ] && rm "$VIDEO.processing" && \
				error_exit "could not convert $SRCDIR/$WERKJE/$VIDEO" )

			fi
		done

done
