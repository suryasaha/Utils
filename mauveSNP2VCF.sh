#!/bin/bash

# Surya Saha
# PPath@Cornell/BTI
# Purpose: Create VCF files from Mauve SNP files
set -u #exit if uninit var
set -e #exit if non-zero return value (error), use command || {echo 'command failed'; exit 1;}
set -o nounset
set -o errexit

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"
readonly WDIR=`pwd`

usage() {
    echo "usage:
    $PROGNAME <mauve SNP file> <seq1 seqid> <seq2 seqid>
    
    Example:
    $PROGNAME seq1-JFGQ01seq2-SNPs NC_012985 Las-A4"
    
    NOTE: 
    1. You may need to use /bin/bash
    2. Make sure HEADER is removed from MAuve SNP file
    
    exit 1
}

if [ "$#" -ne 3 ]
then
	usage
fi

printf "Mauve SNP file: $1\nSeq1 seqid: $2\nSeq2 seqid: $3\n"

awk '{print $1}' "$1" | awk -F "" '{print $1}' > ${1}.seq1.allele
awk '{print $1}' "$1" | awk -F "" '{print $2}' > ${1}.seq2.allele
awk '{print $2}' "$1" > ${1}.seq1.pos
awk '{print $3}' "$1" > ${1}.seq2.pos
paste ${1}.seq1.pos ${1}.seq1.allele ${1}.seq2.pos ${1}.seq2.allele > ${1}.tab
awk -v val1=$2 'BEGIN{OFS="\t"} {print val1,$1,"snp"NR,$2,$4,".","PASS","."}' ${1}.tab > ${1}.${2}.vcf
awk -v val1=$3 'BEGIN{OFS="\t"} {print val1,$3,"snp"NR,$4,$2,".","PASS","."}' ${1}.tab > ${1}.${3}.vcf

#cleanup
unlink ${1}.seq1.pos 
unlink ${1}.seq1.allele 
unlink ${1}.seq2.pos 
unlink ${1}.seq2.allele 
unlink ${1}.tab
