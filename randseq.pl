#!/usr/bin/perl -w
# SGN // PPath@Cornell
# Surya Saha Oct 2, 2013

use strict;
use warnings;

unless (@ARGV == 3){
print "USAGE: $0 <seq length> <seq type> <format>\n";
print "Print randome sequence of given length and type(dna/protein) and format (seq/fasta)\n";
exit;
}
my $len = $ARGV[0];
my $type = $ARGV[1];
my $format = $ARGV[2];
my $string;


if ($type=~ m/dna/i){
	my @chars = ('A','T','G','C');
	$string .= $chars[rand @chars] for 1..$len;
}
elsif ( $type=~ m/protein/i){
	my @chars = ('A','R','N','D','C','Q','E','G','H','I','L','K','M','F','P','S','T','W','Y','V','B','Z','X');
	$string .= $chars[rand @chars] for 1..$len;
}
else{
	die "Incorrect type specified. Only dna or protein accepted.";
}
if ( $format=~ m/seq/i){
	print $string,"\n";
}
elsif( $format=~ m/fasta/i){
	print "\>seq\n",$string,"\n";
}
else{
	die "Incorrect format specified. Only seq or fasta accepted.";
}

