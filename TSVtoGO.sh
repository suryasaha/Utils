#!/bin/bash

# Surya Saha
# Solgenomics@BTI
# Purpose: Get a list of unique GO terms from an interproscan TSV file

usage(){
	echo "usage:
	$0 <TSV>"
	exit 1
}

if [ "$#" -ne 1 ]
then
	usage
fi

#printf "ARG 1 : %s \n" "$1"

awk -F"\t" '{print $1}' "$1"| sort| uniq > "$1".names

while read ACC
do
	GO=$(grep "$ACC" "$1"| grep 'GO:' | awk -F"\t" '{print $14}'| sed 's,|,\n,g'| sort| uniq)
	COUNT=$(grep "$ACC" "$1"| grep 'GO:' | awk -F"\t" '{print $14}'| sed 's,|,\n,g'| sort| uniq| wc -l)
	
	if [ "$COUNT" -gt 0 ] 
	then
		GO_ROW=$(echo "$GO"| awk 'BEGIN {ORS = " " } {print}')
		printf "%s\t%s\n" "$ACC" "$GO_ROW"
	fi
	
done < "$1".names

unlink "$1".names

