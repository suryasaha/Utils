#!/bin/bash

# Surya Saha
# Solgenomics@BTI
# Purpose: Get a list of unique GO terms from an interproscan GFF file generated from transcripts. REMOVE Fasta at bottom of GFF

usage(){
	echo "Gets a list of unique GO terms from an interproscan GFF file generated from transcripts. REMOVE Fasta at bottom of GFF";
	echo "usage:
	$0 <GFF>"
	exit 1
}

if [ "$#" -ne 1 ]
then
	usage
fi

#printf "ARG 1 : %s \n" "$1"

awk -F"\t" '{print $1}' "$1"| sort| uniq > "$1".seqnames

while read ACC
do
	GO=$(grep "$ACC" "$1"| grep -Eo 'GO:[0-9]+'| sort| uniq)
	COUNT=$(grep "$ACC" "$1"| grep -Eo 'GO:[0-9]+'| sort| uniq| wc -l)
	
	if [ "$COUNT" -gt 0 ] #if any GO term is found
	then
		GO_ROW=$(echo "$GO"| awk 'BEGIN {ORS = " " } {print}')
		printf "%s\t%s\n" "$ACC" "$GO_ROW"| sed -e 's, $,,' -e 's, ,\,,g'
	fi
	
done < "$1".seqnames

unlink "$1".seqnames

