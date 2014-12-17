#!/usr/bin/perl -w
# PPath@Cornell/BTI
# Surya Saha 12/16/2014
# Purpose: Print the quality values in a fastq file with corresponding ASCII value
# Illumina 1.8+ Phred+33 : 33 to 73
# Illumina 1.5+ Phred+64 : 64 to 104
# http://en.wikipedia.org/wiki/FASTQ_format

unless (@ARGV == 1){
	print "USAGE: $0 <Fastq> \n";
	exit;
}

use strict;
use warnings;

my ($ifname,$rec,$i,$j,@temp);

$ifname=$ARGV[0];
unless(open(IN,$ifname)){print "not able to open ".$ifname."\n\n";exit;}
$i=0;
while ($rec=<IN>){
	$i++; chomp $rec;
	if (($i % 4) == 0){
		print "line $i\n".$rec."\n";
		@temp = split ('',$rec);
		foreach $j (@temp){
			print "$j\t"; print ord $j; print "\n";
		}
		print "\n";
	}
}

close (IN);

