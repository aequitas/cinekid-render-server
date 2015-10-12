#!/bin/sh
# This script recursively checks $SRCDIR for new videos and re-encodes them if no other host is already doing it
# 20120926 Maarten te Paske <mtp@renice.nl>

SRCDIR="/srv/samba"
DSTDIR="/srv/results"

STARTDATE="16"		# start of the festival
# TODAY=$(date +%d)
TODAY=25

error_exit() {
	echo "error, $1"
	exit 1
}

[ -x $(which seq) ]		|| error_exit "seq binary does not exist"
[ -x $(which basename) ]	|| error_exit "basename binary does not exist"
[ -x $(which sed) ]		|| error_exit "sed binary does not exist"
[ -x $(which ffmpeg) ]		|| error_exit "ffmpeg binary does not exist"


[ $# -eq "1" ]			|| error_exit "usage: $0 <$SRCDIR/dir_name>"

WERKJE="$1"
[ -d "$SRCDIR/$WERKJE" ] 	|| error_exit "$SRCDIR/$WERKJE does not exist"

process_generic() {
	
	for DAY in $(seq $STARTDATE $TODAY); do

			cd "$SRCDIR/$WERKJE"	
			find $DAY -iname '[a-z0-9]*.mov' -o -iname '[a-z0-9]*.mp4' -o -iname '[a-z0-9]*.avi' -o -iname '[a-z0-9]*.f4v' | while read VIDEO; do
	
				if [ ! -f "$VIDEO.processing" ]; then

					CHANGED=$(stat --printf=%Y "$VIDEO")
					NOW=$(date +%s)
					AGE=$(($NOW - $CHANGED))

					if [ "$AGE" -gt "300" ]; then
	
						echo "$WERKJE : $VIDEO"
			
						NAME=$(basename "$VIDEO" | sed -e "s/.mov$//" -e "s/.MOV$//" -e "s/.mp4$//" -e "s/.MP4$//" -e "s/.avi$//" -e "s/.AVI$//" -e "s/.f4v$//")
		
						touch "$VIDEO.processing"
		
						( ffmpeg -y -i "$VIDEO" -acodec libmp3lame -ar 44100 -ab 96k \
							-vcodec libx264 -level 41 -crf 25 -bufsize 20000k -maxrate 25000k \
							-g 250 -coder 1 -flags +loop -cmp +chroma -partitions \
							+parti4x4+partp8x8+partb8x8 -vpre slow \
							-subq 7 -me_range 16 -keyint_min 25 -sc_threshold 40 \
							-i_qfactor 0.71 -rc_eq 'blurCplx^(1-qComp)' -bf 16 -b_strategy 1 \
							-bidir_refine 1 -refs 6 -deblockalpha 0 -deblockbeta 0 -loglevel quiet \
							-b:v 1600k -bt 1600k -threads 0 \
							"$DSTDIR/$WERKJE/$DAY/$NAME.flv" && \
						ffmpeg -i "$VIDEO" -ss 00:00:10.0 -vcodec mjpeg -vframes 1 -loglevel debug \
							-f image2 "$DSTDIR/$WERKJE/$DAY/$NAME.jpg" ) || \
						( [ ! -s "$DSTDIR/$WERKJE/$DAY/$NAME.flv" ] && rm "$DSTDIR/$WERKJE/$DAY/$NAME.flv"; \
						[ -f "$VIDEO.processing" ] && rm "$VIDEO.processing" && \
						error_exit "could not convert $SRCDIR/$WERKJE/$VIDEO" )

					else

						echo "$VIDEO has been modified in the last 5 minutes, skipping"

					fi
				fi
			done
	done
}

process_ck2_presenteren() {
	
	for DAY in $(seq $STARTDATE $TODAY); do

			cd "$SRCDIR/$WERKJE"	
			# find $DAY -iname '[a-z0-9]*.mov' -o -iname '[a-z0-9]*.mp4' -o -iname '[a-z0-9]*.avi' | while read VIDEO; do
			find $DAY -type f -iname '[a-z0-9]*' ! -name '*processing' | while read VIDEO; do
	
				if [ ! -f "$VIDEO.processing" ]; then

					CHANGED=$(stat --printf=%Y "$VIDEO")
					NOW=$(date +%s)
					AGE=$(($NOW - $CHANGED))

					if [ "$AGE" -gt "300" ] && file "$VIDEO" | grep -q "ISO Media, Apple QuickTime movie"; then
	
						echo "$WERKJE : $VIDEO"
			
						NAME=$(basename "$VIDEO" | sed -e "s/.mov$//" -e "s/.MOV$//" -e "s/.mp4$//" -e "s/.MP4$//" -e "s/.avi$//" -e "s/.AVI$//")
		
						touch "$VIDEO.processing"
		
						( ffmpeg -y -i "$VIDEO" -acodec libmp3lame -ar 44100 -ab 96k \
							-vcodec libx264 -level 41 -crf 25 -bufsize 20000k -maxrate 25000k \
							-g 250 -coder 1 -flags +loop -cmp +chroma -partitions \
							+parti4x4+partp8x8+partb8x8 -vpre slow \
							-subq 7 -me_range 16 -keyint_min 25 -sc_threshold 40 \
							-i_qfactor 0.71 -rc_eq 'blurCplx^(1-qComp)' -bf 16 -b_strategy 1 \
							-bidir_refine 1 -refs 6 -deblockalpha 0 -deblockbeta 0 -loglevel quiet \
							-b:v 1600k -bt 1600k -threads 0 \
							"$DSTDIR/$WERKJE/$DAY/$NAME.flv" && \
						ffmpeg -i "$VIDEO" -ss 00:00:10.0 -vcodec mjpeg -vframes 1 -loglevel quiet \
							-f image2 "$DSTDIR/$WERKJE/$DAY/$NAME.jpg" ) || \
						( [ ! -s "$DSTDIR/$WERKJE/$DAY/$NAME.flv" ] && rm "$DSTDIR/$WERKJE/$DAY/$NAME.flv"; \
						[ -f "$VIDEO.processing" ] && rm "$VIDEO.processing" && \
						error_exit "could not convert $SRCDIR/$WERKJE/$VIDEO" )

					else

						echo "$VIDEO has been modified in the last 5 minutes, skipping"

					fi
				fi
			done
	done
}

process_ck3_sprong() {
	
	for DAY in $(seq $STARTDATE $TODAY); do

			cd "$SRCDIR/$WERKJE"	
			# find $DAY -iname '[a-z0-9]*.mov' -o -iname '[a-z0-9]*.mp4' -o -iname '[a-z0-9]*.avi' | while read VIDEO; do
			find $DAY -type f -iname '[a-z0-9]*' ! -name '*processing' | while read VIDEO; do
	
				if [ ! -f "$VIDEO.processing" ]; then

					CHANGED=$(stat --printf=%Y "$VIDEO")
					NOW=$(date +%s)
					AGE=$(($NOW - $CHANGED))

					if [ "$AGE" -gt "300" ] && file "$VIDEO" | grep -q "ISO Media, Apple QuickTime movie"; then
	
						echo "$WERKJE : $VIDEO"
			
						NAME=$(basename "$VIDEO" | sed -e "s/.mov$//" -e "s/.MOV$//" -e "s/.mp4$//" -e "s/.MP4$//" -e "s/.avi$//" -e "s/.AVI$//")
		
						touch "$VIDEO.processing"
		
						( ffmpeg -y -i "$VIDEO" -acodec libmp3lame -ar 44100 -ab 96k \
							-vcodec libx264 -level 41 -crf 25 -bufsize 20000k -maxrate 25000k \
							-g 250 -coder 1 -flags +loop -cmp +chroma -partitions \
							+parti4x4+partp8x8+partb8x8 -vpre slow \
							-subq 7 -me_range 16 -keyint_min 25 -sc_threshold 40 \
							-i_qfactor 0.71 -rc_eq 'blurCplx^(1-qComp)' -bf 16 -b_strategy 1 \
							-bidir_refine 1 -refs 6 -deblockalpha 0 -deblockbeta 0 -loglevel quiet \
							-b:v 1600k -bt 1600k -threads 0 \
							"$DSTDIR/$WERKJE/$DAY/$NAME.flv" && \
						ffmpeg -i "$VIDEO" -ss 00:00:17.0 -vcodec mjpeg -vframes 1 -loglevel quiet \
							-f image2 "$DSTDIR/$WERKJE/$DAY/$NAME.jpg" ) || \
						( [ ! -s "$DSTDIR/$WERKJE/$DAY/$NAME.flv" ] && rm "$DSTDIR/$WERKJE/$DAY/$NAME.flv"; \
						[ -f "$VIDEO.processing" ] && rm "$VIDEO.processing" && \
						error_exit "could not convert $SRCDIR/$WERKJE/$VIDEO" )

					else

						echo "$VIDEO has been modified in the last 5 minutes, skipping"

					fi
				fi
			done
	done
}

process_ck4_animatieplaats() {
	
	for DAY in $(seq $STARTDATE $TODAY); do

			cd "$SRCDIR/$WERKJE"	
			find $DAY -iname '[a-z0-9]*.mov' -o -iname '[a-z0-9]*.mp4' -o -iname '[a-z0-9]*.avi' | while read VIDEO; do
	
				if [ ! -f "$VIDEO.processing" ]; then

					CHANGED=$(stat --printf=%Y "$VIDEO")
					NOW=$(date +%s)
					AGE=$(($NOW - $CHANGED))

					if [ "$AGE" -gt "300" ]; then
	
						echo "$WERKJE : $VIDEO"
			
						NAME=$(basename "$VIDEO" | sed -e "s/.mov$//" -e "s/.MOV$//" -e "s/.mp4$//" -e "s/.MP4$//" -e "s/.avi$//" -e "s/.AVI$//")
		
						touch "$VIDEO.processing"
		
						( ffmpeg -y -i "$VIDEO" -acodec libmp3lame -ar 44100 -ab 96k \
							-vcodec libx264 -level 41 -crf 25 -bufsize 20000k -maxrate 25000k \
							-g 250 -coder 1 -flags +loop -cmp +chroma -partitions \
							+parti4x4+partp8x8+partb8x8 -vpre slow \
							-subq 7 -me_range 16 -keyint_min 25 -sc_threshold 40 \
							-i_qfactor 0.71 -rc_eq 'blurCplx^(1-qComp)' -bf 16 -b_strategy 1 \
							-bidir_refine 1 -refs 6 -deblockalpha 0 -deblockbeta 0 -loglevel quiet \
							-b:v 1600k -bt 1600k -threads 0 \
							"$DSTDIR/$WERKJE/$DAY/$NAME.flv" && \
						ffmpeg -i "$VIDEO" -ss 00:00:01.0 -vcodec mjpeg -vframes 1 -loglevel quiet \
							-f image2 "$DSTDIR/$WERKJE/$DAY/$NAME.jpg" ) || \
						( [ ! -s "$DSTDIR/$WERKJE/$DAY/$NAME.flv" ] && rm "$DSTDIR/$WERKJE/$DAY/$NAME.flv"; \
						[ -f "$VIDEO.processing" ] && rm "$VIDEO.processing" && \
						error_exit "could not convert $SRCDIR/$WERKJE/$VIDEO" )

					else

						echo "$VIDEO has been modified in the last 5 minutes, skipping"

					fi
				fi
			done
	done
}

process_ck7_tagtool() {
	
	for DAY in $(seq $STARTDATE $TODAY); do

			cd "$SRCDIR/$WERKJE"	
			find $DAY -iname '[a-z0-9]*.mov' -o -iname '[a-z0-9]*.mp4' -o -iname '[a-z0-9]*.avi' | while read VIDEO; do
	
				if [ ! -f "$VIDEO.processing" ]; then

					CHANGED=$(stat --printf=%Y "$VIDEO")
					NOW=$(date +%s)
					AGE=$(($NOW - $CHANGED))

					if [ "$AGE" -gt "300" ]; then
	
						echo "$WERKJE : $VIDEO"
			
						NAME=$(basename "$VIDEO" | sed -e "s/.mov$//" -e "s/.MOV$//" -e "s/.mp4$//" -e "s/.MP4$//" -e "s/.avi$//" -e "s/.AVI$//")
		
						touch "$VIDEO.processing"
		
						( ffmpeg -y -i "$VIDEO" -acodec libmp3lame -ar 44100 -ab 96k \
							-vcodec libx264 -level 41 -crf 25 -bufsize 20000k -maxrate 25000k \
							-g 250 -coder 1 -flags +loop -cmp +chroma -partitions \
							+parti4x4+partp8x8+partb8x8 -vpre slow \
							-subq 7 -me_range 16 -keyint_min 25 -sc_threshold 40 \
							-i_qfactor 0.71 -rc_eq 'blurCplx^(1-qComp)' -bf 16 -b_strategy 1 \
							-bidir_refine 1 -refs 6 -deblockalpha 0 -deblockbeta 0 -loglevel quiet \
							-b:v 1600k -bt 1600k -threads 0 \
							"$DSTDIR/$WERKJE/$DAY/$NAME.flv" && \
						ffmpeg -i "$VIDEO" -ss 00:00:02.0 -vcodec mjpeg -vframes 1 -loglevel quiet \
							-f image2 "$DSTDIR/$WERKJE/$DAY/$NAME.jpg" ) || \
						( [ ! -s "$DSTDIR/$WERKJE/$DAY/$NAME.flv" ] && rm "$DSTDIR/$WERKJE/$DAY/$NAME.flv"; \
						[ -f "$VIDEO.processing" ] && rm "$VIDEO.processing" && \
						error_exit "could not convert $SRCDIR/$WERKJE/$VIDEO" )

					else

						echo "$VIDEO has been modified in the last 5 minutes, skipping"

					fi
				fi
			done
	done
}

# seems very redundant but this way we can fiddle a bit with conversion settings for each werkje
case "$WERKJE" in

	# ck1_ar_portraits)

	# 	process_ck1_ar_portraits

	# ;;

	ck2_presenteren)

		process_ck2_presenteren

	;;

	ck3_sprong)

		process_ck3_sprong

	;;

	ck4_animatieplaats)

		process_ck4_animatieplaats

	;;

	# ck5_wonderwiel)

	# 	process_ck5_wonderwiel

	# ;;

	ck6_3d_avatarfabriek)

		rsync -a --exclude='**/._.DS_Store' --exclude='**/.DS_Store' $SRCDIR/ck6_3d_avatarfabriek/ $DSTDIR/ck6_3d_avatarfabriek/

	;;

	ck7_tagtool)

		process_ck7_tagtool

	;;

	ck8_hackasaurus)

		rsync -a --exclude='**/._.DS_Store' --exclude='**/.DS_Store' $SRCDIR/ck8_hackasaurus/ $DSTDIR/ck8_hackasaurus/

	;;

	ck9_catroid)

		rsync -a --exclude='**/._.DS_Store' --exclude='**/.DS_Store' $SRCDIR/ck9_catroid/ $DSTDIR/ck9_catroid/

	;;

	# ck10_watch_that_sound)

	# 	process_ck10_watch_that_sound

	# ;;

	*)

		process_generic

	;;

esac
