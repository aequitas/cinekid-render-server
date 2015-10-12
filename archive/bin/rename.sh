#!/bin/sh
# rename video files without extension if they are > 0 bytes and were last
# modified > 60 seconds ago
# 20121024 Maarten te Paske <mtp@renice.n>

error_exit() {
	echo "error, $1"
	exit
}


[ -x $(which stat) ]	|| error_exit "stat binary missing"
[ -x $(which date) ]	|| error_exit "date binary missing"

NOW=$(date +%s)
SMBDIR="/srv/samba"

[ -n "$NOW" ]		|| error_exit "don't know current time"
[ -d "$SMBDIR" ]	|| error_exit "$SMBDIR does not exist"

for WERKJE in presenteren sprong; do

	ls $SMBDIR/$WERKJE/*/* | egrep -v '(mov|mp4)' | while read FILE; do

		if [ -s "$FILE" ]; then

			LASTMOD=$(stat -c %Y "$FILE")

			AGE=$(($NOW - $LASTMOD))

			if [ "$AGE" -gt "60" ]; then

				echo "$FILE $LASTMOD $NOW $AGE"

			fi

		fi

	done

done
