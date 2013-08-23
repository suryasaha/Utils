#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Nov 22, 2010
# http://www.bioperl.org/wiki/HOWTO:EUtilities_Cookbook#How_do_I_retrieve_a_long_list_of_sequences_using_a_query.3F

use strict;
use warnings;
eval {
	require Bio::DB::EUtilities;
};
use Bio::DB::EUtilities;

unless (@ARGV == 6){
	print "USAGE: $0 <db name> <search term> <output file> <format(fasta,gb,gbwithparts)> <items/500> <tries/5>\n";
	print "Get sequences from Entrez given a DB name and search string. See http://eutils.ncbi.nlm.nih.gov/corehtml/query/static/efetchseq_help.html for Efetch details\n"; 
	exit;
}
 
my $factory = Bio::DB::EUtilities->new(-eutil  => 'esearch',
                                       -db     => $ARGV[0],
                                       -term   => $ARGV[1],
                                       -email  => 'ss2489l@cornell.edu',
                                       -usehistory => 'y');
 
# query terms are mapped; what's the actual query?
print STDERR "Query translation: ",$factory->get_query_translation,"\n";
# query hits
print STDERR "Count: ",$factory->get_count,"\n";


my $count = $factory->get_count;
# get history from queue
my $hist  = $factory->next_History || die 'No history data returned';
print "History returned\n";
# note db carries over from above
$factory->set_parameters(-eutil   => 'efetch',
                         -rettype => $ARGV[3],
                         -history => $hist);
 
my $retry = 0;
my ($retmax, $retstart) = ($ARGV[4],0);
 
open (my $out, '>', $ARGV[2]) || die "Can't open file:$!";
 
RETRIEVE_SEQS:
while ($retstart < $count) {
    $factory->set_parameters(-retmax   => $retmax,
                             -retstart => $retstart);
    eval{
        $factory->get_Response(-cb => sub {my ($data) = @_; $data=~ s/\n\n/\n/g; print $out $data} );
    };
    if ($@) {
        die "Server error: $@.  Try again later" if $retry == $ARGV[5];
        print STDERR "Server error, redo #$retry\n";
        $retry++ && redo RETRIEVE_SEQS;
    }
    print "Retrieved $retstart sequences\n";
    $retstart += $retmax;
}
 
close $out;
print STDERR "Extra newlines may have to be removed from $ARGV[2]\n";

exit;
