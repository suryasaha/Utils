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

 Reads in BLAST report file. Should work for any type of Blast. CHECK!! 
  
=head1 VERSION HISTORY
 Version   1.0  INPUT:  Blast report file 
                OUTPUT: XLS file

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
if ($printhits) {
	unless ( open( HITS, ">${out}.querywthit.names" ) ) {
		print "not able to open ${out}.querywthit.names\n\n";
		exit 1;
	}
}
if ($printnohits) {
	unless ( open( NOHITS, ">${out}.querywtnohit.names" ) ) {
		print "not able to open ${out}.querywtnohit.names\n\n";
		exit 1;
	}
	unless ( open( NOVALIDHITS, ">${out}.querywtnovalidhit.names" ) ) {
		print "not able to open ${out}.querywtnovalidhit.names\n\n";
		exit 1;
	}
}
if ($printbesthit) {
	unless ( open( BESTHITS, ">${out}.querywthit_besthit.names" ) ) {
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
			unless ( open( XLS, ">$out" ) ) {
				print "not able to open $out\n\n";
				exit 1;
			}
			print XLS "\t\tBLAST REPORT\n\n\n";
			print XLS "Blast report\tE-value cutoff\n$rep\t$evalcutoff\n\n";
			print XLS "Algorithm\tVersion\n", $result->algorithm, "\t",
			  $result->algorithm_version, "\n";
			print XLS "DB name\tSequences\tSize\n", $result->database_name,
			  "\t", $result->database_entries, "\t", $result->database_letters,
			  "\n";
			print XLS
"NOTE\tCounts for translated blasts (tblastn etc.) will have a mix of amino acid counts and nucleotide counts\n\n";
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
			  . "\tE-value\tScore\tLength\tQuery_gaps%\tQuery\t%\tHit_gaps%\tHit\t%\tHit name\tDescription\tLength\n";
		}
		else {
			$str =
			    "\nQuery\t"
			  . $result->query_name
			  . "\nLength\t"
			  . $result->query_length . "\n";
			$str = $str
			  . "\tE-value\tScore\tLength\tQuery_gaps\t%\tQuery\t%\tHit_gaps\ts%\tHit\t%\tHit name\tDescription\tLength\n";
		}

		my ( @qgen, $qalng, $salng, $qaln, $saln, $tothsplen, $qhsplen,
			$shsplen );

		if ($cov) {
			for $i ( 0 .. $result->query_length() ) { $qgen[$i] = 0; }
		}

		while ( $hit = $result->next_hit ) {

			#get total length of all hsps
			$qhsplen = $shsplen = $tothsplen = 0;
			if ($debug) {
				print STDERR "For Query: ", $result->query_name, "\n";
			}
			while ( $hsp = $hit->next_hsp() ) {
				$tothsplen += $hsp->length('total');
				$qhsplen   += $hsp->length('query');
				$shsplen   += $hsp->length('hit');
				if ($cov) {
					for $i ( $hsp->start('query') .. $hsp->end('query') ) {
						$qgen[$i] = 1;
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

			## $hit is a Bio::Search::Hit::HitI compliant object
			if ( $result->query_length() == 0 ) { $qalng = 0; }
			else { $qalng = ( $tothsplen / $result->query_length() ) * 100; }
			if ( $hit->length() == 0 ) { $salng = 0; }
			else { $salng = ( $tothsplen / $hit->length() ) * 100; }
			if ( $result->query_length() == 0 ) { $qaln = 0; }
			else { $qaln = ( $qhsplen / $result->query_length() ) * 100; }
			if ( $hit->length() == 0 ) { $saln = 0; }
			else { $saln = ( $shsplen / $hit->length() ) * 100; }

			if (   ( $hit->significance <= $evalcutoff )
				&& ( $qaln > $qcutoff )
				&& ( $saln > $scutoff ) )
			{
				$str =
				    $str . "\t"
				  . $hit->significance . "\t"
				  . $hit->bits . "\t"
				  . $tothsplen . "\t"
				  . sprintf( "%.3f", $qalng ) . "\t"
				  . $qhsplen . "\t"
				  . sprintf( "%.3f", $qaln ) . "\t"
				  . sprintf( "%.3f", $salng ) . "\t"
				  . $shsplen . "\t"
				  . sprintf( "%.3f", $saln ) . "\t"
				  . $hit->name . "\t"
				  . $hit->description . "\t"
				  . $hit->length() . "\n";

				#since first hit is the best hit
				if ( $validhits == 0 ) {
					if ($printbesthit) {
						print BESTHITS $hit->name . "\n";
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
			}
		}
		if ($cov) {
			$j = 0;
			for $i ( 0 .. $#qgen ) { $j += $qgen[$i]; }
			$i = ( $j / $result->query_length() ) * 100;
			$str = $str . "\tCoverage\t" . sprintf( "%.3f", $i ) . "%\n";
		}

		if ($validhits) {
			print XLS $str;
			if ($printhits) {
				print HITS $result->query_name . "\n";
			}
		}
		else {
			if ($printnohits) {
				print NOVALIDHITS $result->query_name . "\n";
			}
		}
	}
	else {
		if ($printnohits) {
			print NOHITS $result->query_name . "\n";
		}
	}
	$i = $result;
}

if ( $flag == 1 ) {
	@temp = $i->available_parameters();
	print XLS "\n\nParameters\t";
	foreach $j (@temp) { print XLS $j, "\t"; }
	print XLS "\n\t";
	foreach $j (@temp) { print XLS $i->get_parameter($j), "\t"; }
	print XLS "\n";
	@temp = $i->available_statistics();
	print XLS "Statistics\t";
	foreach $j (@temp) { print XLS $j, "\t"; }
	print XLS "\n\t";
	foreach $j (@temp) { print XLS $i->get_statistic($j), "\t"; }
	print XLS "\n\n";
}

if ( $flag == 0 ) {
	print STDERR "\n\nNo hits found!!\n";
}
else {
	close(XLS);
	if ($printhits) {
		close(HITS);
	}
	if ($printnohits) {
		close(NOHITS);
	}
	if ($printbesthit) {
		close(BESTHITS);
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

 Reads in BLAST report file. Should work for any type of Blast. CHECK!! 
  
VERSION HISTORY
 Version   1.0  INPUT:  Blast report file 
                OUTPUT: XLS file

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

 Surya Saha, ss2489\@cornell.edu
		
EOF
	exit(1);
}
