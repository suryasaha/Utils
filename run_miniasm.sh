#!/bin/sh

# Surya Saha
# Solgenomics@BTI
# Purpose: Run Heng Li's miniasm assembler with pac bio data

usage(){
	echo "usage:
	$0 <fastq file NO RELATIVE PATHS> <cores>"
	exit 1
}

if [ "$#" -ne 2 ]
then
	usage
fi

printf "Fastq file : %s \n" "$1"
printf "Cores : %s \n" "$2"

WD=`pwd`

#update repo
cd ~/tools/minimap/ ; git pull --rebase
cd ~/tools/minimap/ ; git pull --rebase
cd $WD

~/tools/minimap/minimap -Sw5 -L100 -m0 -t"$2" "$1" "$1"| gzip -1 > minimap.out.paf.gz
~/tools/miniasm/miniasm -f "$1" minimap.out.paf.gz > miniasm.out.gfa

awk '$1=="S" {print ">"$2"\n"$3}' miniasm.out.gfa > contigs.fas
seqstat -a contigs.fas 

