#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Nov 5, 2010

use strict;
use warnings;
use Getopt::Long;
eval { require Bio::SearchIO; };
use Bio::SearchIO;

=head1 NAME

 BlastReport.pl - Create an Excel report of Blast text report  

=head1 SYNOPSIS

  % BlastReport.pl --report blast.out --ecutoff 1.0 --qcutoff 0.00000001 --scutoff 0.00000001
  
=head1 DESCRIPTION

 Reads in BLAST report file. Should work for any type of Blast.
 Tried to print coverage of only qualifying hits but always the same as all hits. Explore later (use $hit->rewind to reset hsps)  
  
=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --report  <.out>   Blast report in text format (required)
   --ecutoff <float>  Evalue cutoff (<=). A float value <1.0> 
   --qcutoff <float>  % of query participating in a hit. A float value <0.00000001>
   --scutoff <float>  % of subject participating in a hit. A float value <0.00000001>
   --cov     <0/1>    Print coverage of query from all hits??
   --out     <.xls>   Excel (tabbed) output filename
   --hits    <0/1>    Print queries with hits 
   --nohits  <0/1>    Print queries with No hits
   --besthit <0/1>    Print subjects with best match (1=>1 mapping with queries with hits)
   --debug   <0/1>    Print debug messages (0 or 1)

=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut

my (
	$debug, $rep,       $evalcutoff,  $qcutoff, $scutoff,
	$help,  $out,       $cov,         $flag,    $in,
	@temp,  $result,    $hit,         $hsp,     $i,
	$j,     $printhits, $printnohits, $printbesthit
);

GetOptions(
	'report=s'  => \$rep,
	'ecutoff:f' => \$evalcutoff,
	'qcutoff:f' => \$qcutoff,
	'scutoff:f' => \$scutoff,
	'cov:s'     => \$cov,
	'out:s'     => \$out,
	'hits:i'    => \$printhits,
	'nohits:i'  => \$printnohits,
	'besthit:i' => \$printbesthit,
	'debug:i'   => \$debug,
	'help:s'    => \$help
) or ( system( 'pod2text', $0 ), exit 1 );

# defaults and checks
defined($rep) or ( system( 'pod2text', $0 ), exit 1 );
if ( !( -e $rep ) ) { print STDERR "$rep not found: $!\n"; exit 1; }
if ( defined($printhits) && $printhits != 0 && $printhits != 1 ) {
	system( 'pod2text', $0 ), exit 1;
}
if ( defined($printnohits) && $printnohits != 0 && $printnohits != 1 ) {
	system( 'pod2text', $0 ), exit 1;
}
if ( defined($printbesthit) && $printbesthit != 0 && $printbesthit != 1 ) {
	system( 'pod2text', $0 ), exit 1;
}
if ( defined($cov) && $cov != 0 && $cov != 1 ) {
	system( 'pod2text', $0 ), exit 1;
}
$evalcutoff   ||= 1.0;
$scutoff      ||= 0.00000001;    #just to keep low for whole genome comparisons
$qcutoff      ||= 0.00000001;
$cov          ||= 0;
$printbesthit ||= 0;
$printnohits  ||= 0;
$printhits    ||= 0;
$out          ||= "$rep\.xls";
if ( defined $help ) { help(); }

print STDERR
"Using E value cutoff of $evalcutoff, Query alignment% threshold of $qcutoff, Subject alignment% threshold of $scutoff ...\n";

# file handles
my ($XLS, $HITS, $NOHITS, $NOVALIDHITS, $BESTHITS);
if ($printhits) {
	unless ( open $HITS, '>', "${out}.querywthit.names" ) {
		print "not able to open ${out}.querywthit.names\n\n";
		exit 1;
	}
}
if ($printnohits) {
	unless ( open $NOHITS, '>', ">${out}.querywtnohit.names" ) {
		print "not able to open ${out}.querywtnohit.names\n\n";
		exit 1;
	}
	unless ( open $NOVALIDHITS, '>', ">${out}.querywtnovalidhit.names" ) {
		print "not able to open ${out}.querywtnovalidhit.names\n\n";
		exit 1;
	}
}
if ($printbesthit) {
	unless ( open $BESTHITS, '>', "${out}.querywthit_besthit.names" ) {
		print "not able to open ${out}.querywthit_besthit.names\n\n";
		exit 1;
	}
}

$in = new Bio::SearchIO( -format => 'blast', -file => $rep );

$flag = 0;
while ( $result = $in->next_result ) {
	## $result is a Bio::Search::Result::ResultI compliant object
	#get blast report
	if ( $result->num_hits > 0 ) {
		if ( $flag == 0 ) {
			unless ( open $XLS, '>', "$out" ) {
				print "not able to open $out\n\n";
				exit 1;
			}
			print $XLS "\t\tBLAST REPORT\n\n\n";
			print $XLS "Blast report\tE-value cutoff\n$rep\t$evalcutoff\n\n";
			print $XLS "Algorithm\tVersion\n", $result->algorithm, "\t",
			  $result->algorithm_version, "\n";
			print $XLS "DB name\tSequences\tSize\n", $result->database_name,
			  "\t", $result->database_entries, "\t", $result->database_letters,
			  "\n";
			print $XLS
				"NOTE\tCounts for translated blasts (tblastn etc.) will have a mix of amino acid counts and nucleotide counts\n\n";
			print $XLS "\ttot_HSP_Length\tSum of all HSPs
				Query_tot_HSP%\tSum of all HSPs / Query length
				Query_HSP\tSum of all HSPs in query coordinates
				%\tSum of all HSPs in query coordinates / Query Length
				Query_cov\tBases of query covered by HSPs in this hit
				%\tBases of query covered by HSPs in this hit / Query Length
				Hit_tot_HSP%\tSum of all HSPs / Hit length
				Hit_HSP\tSum of all HSPs in hit coordinates
				%\tSum of all HSPs in hit coordinates / Hit length
				Hit_cov\tBases of query covered by HSPs in this hit
				%\tBases of query covered by HSPs in this hit / Hit length\n\n";
			$flag = 1;
		}
		my $str       = '';
		my $validhits = 0;
		if ( $result->query_description ) {
			$str =
			    "\nQuery\t"
			  . $result->query_name
			  . "\nDesc\t"
			  . $result->query_description
			  . "\nLength\t"
			  . $result->query_length . "\n";
			$str = $str
			  . "\tE-value\tScore\ttot_HSP_Length\tQuery_tot_HSP%\tQuery_HSP\t%\tQuery_cov\t%\tHit_tot_HSP%"
			  . "\tHit_HSP\t%\tHit_cov\t%\tHit name\tDescription\tLength\n";
		}
		else {
			$str =
			    "\nQuery\t"
			  . $result->query_name
			  . "\nLength\t"
			  . $result->query_length . "\n";
			$str = $str
			  . "\tE-value\tScore\ttot_HSP_Length\tQuery_tot_HSP%\tQuery_HSP\t%\tQuery_cov\t%\tHit_tot_HSP%"
			  . "\tHit_HSP\t%\tHit_cov\t%\tHit name\tDescription\tLength\n";
		}

		my ( @qcov_all_hits, $qcov, $qcovperc, $scov, $scovperc, $qtothsplenperc, $stothsplenperc, $qhsplenperc, $shsplenperc, $tothsplen, $qhsplen,
			$shsplen );

		if ($cov) {
			for my $i ( 0 .. $result->query_length() ) { $qcov_all_hits[$i] = 0; }
		}

		while ( $hit = $result->next_hit ) {
			## $hit is a Bio::Search::Hit::HitI compliant object
			#coverage for this hit
			my (@qcov,@scov);
			for my $i ( 0 .. $result->query_length() ) { $qcov[$i] = 0; }
			for my $i ( 0 .. $hit->length() ) { $scov[$i] = 0; }
			
			#get total length of all hsps
			$qhsplen = $shsplen = $tothsplen = 0;
			
			if ($debug) {
				print STDERR "For Query: ", $result->query_name, "\n";
			}
			if ($debug) {
				print STDERR $hit->num_hsps . ' hsps for ' . $hit->name . "\n";
			}
			while ( $hsp = $hit->next_hsp() ) {
				## $hsp is a Bio::Search::HSP::HSPI object
				$tothsplen += $hsp->length('total');
				$qhsplen   += $hsp->length('query');
				$shsplen   += $hsp->length('hit');
				
				for my $i ( $hsp->start('query') .. $hsp->end('query') ) {
					$qcov[$i] = 1;
				}
				
				for my $i ( $hsp->start('sbjct') .. $hsp->end('sbjct') ) {
					$scov[$i] = 1;
				}
								
				
				if ($cov) {
					for my $i ( $hsp->start('query') .. $hsp->end('query') ) {
						$qcov_all_hits[$i] = 1;
					}
				}
				if ($debug) {
					print STDERR "\tqStrand: ", $hsp->strand('query'),
					  "\tqStart: ", $hsp->start('query'), "\tqEnd: ",
					  $hsp->end('query'), "\n";
					print STDERR "\tsStrand: ", $hsp->strand('sbjct'),
					  "\tsStart: ", $hsp->start('sbjct'), "\tsEnd: ",
					  $hsp->end('sbjct'), "\n";
				}
			}
			
			$j = 0;
			for my $i ( 0 .. $#qcov ) { $j += $qcov[$i]; }
			$qcov = $j;
			$qcovperc = ( $qcov / $result->query_length() ) * 100;
			$j = 0;
			for my $i ( 0 .. $#scov ) { $j += $scov[$i]; }
			$scov = $j;
			$scovperc = ( $scov / $hit->length() ) * 100;
			

			## $hit is a Bio::Search::Hit::HitI compliant object
			if ( $result->query_length() == 0 ) { $qtothsplenperc = 0; }
			else { $qtothsplenperc = ( $tothsplen / $result->query_length() ) * 100; }
			
			if ( $hit->length() == 0 ) { $stothsplenperc = 0; }
			else { $stothsplenperc = ( $tothsplen / $hit->length() ) * 100; }
			
			if ( $result->query_length() == 0 ) { $qhsplenperc = 0; }
			else { $qhsplenperc = ( $qhsplen / $result->query_length() ) * 100; }
			
			if ( $hit->length() == 0 ) { $shsplenperc = 0; }
			else { $shsplenperc = ( $shsplen / $hit->length() ) * 100; }

			if (   ( $hit->significance <= $evalcutoff )
				&& ( $qcovperc > $qcutoff )
				&& ( $scovperc > $scutoff ) )
			{
				if ($debug) {
					print STDERR $hit->num_hsps
					  . ' hsps for valid hit '
					  . $hit->name . "\n";
				}
				$str =
				    $str . "\t"
				  . $hit->significance . "\t"
				  . $hit->bits . "\t"
				  . $tothsplen . "\t"
				  . sprintf( "%.3f", $qtothsplenperc ) . "\t"
				  . $qhsplen . "\t"
				  . sprintf( "%.3f", $qhsplenperc ) . "\t"
				  . $qcov . "\t"
				  . sprintf( "%.3f", $qcovperc ) . "\t"
				  . sprintf( "%.3f", $stothsplenperc ) . "\t"
				  . $shsplen . "\t"
				  . sprintf( "%.3f", $shsplenperc ) . "\t"
				  . $scov . "\t"	
				  . sprintf( "%.3f", $scovperc ) . "\t"
				  . $hit->name . "\t"
				  . $hit->description . "\t"
				  . $hit->length() . "\n";

				#since first hit is the best hit
				if ( $validhits == 0 ) {
					if ($printbesthit) {
						print $BESTHITS $hit->name . "\n";
					}
				}
				$validhits = 1;
			}
			else {
				$str =
				    $str
				  . "\tHit at "
				  . $hit->significance
				  . " with HSP length "
				  . $tothsplen
				  . " does not qualify\n";
				if ($debug) {
					print STDERR 'Invalid hit ' . $hit->name . "\n";
				}
			}
		}
		if ($cov) {
			$j = 0;
			for my $i ( 0 .. $#qcov_all_hits ) { $j += $qcov_all_hits[$i]; }
			$i = ( $j / $result->query_length() ) * 100;
			$str =
			    $str
			  . "\tCoverage for all hits\t"
			  . sprintf( "%.3f", $i ) . "%\n";
		}

		if ($validhits) {
			print $XLS $str;
			if ($printhits) {
				print $HITS $result->query_name . "\n";
			}
		}
		else {
			if ($printnohits) {
				print $NOVALIDHITS $result->query_name . "\n";
			}
		}
	}
	else {
		if ($printnohits) {
			print $NOHITS $result->query_name . "\n";
		}
	}
	$i = $result;
}

if ( $flag == 1 ) {
	@temp = $i->available_parameters();
	print $XLS "\n\nParameters\t";
	foreach my $j (@temp) { print $XLS $j, "\t"; }
	print $XLS "\n\t";
	foreach my $j (@temp) { print $XLS $i->get_parameter($j), "\t"; }
	print $XLS "\n";
	@temp = $i->available_statistics();
	print $XLS "Statistics\t";
	foreach my $j (@temp) { print $XLS $j, "\t"; }
	print $XLS "\n\t";
	foreach my $j (@temp) { print $XLS $i->get_statistic($j), "\t"; }
	print $XLS "\n\n";
}

if ( $flag == 0 ) {
	print STDERR "\n\nNo hits found!!\n";
}
else {
	close($XLS);
	if ($printhits) {
		close($HITS);
	}
	if ($printnohits) {
		close($NOHITS);
	}
	if ($printbesthit) {
		close($BESTHITS);
	}
}

exit;

sub help {
	print STDERR <<EOF;
	
	$0:
	
	 Creates an Excel report of Blast text report  

SYNOPSIS

BlastReport.pl --report blast.out --ecutoff 1.0 --qcutoff 0.00000001 --scutoff 0.00000001
  
DESCRIPTION

 Reads in BLAST report file. Should work for any type of Blast.
 Tried to print coverage of only qualifying hits but always the same as all hits. Explore later (use $hit->rewind to reset hsps) 
  
COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --report  <.out>   Blast report in text format (required)
   --ecutoff <float>  Evalue cutoff. A float value <1.0> 
   --qcutoff <float>  % of query participating in a hit. A float value <0.00000001>
   --scutoff <float>  % of subject participating in a hit. A float value <0.00000001>
   --cov     <0/1>    Print coverage of query from all hits??
   --hits    <0/1>    Print queries with hits 
   --nohits  <0/1>    Print queries with No hits
   --besthit <0/1>    Print subjects with best match (1=>1 mapping with queries with hits)
   --out     <.xls>   Excel (tabbed) output filename
   --debug   <0/1>    Print debug messages (0 or 1)

AUTHOR

 Surya Saha, ss2489 near cornell.edu , \@SahaSurya
		
EOF
	exit(1);
}
