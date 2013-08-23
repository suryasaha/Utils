#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Nov 22, 2010
# http://www.bioperl.org/wiki/HOWTO:EUtilities_Cookbook#Simple_database_query

use strict;
use warnings;
eval {
	require Bio::DB::EUtilities;
};
use Bio::DB::EUtilities;

unless (@ARGV == 2){
	print "USAGE: $0 <db name> <search term>\n";
	print "Get the primary IDs from Entrez for a search string and a DB, for e.g. GIs for Protein DB\n";
	exit;
}
 
my $factory = Bio::DB::EUtilities->new(-eutil  => 'esearch',
                                       -db     => $ARGV[0],
                                       -term   => $ARGV[1],
                                       -email  => 'ss2489@cornell.edu',
                                       -retmax => 50000000);
 
## query terms are mapped; what's the actual query?
print STDERR "Query translation: ",$factory->get_query_translation,"\n";
## query hits
print STDERR "Count: ",$factory->get_count,"\n";
# UIDs
my @ids = $factory->get_ids;
foreach (@ids){ print "$_\n";}

exit;
