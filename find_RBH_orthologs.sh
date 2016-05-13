#!/bin/bash

# Surya Saha
# Solgenomics@BTI
# Purpose: Find reciprocal blast hit orthologs when given protein GIs or accessions. Use with ortholog files created using create_RBH_orthologs.sh

# Input ortholog format
#gi|662182960|ref|XP_008470658.1| FBpp0301195
#gi|662182962|ref|XP_008480455.1| FBpp0087031
#gi|662182964|ref|XP_008487638.1| FBpp0291925
#gi|662182972|ref|XP_008470659.1| FBpp0311427

usage(){
	echo "usage:
	$0 <GI or accession list> <80perc orthologs> <60perc orthologs> <50perc orthologs> <40perc orthologs> <20perc orthologs> <10perc orthologs> <5perc orthologs>"
	exit 1
}

if [ "$#" -ne 8 ]
then
	usage
fi

printf "ARG 1 : %s \n" "$1"
printf "ARG 2 : %s \n" "$2"
printf "ARG 3 : %s \n" "$3"
printf "ARG 4 : %s \n" "$4"
printf "ARG 5 : %s \n" "$5"
printf "ARG 6 : %s \n" "$6"
printf "ARG 7 : %s \n" "$7"
printf "ARG 8 : %s \n" "$8"


grep -f "$1" "$2" > "${1}"."${2}".orthologs

awk -F"|" '{print $2}' "${1}"."${2}".orthologs | grep -f - -v "$1"| grep -f - "$3" > "${1}"."${3}".orthologs

awk -F"|" '{print $2}' <(cat "${1}"."${2}".orthologs "${1}"."${3}".orthologs) | grep -f - -v "$1"| grep -f - "$4" > "${1}"."${4}".orthologs

awk -F"|" '{print $2}' <(cat "${1}"."${2}".orthologs "${1}"."${3}".orthologs "${1}"."${4}".orthologs) | grep -f - -v "$1"| grep -f - "$5" > "${1}"."${5}".orthologs

awk -F"|" '{print $2}' <(cat "${1}"."${2}".orthologs "${1}"."${3}".orthologs "${1}"."${4}".orthologs "${1}"."${5}".orthologs) | grep -f - -v "$1"| grep -f - "$" > "${1}"."${6}".orthologs

awk -F"|" '{print $2}' <(cat "${1}"."${2}".orthologs "${1}"."${3}".orthologs "${1}"."${4}".orthologs "${1}"."${5}".orthologs "${1}"."${6}".orthologs) | grep -f - -v "$1"| grep -f - "$" > "${1}"."${7}".orthologs

awk -F"|" '{print $2}' <(cat "${1}"."${2}".orthologs "${1}"."${3}".orthologs "${1}"."${4}".orthologs "${1}"."${5}".orthologs "${1}"."${6}".orthologs "${1}"."${7}".orthologs) | grep -f - -v "$1"| grep -f - "$" > "${1}"."${8}".orthologs

