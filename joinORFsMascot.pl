#!/usr/bin/perl -w
# BTI

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

 joinORFsMascot.pl - Join reading frames for a DNA sequence (generated from getorf) for a Mascot mass spec search

=head1 SYNOPSIS

  % joinORFsMascot.pl --faa file1.faa --sep XXXXXXXXXX --out out.faa
 
=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --faa    <.faa>  ORFs in fasta format generated using getorf -find 1 (required)
   --sep    String to separate the ORF proteins, e.g. XXXXXXXXXX (required)
   --out    <.faa>  Name of output file

=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut

use strict;
use warnings;
use File::Slurp;
use Getopt::Std;

our ( $opt_i, $opt_s, $opt_o, $opt_h );
getopts('i:o:s:h');
if ($opt_h) {
	help();
	exit;
}
if ( !$opt_i || !$opt_s || !$opt_o) {
	print
"\nORF Fasta file input, separator and output file are required.
See help below\n\n\n";
	help();
}

#get input files
my $fasta_input_file = $opt_i;
my $input_fasta      = read_file($fasta_input_file)
	or die "Could not open fasta input file: $fasta_input_file\n";
my $fasta_output_file = $opt_o;

my @lines          = split( /\n/, $input_fasta );
my $last_id        = 0;
my $last_mikado_id = '';
my $fasta_output   = '';
my $seq_counter    = 0;
my $ORF_counter    = 0;
my $seq            = '';

foreach my $line (@lines) {
	chomp($line);
	my $new_id;

	if ( $line =~ m/^>/ ) {
		#ScVcwli_1_ID=mikado.ScVcwli_1G4.1_5511_6105_1 [30 - 92], ScVcwli_1_ID=mikado.ScVcwli_1G4.2_5511_6105_1 [130 - 192] 
		#>ScVcwli_1_ID=mikado.ScVcwli_1G4.1_5511_6105_3 [265 - 134] (REVERSE SENSE)
		#mikado.ScVcwli_1G4.1
		
		$line =~ s/^>//;
		
		my $current_mikado_id = $line;
		$current_mikado_id =~ s/^[\S]+=//; #ScVcwli_1_ID=
		#print "$current_mikado_id\n";
		$current_mikado_id =~ s/ \[[\S\s]+$//; # [265 - 134] (REVERSE SENSE)
		#print "$current_mikado_id\n";
		$current_mikado_id =~ s/_[\d]+_[\d]+_[\d]+//; #_5511_6105_1
		print "$current_mikado_id\n";
				
		if(($last_mikado_id ne $current_mikado_id) && ($seq_counter > 0)){
			$fasta_output = $fasta_output.">".$last_mikado_id.'_'.$ORF_counter."\n".$seq."\n";
			$seq = '';
			$ORF_counter = 0;
		}
		$last_mikado_id = $current_mikado_id;
		$seq_counter++;
		$ORF_counter++;
	}
	else{
		$seq = $seq.$opt_s.$line;
	}
}
#last seq
$fasta_output = $fasta_output.">".$last_mikado_id.'_'.$ORF_counter."\n".$seq."\n";

unless ( open( OID, ">$fasta_output_file" ) ) {
	print STDERR "Cannot open $fasta_output_file\n";
	exit 1;
}
print OID $fasta_output;
close(OID);



#----------------------------------------------------------------------------

sub help {
	print STDERR <<EOF;
  $0:

    Description:

      To create a pseudoprotein of all ORFs for a non-coding gene prediction from mikado to run a Mascot search. The ORFs will be connected with a separator (XXXXXXXXXX). The goal is to see if one of the ORFs has coverage from mass spec data - then its not a non-coding gene

    Usage:
      joinORFsMascot.pl --faa file1.faa --sep XXXXXXXXXX --out out.faa

    Flags:

   --faa    <.faa>  ORFs in fasta format generated using getorf -find 1 (required)
   --sep    String to separate the ORF proteins, e.g. XXXXXXXXXX (required)
   --out    <.faa>  Name of output file
   --help   Help
   

EOF
	exit(1);
}

=head1 LICENSE

  Same as Perl.

=head1 AUTHORS

  Surya Saha <suryasaha@cornell.edu , @SahaSurya>

=cut

__END__

