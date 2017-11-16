#!/bin/sh

# Surya Saha
# BTI/PPath@Cornell
# Purpose: Make dot plots for full chr length alignment with all and 1-1 mapping between ref and query

usage(){
	echo "usage:
	$0 <ref.fa> <query.fa> <prefix for outfiles> <min tile length> <min identity perc>"
	exit 1
}

if [ "$#" -ne 5 ]
then
	usage
fi

printf "Ref file: %s \n" "$1"
printf "Query file: %s \n" "$2"
printf "Prefix: %s \n" "$3"
printf "Min tile length : %d \n" "$4"
printf "Min id perc: %d \n\n" "$5"

time nucmer -p "$3" --noextend --threads=8 "$1" "$2" 
#human readable
show-coords "$3".delta > "$3".delta.coords
#plot
mummerplot --png --prefix="${3}".all "${3}".delta

#only 1-1 mapping between ref and query
delta-filter -1 -l "$4" -i "$5" "${3}".delta > filtered."${3}".delta
#human readable
show-coords filtered."${3}".delta > filtered."${3}".delta.coords

#plot
mummerplot --png --prefix="${3}" filtered."${3}".delta

#cleanup
rm "${3}".rplot
rm "${3}".gp
rm "${3}".fplot
rm "${3}".delta

