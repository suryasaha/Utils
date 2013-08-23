#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Oct 1, 2010
# http://www.bioperl.org/wiki/HOWTO:EUtilities_Cookbook#How_do_I_retrieve_a_long_list_of_sequences_using_a_query.3F

use strict;
use warnings;
eval {
	require Bio::DB::EUtilities;
};
use Bio::DB::EUtilities;

unless (@ARGV == 4){
	print "USAGE: $0 <db> <GI file> <output file> <format(fasta,gb,gbwithparts)>\n";
	print "Get sequences from Entrez given a GI list. See http://eutils.ncbi.nlm.nih.gov/corehtml/query/static/efetchseq_help.html for Efetch details\n"; 
	exit;
}

unless(open(GI,"<$ARGV[1]")){print "not able to open $ARGV[1]\n\n";exit 1;}

my (@ids,$i);
while ($i=<GI>){ chomp($i); push @ids,$i;}
close (GI);
#@ids     = qw(1621261 89318838 68536103 20807972 730439); works for this!!

#my $factory = Bio::DB::EUtilities->new(-eutil   => 'efetch',
#                                       -db      => 'protein',
#                                       -rettype => 'fasta',
#                                       -tool    => 'bioperl',
#                                       -email  => 'ss2489l@cornell.edu',
#                                       -id      => \@ids);
# 
#my $file = 'myseqs.fasta';
#
## dump HTTP::Response content to a file (not retained in memory)
#$factory->get_Response(-file => $file);
#MSG: Response Error
#Request-URI Too Large<------------------------------------------ ERROR
#STACK: Error::throw



my $factory = Bio::DB::EUtilities->new(-eutil  => 'epost',
                                       -db     => $ARGV[0],
                                       -id     => \@ids,
                                       -email  => 'ss2489l@cornell.edu',
                                       -keep_histories => 1);

#if (my $history = $factory->next_History) {
#    print "Posted successfully\n";
#    print "WebEnv    : ",$history->get_webenv,"\n";
#    print "Query_key : ",$history->get_query_key,"\n";
#}

#my $count = $factory->get_count;
my $count = scalar @ids;
# get history from queue
my $hist  = $factory->next_History || die 'No history data returned';
print "History returned\n";
# note db carries over from above
$factory->set_parameters(-eutil   => 'efetch',
                         -rettype => $ARGV[3],
                         -history => $hist);
 
my $retry = 0;
my ($retmax, $retstart) = (500,0);
 
open (my $out, '>', $ARGV[2]) || die "Can't open file:$!";
 
RETRIEVE_SEQS:
while ($retstart < $count) {
    $factory->set_parameters(-retmax   => $retmax, -retstart => $retstart);
    eval{
        $factory->get_Response(-cb => sub {my ($data) = @_; $data=~ s/\n\n/\n/g; print $out $data} );
    };
    if ($@) {
        die "Server error: $@.  Try again later" if $retry == 5;
        print STDERR "Server error, redo #$retry\n";#ERROR generated
        $retry++ && redo RETRIEVE_SEQS;
    }
    print "Retrieved $retstart sequences\n";
    $retstart += $retmax;
}
 
close $out;
print STDERR "Extra newlines may have to be removed from $ARGV[1]\n";

exit;