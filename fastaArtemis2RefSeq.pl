#!/usr/bin/perl -w
# PPath
# Surya Saha  7/17/2013 
# reading Fasta files produced by Artemis  
# and writing Fasta file with Name from a Refseq GFF file
# Only for CDS features

unless (@ARGV == 2){
	print "USAGE: $0 <Artemis fasta> <Refseq GFF>\n";
	exit;
}

use strict;
use warnings;

unless(open(INFAS,"<$ARGV[0]")){print "not able to open $ARGV[0]\n\n";exit 1;}
unless(open(INGFF,"<$ARGV[1]")){print "not able to open $ARGV[1]\n\n";exit 1;}
unless(open(OFAS,">refseq.$ARGV[0]")){print "not able to open $ARGV[0]\n\n";exit 1;}

my ($rec,$i,$j,@temp,@temp1);
my (%names);

#LamPW_SP	GenBank	chromosome	1	1176533	.	.	.	db_xref='taxon:
#LamPW_SP	GenBank	CDS	739	3558	.	-	1	Name=LamPW_SP1;product=Isoleucyl-tRNA
#LamPW_SP	GenBank	CDS	3863	4513	.	-	2	Name=LamPW_SP2;product=Phage
#LamPW_SP	GenBank	CDS	5291	5710	.	+	2	Name=LamPW_SP3;product=Predicted
#read GFF and build hash of names
while($rec= <INGFF>){
	if ($rec=~ /^\#/){next;}
	else{
		@temp = split("\t", $rec);
		
		if ($temp[2] eq 'CDS'){ 
			@temp1 = split(';',$temp[8]);
			foreach $i (@temp1){
				if ($i =~ /^Name/){
					$i =~ s/^Name\=//;
					#record name with location as key
					$names{"$temp[3]\:$temp[4]"}=$i;
					last;
				}
			}
		}
	}
}
close (INGFF);

#>CDS CDS Isoleucyl-tRNA synthetase (EC 6.1.1.5) 739:3558 reverse MW:107095
#MRAGLPKKEPELLSYWEEINLFERLRDSGQSRKKFILHDGPPYANGNIHIGHALNKVLKD
#IVVRSFQMRGFDANYVPGWDCHGLPIEWKIESEYIKQGKNKSNIPINEFRQECRNFAAKW
while ($rec=<INFAS>){
	if ($rec=~ /^>/){# get coords
		@temp = split(' ',$rec);
		#Confusing layout, taking third word from end
		$rec=~ s/^>//;
		print OFAS '>gi|',$names{$temp[$#temp-2]},'|ref|',$names{$temp[$#temp-2]},'| ',$rec;
		@temp=();
	}
	else{# get seq
		print OFAS $rec;
	}
}
close(INFAS);




exit;