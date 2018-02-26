#!/usr/bin/perl -w
# Solgenomics@BTI
# Surya Saha
# Purpose: Update descriptions in Fasta file


unless (@ARGV == 3){
	print "USAGE: $0 <Fasta> <Tabbed Desc file> <updated fasta>\n";
	exit;
}

use strict;
use warnings;

my ($input_fasta, $input_desc, $output_fasta);
$input_fasta = $ARGV[0];
$input_desc = $ARGV[1];
$output_fasta = $ARGV[2];

unless(open(INDESC,$input_desc)){print "not able to open ".$input_desc."\n\n";exit;}
my %desc;
while (my $rec = <INDESC>){
	my @desc_arr = split ("\t", $rec);
	$desc{$desc_arr[0]} = $desc_arr[1];
}
close (INDESC);

unless(open(INFAS,$input_fasta)){print "not able to open ".$input_fasta."\n\n";exit;}
unless(open(OUT,">$output_fasta")){print "not able to open ".$output_fasta."\n\n";exit;}

while (my $rec = <INFAS>){
	if ( $rec =~ />/ ){
		my $name = $rec; chomp $name;
		$name =~ s/^>//;
		die "$name not found in desc hash\n" if ( !exists $desc{$name} );
		chomp $rec; $rec = $rec.' '.$desc{$name};
		print OUT $rec;
	}
	else{
		print OUT $rec;
	}
}
close (INFAS);
close (OUT);

