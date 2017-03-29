#!/bin/bash

# Surya Saha
# Solgenomics@BTI
# Purpose: Find reciprocal blast hit orthologs when given protein GIs or accessions. Use with ortholog files created using create_RBH_orthologs.sh

# Input ortholog format
#gi|662182960|ref|XP_008470658.1| FBpp0301195
#gi|662182962|ref|XP_008480455.1| FBpp0087031
#gi|662182964|ref|XP_008487638.1| FBpp0291925
#gi|662182972|ref|XP_008470659.1| FBpp0311427

# NOTE 
# NOT TESTED

usage(){
	echo "usage:
	$0 <GI or accession list> <90perc orthologs> <80perc orthologs> <70perc orthologs>"
	exit 1
}

if [ "$#" -ne 4 ]
then
	usage
fi

printf "GI or accession list : %s \n" "$1"
printf "90perc orthologs : %s \n" "$2"
printf "80perc orthologs : %s \n" "$3"
printf "70perc orthologs : %s \n" "$4"

LIST="$1"
PERC90="$2"
PERC80="$3"
PERC70="$4"

grep -f "$LIST" "$PERC90" > "${1}"."${2}".orthologs

awk -F"|" '{print $PERC90}' "${1}"."${2}".orthologs | grep -f - -v "$LIST"| grep -f - "$PERC80" > "${1}"."${PERC80}".orthologs

awk -F"|" '{print $PERC90}' <(cat "${1}"."${2}".orthologs "${1}"."${PERC80}".orthologs) | grep -f - -v "$LIST"| grep -f - "$4" > "${1}"."${PERC70}".orthologs

awk -F"|" '{print $PERC90}' <(cat "${1}"."${2}".orthologs "${1}"."${PERC80}".orthologs "${1}"."${PERC70}".orthologs) | grep -f - -v "$LIST"| grep -f - "$5" > "${1}"."${5}".orthologs

awk -F"|" '{print $PERC90}' <(cat "${1}"."${2}".orthologs "${1}"."${PERC80}".orthologs "${1}"."${PERC70}".orthologs "${1}"."${5}".orthologs) | grep -f - -v "$LIST"| grep -f - "$" > "${1}"."${6}".orthologs

awk -F"|" '{print $PERC90}' <(cat "${1}"."${2}".orthologs "${1}"."${PERC80}".orthologs "${1}"."${PERC70}".orthologs "${1}"."${5}".orthologs "${1}"."${6}".orthologs) | grep -f - -v "$LIST"| grep -f - "$" > "${1}"."${7}".orthologs

awk -F"|" '{print $PERC90}' <(cat "${1}"."${2}".orthologs "${1}"."${PERC80}".orthologs "${1}"."${PERC70}".orthologs "${1}"."${5}".orthologs "${1}"."${6}".orthologs "${1}"."${7}".orthologs) | grep -f - -v "$LIST"| grep -f - "$" > "${1}"."${8}".orthologs
