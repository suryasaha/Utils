#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Mar 3, 2011

use strict;
use warnings;
use Getopt::Long;
use Bio::Perl;
use Bio::SeqIO;
eval {require Bio::SeqIO; };
if ( $@ ) {
print STDERR "Cannot find Bio::SeqIO\n";
print STDERR "You will need the bioperl-run library to run SeqIO\n";
return 0;
}

=head1 NAME

 sortSeqs.pl - Sort a sequence file according to length 

=head1 SYNOPSIS

  % sortSeqs.pl --seq file --minlen 0 --format Fasta --order asc/desc
  
=head1 DESCRIPTION

 Sorting a sequence file in ascending or descending order. Designed to sort the contigs 
 produced by velvet/mira before characterization runs like blast etc. So that the largest
 contigs are up top. 
 
=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --seq      <file>  File with sequences (required)
   --minlen   <>      Minimum length cutoff for sequence. Default is 0
   --format   <>      Format (Fasta, Genbank, EMBL). Default is Fasta
   --order    <>      Ascending or descending (asc/desc). Default is descending.
   --out      <>      Output sequence file.

=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut

my($file,$format,$minlen,$order,$out,$i,$j,@seqs,@temp,$k,$l);

GetOptions (
	'seq=s' => \$file,
	'minlen:s' => \$minlen,
	'format:s' => \$format,
	'order:s' => \$order,
	'out:s'    => \$out) or (system('pod2text',$0), exit 1);

defined($file) or (system('pod2text',$0), exit 1);
if (!(-e $file)){print STDERR "$file not found: $!\n"; exit 1;}
$minlen ||=0;
$format ||='Fasta';
$order ||='desc';
$out ||= "sorted.$file";

$i=Bio::SeqIO->new('-file'=>$file ,'-format' => $format);
while ($j = $i->next_seq()){
	if($j->length() >= $minlen){
		@temp=(); $temp[0]=$j->length();
		$temp[1]=$j->display_id(); $temp[2]=$j->desc();
		$temp[3]=$j->seq(); push @seqs,[@temp];		
	}
}

#sort on length
if($order eq 'desc'){@temp = sort {$b->[0] <=> $a->[0]} @seqs;}
elsif($order eq 'asc'){@temp = sort {$a->[0] <=> $b->[0]} @seqs;}
@seqs=@temp;

$i = Bio::SeqIO->new('-file'=>">$out" ,'-format' => $format);
foreach $j (@seqs){
	$k=$j->[1].$j->[2];
	$l = Bio::Seq->new( -display_id => $k,-seq => $j->[3]);
	$i->write_seq($l);
}
exit;