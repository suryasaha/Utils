#!/usr/bin/perl -w
# Solgenomics@BTI
# Surya Saha Oct 8, 2019
# Purpose: Add formatted DcitrXXgYYYYY.version.isoform mRNA and gene IDs to a GFF with maker and Apollo genes

use File::Slurp;

unless (@ARGV == 2){
	print "USAGE: $0 <mRNA index> <GFF file>\n";
	exit;
}

use strict;
use warnings;

my $input_mRNA_index = read_file($ARGV[0]) or die "Could not read ".$ARGV[0]."\n";
my $input_gff = read_file($ARGV[1]) or die "Could not read ".$ARGV[1]."\n";


unless(open(OUTGFF,">formatted.".$ARGV[1])){print "not able to open formatted.".$ARGV[1]."\n\n";exit;}

my %mRNA_index_hash;
my @lines = split (/\n/, $input_mRNA_index);
foreach my $line (@lines){
	my @arr = split (/\t/, $line);
	$mRNA_index_hash{$arr[0]} = $arr[1];
}

my @gene_arr;
my $mRNA_id;

@lines = split (/\n/, $input_gff);
foreach my $line (@lines){
	if ( $line=~ m/^#/ ){
		print OUTGFF $line."\n";
		next;
	}
	elsif ( $line=~ m/\tgene\t/ ){
		@gene_arr = split (/\t/, $line);
		undef $mRNA_id;
	}
	elsif ( $line=~ m/\tmRNA\t/ ){
		my @arr = split (/\t/, $line);
		my @attrib_arr = split (/\;/, $arr[8]);
		foreach my $attrib (@attrib_arr){
			if ( $attrib =~ /^ID\=/ ){
				$attrib =~ s/^ID\=//;
				$mRNA_id = $attrib;
				last;
			}			
		}
		if (!exists $mRNA_index_hash{$mRNA_id}) { die "$mRNA_id not found in hash"; }
		#fix ID and Name
		$line =~ s/${mRNA_id}/$mRNA_index_hash{$mRNA_id}/g;
		my $parent = $mRNA_index_hash{$mRNA_id};
		$parent =~ s/\.\d+$//;
		#fix parent
		$line =~ s/Parent\=\S+\;/Parent=$parent\;/;
		
		#print gene record
		for my $val (0..7){
			print OUTGFF $gene_arr[$val]."\t";
		}
		print OUTGFF 'ID='.$parent.';Name='.$parent."\n";
		#@gene_arr = ();
		
		#print mRNA record
		print OUTGFF $line."\n";
		
		print STDERR "$parent done..\n"
	}
	else{#all other GFF records
		#fix Name and Parent
		$line =~ s/${mRNA_id}/$mRNA_index_hash{$mRNA_id}/g;

		#multi parent child
		if ( $line =~ m/,/ ){
			my @arr = split (/\t/, $line);
			my @attrib_arr = split (/\;/, $arr[8]);
			foreach my $attrib (@attrib_arr){
				if ( $attrib =~ /^Parent\=/ ){
					$attrib =~ s/^Parent\=//;
					my @parents = split ( /,/, $attrib);
					foreach my $parent (@parents){
						#do if maker/apollo id
						if ( $parent !=~ /^Dcitr/ ){
							if (!exists $mRNA_index_hash{$parent}) { die "$parent parent not found in hash"; }
							$line =~ s/${parent}/$mRNA_index_hash{$parent}/;
						}						
					}
				}			
			}
		}


		print OUTGFF $line."\n";
	}
}




close (OUTGFF);

