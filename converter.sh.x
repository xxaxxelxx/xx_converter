#!/bin/bash
DEPOTDIR="/depot"
if [ "x$DEPOTDIR" == "x" ]; then exit; fi
LQSP=$(which liquidsoap)
LQSPUSER="liquidsoap"
SLEEP=60
test -d $DEPOTDIR/md5 || mkdir -p $DEPOTDIR/md5
while true; do
    for INFILE in $DEPOTDIR/*; do
	test -r "$INFILE" || continue
	INFILEBASE=$(basename "$INFILE")
	test -r $INFILEBASE.rc || continue
	INFILEMD5=$(md5sum $INFILE | awk '{print $1}')
	test -r $DEPOTDIR/md5/$INFILEBASE
	if [ $? -eq 0 ]; then
	    cat "$DEPOTDIR/md5/$INFILEBASE" | grep -w "$INFILEMD5" > /dev/null && continue 
	else
	    while read LIQLINE; do
		echo "$LIQLINE" | grep '%' > /dev/null || continue
		echo "$LIQLINE" | grep '^#' > /dev/null && continue
		echo "$LIQLINE" | grep '^$' > /dev/null && continue
		OUTFILEBASE="${LIQLINE%%\|*}"
		CODE="${LIQLINE##*\|}"
		sudo -u $LQSPUSER $LQSP "input='$INFILE';output='$DEPOTDIR/.$OUTFILEBASE.tmp';$CODE" > /dev/null 2>&1 && \
		mv -f $DEPOTDIR/.$OUTFILEBASE.tmp $DEPOTDIR/$OUTFILEBASE
	    done < $INFILEBASE.rc
	    echo $INFILEMD5 > "$DEPOTDIR/md5/$INFILEBASE"
	fi
    done
sleep $SLEEP
done
exit
