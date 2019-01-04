#!/bin/bash

# Surya Saha
# Solgenomics@BTI
# Purpose: Get a list of unique GO terms from an interproscan TSV file generated from proteins

usage(){
	echo "Gets a list of unique GO terms from an interproscan TSV file generated from proteins"
	echo "usage:
	$0 <TSV>"
	exit 1
}

if [ "$#" -ne 1 ]
then
	usage
fi

#printf "ARG 1 : %s \n" "$1"

awk -F"\t" '{print $1}' "$1"| sort| uniq > "$1".seqnames
TOTAL=$(awk -F"\t" '{print $1}' "$1"| sort| uniq| wc -l)
printf "%s unique seqids found\n" "$TOTAL">&2
TOTALGO=$(grep 'GO:' "$1"| awk -F"\t" '{print $1}'| sort| uniq| wc -l)
printf "%s unique seqids found that have GO terms\n" "$TOTALGO" >&2

while read ACC
do
	GO=$(grep "$ACC" "$1"| grep 'GO:' | awk -F"\t" '{print $14}'| sed 's,|,\n,g'| sort| uniq)
	COUNT=$(grep "$ACC" "$1"| grep 'GO:' | awk -F"\t" '{print $14}'| sed 's,|,\n,g'| sort| uniq| wc -l)
	
	if [ "$COUNT" -gt 0 ] #if any GO term is found
	then
		GO_ROW=$(echo "$GO"| awk 'BEGIN {ORS = " " } {print}')
		printf "%s\t%s\n" "$ACC" "$GO_ROW"| sed -e 's, $,,' -e 's, ,\,,g'
	fi
	
done < "$1".seqnames

unlink "$1".seqnames

