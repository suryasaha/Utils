#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Mar 01, 2011

use strict;
use warnings;
use Getopt::Long;
eval {
	require Bio::SearchIO;
	require Bio::SeqIO;
};
use Bio::SearchIO; 
use Bio::SeqIO; 

=head1 NAME

 BlastFailedQueries.pl - Pull out failed remote blast queries from Blast text report  

=head1 SYNOPSIS

  % BlastFailedQueries.pl --report blast.out --query file.fas
  
=head1 DESCRIPTION

 Reads in BLAST report file. Should work for any type of Blast. CHECK!! 
  
=head1 VERSION HISTORY
 Version   1.0  INPUT:  Blast report file and qry fasta file
                OUTPUT: fasta file

=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --report  <.out>    Blast report in text format (required)
   --query   <.fas>    Query fasta file (required)

=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut


my ($rep,$qry,$flag,$inrep,$infas,@temp,$result,$hit,$hsp,$i,$j,%seqs,$ctr);

GetOptions (
	'report=s' => \$rep,
	'query=s' => \$qry) or (system('pod2text',$0), exit 1);

# defaults and checks
defined($rep) or (system('pod2text',$0), exit 1);
if (!(-e $rep)){print STDERR "$rep not found: $!\n"; exit 1;}
defined($qry) or (system('pod2text',$0), exit 1);
if (!(-e $qry)){print STDERR "$qry not found: $!\n"; exit 1;}

$inrep = new Bio::SearchIO(-format => 'blast', -file   => $rep);
$infas = new Bio::SeqIO(-format => 'Fasta', -file   => $qry);

#record query seqs
while($result = $infas->next_seq) {
	$i=$result->display_id().$result->desc(); $i=~ s/\s*//g;
	$seqs{$i}=$result->seq();
}

#search for hits 
while($result = $inrep->next_result) {
	## $result is a Bio::Search::Result::ResultI compliant object
	if($result->no_hits_found()){next;}
	
	#get hit data
	if($result->num_hits>0){
		$i=$result->query_name.$result->query_description; $i=~ s/\s*//g;
		if(exists $seqs{$i}){
			delete $seqs{$i};
		}
		else{
			print STDERR $result->query_name," not found\n\$i is $i\n"; exit 1;
		}
	}
}

#print failed queries, if any
@temp = keys %seqs;
if(@temp>0){
	unless(open(FAS,">failed.$qry")){print "not able to open failed.$qry\n\n";exit 1;}
	$ctr=0;
	while (($i,$j) = each %seqs){
		print FAS "\>$i\n$j\n"; $ctr++; 
	}
	close(FAS);
}

print STDERR "$ctr queries failed\n";

exit;
