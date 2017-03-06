#!/usr/bin/perl -w
# BTI
# Surya Saha 01/06/2016 
# Purpose: 


unless (@ARGV == 1){
	print "USAGE: $0 <.FAA> \n";
	exit;
}

use strict;
use warnings;

my ($ifname,$rec,$i);

$ifname=$ARGV[0];
unless(open(IN,$ifname)){print "not able to open ".$ifname."\n\n";exit;}
unless(open(OUT,">mascot.${ifname}")){print "not able to open mascot.".${ifname}."\n\n";exit;}

#>Diaphorina_1 [3 - 80] citri unplaced genomic scaffold, Diaci psyllid genome assembly version 1.1 scaffold1, whole genome shotgun sequence| start: 1 end: 5000
#>Diaphorina_6 [142 - 201] citri unplaced genomic scaffold, Diaci psyllid genome assembly version 1.1 scaffold162543, whole genome shotgun sequence
#>Diaphorina_7 [201 - 172] (REVERSE SENSE) citri unplaced genomic scaffold, Diaci psyllid genome assembly version 1.1 scaffold162543, whole genome shotgun sequence

#scaffold1-1_5000-Diaphorina_1[3 - 80] citri unplaced genomic scaffold, Diaci psyllid genome assembly version 1.1 scaffold1, whole genome shotgun sequence
#with a regular expression:
#>\([^ ]*\)

while ($rec=<IN>){

	if ($rec =~ /^>/ ){
		my @header = split (' ',$rec);
		my $desc = join (' ',@header[4..$#header]);
		#print STDERR $desc,"\n";
		
		if ($rec =~ /start:/){
			my $seqid = $header[0].$header[1].'-'.$header[3];
			$seqid =~ s/^>//;
			my $scaffold = $header[$#header - 8 ];
			$scaffold =~ s/,$//;
			my $start = $header[$#header - 2 ];
			my $end = $header[$#header];
		
			#print STDERR $rec;
			#print STDERR "$seqid $scaffold $start $end\n";
			#print STDERR $scaffold.'-'.$start.'_'.$end.'-'.$seqid."\n";
			print OUT '>'.$scaffold.'-'.$start.'_'.$end.'-'.$seqid.'| '.$desc."\n";
		}
		else{
			my $seqid = $header[0].$header[1].'-'.$header[3];
			$seqid =~ s/^>//;
			my $scaffold = $header[$#header - 4 ];
			$scaffold =~ s/,$//;
			#my $start = $header[$#header - 2 ];
			#my $end = $header[$#header];
		
			#print STDERR $rec;
			#print STDERR "$seqid $scaffold\n";
			#print STDERR $scaffold.'-'.$seqid."\n";
			print OUT '>'.$scaffold.'-'.$seqid.'| '.$desc."\n";		
		}
	}
	else{
		print OUT $rec;
	}
	
}


close (IN);
close (OUT);

