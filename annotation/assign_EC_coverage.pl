#!/usr/bin/perl -w
# Solgenomics@BTI
# Surya Saha DATE??
# Purpose: Assign ECs based on coverage


unless (@ARGV == 5){
	print "USAGE: $0 <Lengths file> <Blast outfmt 6 tab delimited wt EC file in last column sorted on DcitrP> <coverage%> <identity%> <out file>\n";
	exit;
}

use strict;
use warnings;
use File::Slurp;
use List::MoreUtils qw(uniq);
use Data::Dumper;

my ($input_blast_EC, $input_lengths, $identity, $coverage, $out_file);
$input_blast_EC = $ARGV[1];
$input_lengths = $ARGV[0];
$coverage = $ARGV[2];
$identity = $ARGV[3];
$out_file = $ARGV[4];

unless(open(INLENGTHS,$input_lengths)){print "not able to open ".$input_lengths."\n\n";exit;}
my %lengths;
while (my $rec = <INLENGTHS>){
	my @lengths_arr = split ("\t", $rec);
	$lengths{$lengths_arr[0]} = $lengths_arr[1];
}
close (INLENGTHS);

my $input_blast_EC_data = read_file($input_blast_EC);
my @input_blast_EC_arr      = split ("\n", $input_blast_EC_data);
my $out_file_data = '';
while (my ($gene,$length) = each %lengths){
	chomp $length;
	my @hsp_arr = grep ( /\t$gene\t/, @input_blast_EC_arr );
	next if ( scalar @hsp_arr == 0 ); #skip if not found
	#print STDERR "Got ALL HSPs for gene $gene ". Dumper \@hsp_arr;
	my ($hit, %valid_hit_hash, @valid_hit_hsp_arr);
	foreach my $rec ( @hsp_arr ){
		my @rec_arr = split ( "\t", $rec);
		if ( $rec_arr[3] >= $identity ) { #only hit with perc identity above cut-off
			#push @valid_hit_arr, $rec_arr[0];
			$valid_hit_hash{$rec_arr[0]} = '';
			push @valid_hit_hsp_arr, $rec;
		}
	}
	next if ( scalar keys %valid_hit_hash == 0 ); #skip if no hits above id %
	print STDERR "valid_hit_hsp_arr above id % ".scalar @valid_hit_hsp_arr."\n";
	#my @unique_valid_hit_arr =  keys { map { $_ => 1 } @valid_hit_arr }; #remove duplicates, arr is already sorted
	#my @unique_valid_hit_arr =  uniq @valid_hit_arr; #remove duplicates, arr is already sorted
	my @unique_valid_hit_arr = keys %valid_hit_hash;
	print STDERR "unique_valid_hit_arr above id % ".scalar @unique_valid_hit_arr."\n";
	my %unique_EC_hash;
	foreach my $valid_hit ( @unique_valid_hit_arr ){
		print STDERR "Evaluating $valid_hit for $gene\n";
		my @gene_coverage_arr; for ( 0..$length ){ $gene_coverage_arr[$_] = 0;}
		my @local_valid_hit_hsp_arr = grep (/^$valid_hit/, @valid_hit_hsp_arr); #get hsps with valid identity
		#print STDERR "Got valid HSPs for $valid_hit for $gene\n";
		#print STDERR Dumper \@local_valid_hit_hsp_arr;
		my ($EC, $total_identity_perc, $DB);
		$total_identity_perc = 0;
		foreach my $valid_hit_hsp ( @local_valid_hit_hsp_arr ){
			my @local_hsp_arr = split ("\t", $valid_hit_hsp);
			for ($local_hsp_arr[7] .. $local_hsp_arr[8]){ $gene_coverage_arr[$_] = 1; }
			$EC = $local_hsp_arr[13]; $total_identity_perc+=$local_hsp_arr[3];
			my @hit_name_arr = split ( /\|/, $local_hsp_arr[2]);
			$DB = $hit_name_arr[0];
		}
		my $coverage_count= 0; for ( 0..$length ){ $coverage_count++ if $gene_coverage_arr[$_] == 1;}
		if ( (($coverage_count/$length)*100) >= $coverage ){
			#desc from only first hit providing this EC number
			next if exists $unique_EC_hash{$EC};
			$unique_EC_hash{$EC} = "Similar to $valid_hit (DB= ".$DB." PERC_IDENTITY=".
																sprintf ( "%.2f", $total_identity_perc / scalar @local_valid_hit_hsp_arr)
																.", ALIGN_LENGTH ". $coverage_count .").";
			print STDERR "Found $EC for $gene\n";
		}
		else{
			print STDERR "HSP(s) length $coverage_count below coverage cut-off $coverage for $gene of length $length\n";
		}
	}
	if ( scalar keys %unique_EC_hash > 0 ){# if valid hits found for cov and identity cut-off
		my ($out_file_EC_str, $out_file_desc_str);
		while (my ($valid_EC,$desc) = each %unique_EC_hash){
			 if ( ! defined $out_file_EC_str ){ $out_file_EC_str = $valid_EC.';'; }
			 else { $out_file_EC_str = $out_file_EC_str.$valid_EC.';';}
			 if ( ! defined $out_file_desc_str ){ $out_file_desc_str = $desc.' '; }
			 else { $out_file_desc_str = $out_file_desc_str.$desc.' ';}
		}
		$out_file_data = $out_file_data.$gene."\t$out_file_EC_str\t$out_file_desc_str\n";
	}

	# $out_file_data = $out_file_data.$gene."\t$EC\tSimilar to $valid_hit (DB= ".$DB." PERC_IDENTITY=".
	# 									sprintf ( "%.2f", $total_identity_perc / scalar @local_valid_hit_hsp_arr)
	# 									.", ALIGN_LENGTH ". $coverage_count .")\n";
	print STDERR "\n";
}

unless ( open( OFUNC, ">$out_file" ) ) {
	print STDERR "Cannot open $out_file\n";
	exit 1;
}
print OFUNC $out_file_data;
close(OFUNC);
