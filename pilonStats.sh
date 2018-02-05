#!/bin/sh

# Surya Saha
# Solgenomics@BTI
# Purpose: Get pilon correction stats from the entire log file (-debug 3>&1 1>&2 2>&3 > pilon.log)

usage(){
	echo "usage:
	$0 <log file>"
	exit 1
}

if [ "$#" -ne 1 ]
then
	usage
fi

LOG="$1"
printf "Log file : %s \n" "$LOG"

printf "SNPcount INScount INSbases DELcount DELbases\n"
grep 'Corrected '  "$LOG"| awk '{snpcount+=$2;inscount+=$5;insbases+=$9;delcount+=$11;delbases+=$15} END {print snpcount,inscount,insbases,delcount,delbases}'

printf "Nof gaps closed\n"
grep -c ' ClosedGap' "$LOG"

printf "Nof gaps opened\n"
grep -c ' OpenedGap' "$LOG"

printf "Nof continuity fixes\n"
grep -c ' BreakFix' "$LOG"

printf "Nof cases where continuity could not be fixed\n"
grep -c ' NoSolution' "$LOG"




