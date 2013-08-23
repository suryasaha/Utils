#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Oct 1, 2010

use strict;
use warnings;
use Getopt::Long;
eval {
	require Bio::DB::Fasta;
	require Bio::SeqIO;
};
use Bio::SeqIO;
use Bio::DB::Fasta;

=head1 NAME

 findseqs.pl - Print sequences with names matching user supplied string from a sequence file 

=head1 SYNOPSIS

  % findseqs.pl --infile in.fna --format fasta --name name
  
=head1 DESCRIPTION

 Reads in a sequence file and prints out the ones with matching names.  

=head1 VERSION HISTORY

=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --infile <.fna>    Sequence file in Fasta, Genbank etc format (required)
   --format <x>       Format of sequence file. Should be readable by Bio::SeqIO. Default is fasta
   --name   <x>       Text string in quotes (required)
      
=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut
my ($i,$in,$format,$name,$flag);

GetOptions (
	'infile=s' => \$in,
	'format:s' => \$format,
	'name=s' => \$name) or (system('pod2text',$0), exit 1);
defined($in) or (system('pod2text',$0), exit 1);
if (!(-e $in)){print STDERR "$in not found: $!\n"; exit 1;}
$format ||= 'fasta';
defined($name) or (system('pod2text',$0), exit 1);

my $infaa = Bio::SeqIO->new('-file' => "<$in",'-format' => $format );
$flag=0;
while ($i = $infaa->next_seq()) {
	#>gi|16262454|ref|NP_435247.1| FdoG formate dehydrogenase-O alpha subunit [Sinorhizobium meliloti 1021]
	if($i->id()=~ /$name/ || ($i->desc=~ /$name/)){
		print '>',$i->id(),'|',$i->desc(),"\n",$i->seq(),"\n";
		$flag=1;
	}
}
$infaa->close();
if(!$flag){print STDERR "No sequence found with $name\n";}

exit;
