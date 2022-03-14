#!/bin/sh
LIBDIR=/home/clemens/pub/adr/lib
ADRFILE=${LIBDIR}/addresses.dat

gawk -f "${LIBDIR}/address.part1.awk" \
-f "${LIBDIR}/countryinfo.awk" \
-f "${LIBDIR}/address.part2.awk" \
-v ACTION=`basename $0` -v SEARCH=$1 -v NUM=$2 \
${ADRFILE}
