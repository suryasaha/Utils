#!/bin/bash

# Surya Saha
# Solgenomics@BTI
# Purpose: Create reciprocal blast hit orthologs for 2 protein sets (P1 and P2).
# Input: Blast reports of P1 to P2 and P2 to P1
# ~/tools/ncbi-blast-2.2.31+/bin/blastp -query dmel-all-translation-r6.10.fasta -db protein.fa -evalue 1e-5 -out dmel_gnomon.eval1e-5.out -num_threads 60 -num_descriptions 10 -num_alignments 10

# Output
#gi|662182960|ref|XP_008470658.1| FBpp0301195
#gi|662182962|ref|XP_008480455.1| FBpp0087031
#gi|662182964|ref|XP_008487638.1| FBpp0291925
#gi|662182972|ref|XP_008470659.1| FBpp0311427

usage(){
	echo "usage:
	$0 <p1-p2.eval1e-5.out> <p2-p1.eval1e-5.out> <P1 genome name(no spaces)> <P2 genome name(no spaces)>"
	exit 1
}

if [ "$#" -ne 4 ]
then
	usage
fi

printf "ARG 1 : %s \n" "$1"
printf "ARG 2 : %s \n" "$2"
printf "ARG 3 : %s \n" "$3"
printf "ARG 4 : %s \n" "$4"

# create blast reports with query and hit lists
arr=(90 80 70 60 50 40 30 20 10 5); 

for N in "${arr[@]}"; 	do 
	echo "$N"; BlastReport.pl -r "$1" --qcutoff "$N" --scutoff "$N" --besthit 1 --qhits 1 --out "$1".scov"${N}".qcov"${N}".xls;
	done

for N in "${arr[@]}"; do 
	echo "$N"; BlastReport.pl -r "$2" --qcutoff "$N" --scutoff "$N" --besthit 1 --qhits 1 --out "$2".scov"${N}".qcov"${N}".xls; 
	done

# create ortholog sets
arr=(80 60 50 40 20 10 5); 
for N in "${arr[@]}"; do 
		join -1 1 -2 2 <(paste "$1".scov"${N}".qcov"${N}".xls.querywthit.names "$1".scov"${N}".qcov"${N}".xls.querywthit.names.xls.querywthit_besthit.names| sort) <(paste "$2".scov"${N}".qcov"${N}".xls.querywthit.names.xls.querywthit.names "$2".scov"${N}".qcov"${N}".xls.querywthit.names.xls.querywthit_besthit.names| sort -k 2,2)| awk '$2==$3'| awk '{print $1,$2}' > "$3"-"$4"_"${N}"perc_scovqcov.orthologs
	done

