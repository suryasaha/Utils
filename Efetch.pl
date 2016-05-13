#!/usr/bin/perl -w
# PPath
# Surya Saha 01/26/2010 03:41:10 PM  
# Simply retreive the seqs for GI's in a file from nuccore

# Use following script commands to generate the GIs
# i=1000001; while [ $i -le 1002855 ]; do printf "ABZR0$i\n" >> GInos; i=$(($i+1)); done;

# See http://eutils.ncbi.nlm.nih.gov/corehtml/query/static/efetchseq_help.html

# ===========================================================================
#
#                            PUBLIC DOMAIN NOTICE
#               National Center for Biotechnology Information
#
#  This software/database is a "United States Government Work" under the
#  terms of the United States Copyright Act.  It was written as part of
#  the author's official duties as a United States Government employee and
#  thus cannot be copyrighted.  This software/database is freely available
#  to the public for use. The National Library of Medicine and the U.S.
#  Government have not placed any restriction on its use or reproduction.
#
#  Although all reasonable efforts have been taken to ensure the accuracy
#  and reliability of the software and data, the NLM and the U.S.
#  Government do not and cannot warrant the performance or results that
#  may be obtained by using this software or data. The NLM and the U.S.
#  Government disclaim all warranties, express or implied, including
#  warranties of performance, merchantability or fitness for any particular
#  purpose.
#
#  Please cite the author in any work or product based on this material.
#
# ===========================================================================
#
# Author:  Oleg Khovayko
#
# File Description: eSearch/eFetch calling example

use strict;
use warnings;
use LWP::Simple;

eval {require LWP::Simple; };
if ( $@ ) {
print STDERR "Cannot find LWP::Simple\n";
print STDERR "You will need LWP::Simple library installed to run this script\n";
return 0;
}

unless (@ARGV == 3){
	print "USAGE: $0 <DB> <GI list file> <format(fasta,gb)>\n";
	print "Fetches records one by one.\nSee http://eutils.ncbi.nlm.nih.gov/corehtml/query/static/efetchseq_help.html for details\n";
	exit;
}

unless(open(IN,$ARGV[1])){print "not able to open GI file\n\n";exit;}
unless(open(OUT,">$ARGV[1].fas")){print "not able to open $ARGV[1].fas\n\n";exit;}


my ($utils,$rec,$efetch,$result);

$utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?";

#read a GI, fetch it and print it
while($rec=<IN>){
	$rec=~ s/\s//g;
	$efetch = "$utils"."db=$ARGV[0]&email=ss2489\@cornell.edu&tool=localscript&id=$rec&retmode=text&rettype=$ARGV[2]&strand=1";
	$result = get($efetch);
	if($result eq ''){ print STDERR "No data returned for $rec\n";}
	else{ chomp $result; chomp $result; print OUT "$result\n";}
}
close (IN);



