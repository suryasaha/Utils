#!/usr/bin/env python
# Lei Gao, Fei Lab, BTI
# Surya Saha, Solgenomics, BTI


import sys
import re

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--FASTA", type=str, help="Input fasta seq file", required=True, default="")
parser.add_argument("--seqType", type=str, help="Sequence type: protein or CDS. Protein does not work atm", required=True, default="")

args = parser.parse_args()

FASTA = args.FASTA
seqType = args.seqType


# Get sequences
seq_list = []

fasta= open(FASTA, 'U')
fasta_dict= {}
for line in fasta:
    line= line.strip()                              # remove head and tail
    if line == '':                                  # if empty line, continue
        continue
    if line.startswith('>'):                        # If startswith ">", it's a seqname
        seqname= line.lstrip('>')                   # Get seqname
        #seqname= re.sub('\..*', '', seqname)        # Remove leftmost?
        seq_list.append(seqname)
        fasta_dict[seqname]= ''                     # use the seqname as "key", assign a null value to it
    else:
        fasta_dict[seqname] += line                 # use the following line(s) of seqs as "value"
fasta.close()


if seqType == "CDS":
    head_list = ['Seq','Start_codon','Stop_codon',"Premature_stop_codon",'Ns','Conclusion']
    print "\t".join(head_list)

    good_stops = set(["TAG","TGA","TAA"])

    for seqname in seq_list:
        Seq = fasta_dict[seqname]
        Start_codon = Seq[0:3]
        Stop_codon = Seq[-3:]
        if len(Seq) % 3 != 0:
            Conclusion = "Frameshift"
        else:
            if Start_codon == "ATG" and Stop_codon in good_stops:
                Conclusion = "Complete"
            elif Start_codon == "ATG":
                Conclusion = "Bad_Stop"
            elif Stop_codon in good_stops:
                Conclusion = "Bad_Start"
            else:
                Conclusion = "Bad_Both"
        
        i = 3
        Premature_stop_codon = 0
        while i < len(Seq)-3:
            if Seq[i:i+3] in good_stops:
                Premature_stop_codon += 1
            i = i + 3
        if Premature_stop_codon > 0:
            Conclusion = Conclusion + "|Premature_stop_codon"

        Ns = 0
        while i < len(Seq):                              # counting N bases as error
            if Seq[i] == 'N':
                Ns += 1
            i = i + 1
        if Ns > 0:
            Conclusion = Conclusion + "|Ns"

        outlist = [seqname,Start_codon,Stop_codon,str(Premature_stop_codon),str(Ns),Conclusion]
        print "\t".join(outlist)

elif seqType == "protein":
    print "Assuming * or X denotes STOP codon. X or . can denote NNN unknown bases\n\n"
    head_list = ['Seq','Start_codon','Stop_codon',"Premature_stop_error",'Conclusion']
    print "\t".join(head_list)

    good_stops = set(["*","X","."])                     # counting X from N bases as error, sometimes X is also used for stop

    for seqname in seq_list:
        Seq = fasta_dict[seqname]
        Start = Seq[0]
        Stop = Seq[-1:]
        if Start == "M" and Stop in good_stops:
            Conclusion = "Complete"
        elif Start == "M":
            Conclusion = "Bad_Stop"
        elif Stop in good_stops:
            Conclusion = "Bad_Start"
        else:
            Conclusion = "Bad_Both"
        i = 1
        Premature_stop = 0
        while i < len(Seq)-1:
            if Seq[i] in good_stops:
                Premature_stop += 1
            i = i + 1
        if Premature_stop > 0:
            Conclusion = Conclusion + "|Premature_stop_error"
        outlist = [seqname,Start,Stop,str(Premature_stop),Conclusion]
        print "\t".join(outlist)
else:
    print "Wrong seq type!"
    print 'Please input "CDS" or "protein".'

