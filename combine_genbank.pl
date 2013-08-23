#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Oct 18, 2010

use strict;
use warnings;
use Getopt::Long;
use POSIX;
use Bio::SeqIO;
use Bio::Seq;
use Bio::SeqUtils;

=head1 NAME

 Combine_Genbank.pl - concatenate GBK files with linker 

=head1 SYNOPSIS

  % Combine_Genbank.pl --files file1.gbk file2.gbk .... --out merged.genome
  
=head1 DESCRIPTION

 TODO
 
=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --files  <.gbk>    Genbank files to concatenate
   --out    <name>    Name of output file

=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut

my (@files,$out,$i,$j,$ctr,$in,@seqs,$linker,@temp);

GetOptions (
	'files=s{2,20}' => \@files,
	'out=s'    => \$out) or (system('pod2text',$0), exit 1);

# checks
if (@files==0){system('pod2text',$0); exit 1;}
foreach $i (@files){
	if (!(-e $i)){print STDERR "$i not found: $!\n"; exit 1;}
}

#read in sequences
foreach $i (@files){
	$in=Bio::SeqIO->new(-file => "<$i", -format => 'genbank');
	while ($j=$in->next_seq()){
		push (@seqs,$j);
	}
}

# sort by length
@seqs = sort { $b->length <=> $a->length } @seqs;
print "Sequence order: \n";
foreach $i (@seqs){
	print $i->primary_id(),"\t\t",$i->desc(),"\t\t",$i->length,"\n";
}

$linker=Bio::Seq->new(-display_id => 'linker', -seq =>'NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN');
foreach $i (@seqs){
	push (@temp,$i); push (@temp,$linker);  
}
pop @temp;
$i=Bio::SeqUtils->cat(@temp);#concatenate
$out=Bio::SeqIO->new(-file => ">${out}.gbk", -format => 'genbank');
$out->write_seq($temp[0]);


exit;