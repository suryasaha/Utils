#!/usr/bin/perl

=head1 NAME

fastaSplit.pl

=head1 SYNOPSIS

fastaSplit.pl -f [Fasta file] -l [fragment length]

=head1 COMMAND-LINE OPTIONS

 -f  Genome fasta file (required)
 -l  Fragment length to split each sequence into  (required)
 -d  debugging messages (1 or 0)
 -o  Output fasta file
 -h  Help

=cut

use strict;
use warnings;

use Getopt::Std;
use Bio::Perl;
use Bio::SeqIO;

our ( $opt_f, $opt_l, $opt_o, $opt_d, $opt_h );
getopts('f:l:o:d:h');
if ($opt_h) {
	help();
	exit;
}

if ( !$opt_f || !$opt_l) {
	print "\n Contig fasta and fragment length are required. See help below\n\n\n";
	help();
}

my $fna = $opt_f;
if (!(-e $fna)){print STDERR "$fna not found: $!\n"; exit 1;}
my $fragmentLength = $opt_l;
$opt_o ||= 'split.'.${fna};

my $fastaObj = Bio::SeqIO->new('-file'=>$fna ,'-format' => 'fasta');
my $fastaOut = '';
my ($countIn , $countOut) = 0,0;

while (my $seqObj=$fastaObj->next_seq()){

	$countIn++;
	
	if ($opt_d){
		print STDERR $seqObj->display_name()."\n";
		print STDERR $seqObj->description()."\n";
		print STDERR $seqObj->length()."\n";
	}
	
	my $start = 1;
	my $end   = $fragmentLength;
	my ($header, $sequence);
	if ( $seqObj->length() <= $fragmentLength ){
		$header   = $seqObj->display_name() . $seqObj->description() . "\n";
		$sequence = $seqObj->seq();
		$fastaOut = $fastaOut . '>' . $header . $sequence . "\n";
		$countOut++;
	}
	else{
		while ( $end != ($seqObj->length() + 1 )) {
			#print STDERR ref $seqObj;
			if ( $opt_d){
				print STDERR "Start $start End $end\n ";
			}
			
			$header   = $seqObj->display_name() . $seqObj->description() . '| start: '. $start . ' end: ' . $end . "\n";
			$sequence = $seqObj->subseq($start, $end);
			$fastaOut = $fastaOut . '>' . $header . $sequence . "\n";
			$countOut++;
			
			$start = $end + 1 ;
			$end   = $start + $fragmentLength - 1 ;
			if ($end > $seqObj->length() ) { $end = $seqObj->length();} #for last fragment
		}
	}
}

unless(open(OF,">$opt_o")){print "not able to open $opt_o for writing\n\n";exit 1;}
print OF $fastaOut;
close (OF);

print STDERR "Split $countIn sequences into $countOut fragments of length $fragmentLength\n\n";


#----------------------------------------------------------------------------

sub help {
	print STDERR <<EOF;
  $0:

    Description:

    Split each sequence into fixed length fragments to translate in all 6 reading frames to create DB for proteomics experiments. It is easier to review Mascot and scaffold reports if the contigs are small. It creates the file in memory so it can crash if the Fasta file is > your RAM
     
    NOTE:


    Usage:
      fastaSplit.pl -f [Fasta file] -l [fragment length]
      
    Flags:

		  -f  Genome fasta file (required)
                  -l  Fragment length to split each sequence into
                  -d  debugging messages (1 or 0)
                  -h  Help


EOF
	exit(1);
}

=head1 LICENSE

  Same as Perl.

=head1 AUTHORS

  Surya Saha <suryasaha@cornell.edu , @SahaSurya>

=cut

