#!/usr/bin/perl -w
# Solgenomics@BTI
# Surya Saha Oct 8, 2019
# Purpose: Add formatted DcitrXXgYYYYY.version.isoform mRNA and gene IDs to a GFF with maker genes. Does NOT work for and Apollo genes since their IDs are all random numbers. mRNA index file is created with update_maker_names_fasta_chrlocs.pl or update_maker_names_fasta.pl 

use File::Slurp;

unless (@ARGV == 2){
	print "USAGE: $0 <mRNA index with Maker and OGS id> <GFF file>\n";
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
	$mRNA_index_hash{$arr[0]} = $arr[1];								#snap-DC3.0sc00-processed-gene-3.9-mRNA-1	Dcitr00g01000.1.1
}

my @gene_arr;
my $mRNA_id;
my $gene_processed_flag = 0;												#remember if gene record was already printed for mRNA 1

@lines = split (/\n/, $input_gff);
foreach my $line (@lines){
	if ( $line=~ m/^#/ ){
		print OUTGFF $line."\n";
		next;
	}
	elsif ( $line=~ m/\tgene\t/ ){
		@gene_arr = split (/\t/, $line);
		undef $mRNA_id;
		$gene_processed_flag = 0;											#reset flag
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
		
		$line =~ s/${mRNA_id}/$mRNA_index_hash{$mRNA_id}/g;					#fix ID and Name
		my $parent = $mRNA_index_hash{$mRNA_id};
		$parent =~ s/\.\d+$//;
		
		$line =~ s/Parent\=\S+\;/Parent=$parent\;/;							#fix parent
		
		if ( !$gene_processed_flag ){
			for my $val (0..7){												#print gene record
				print OUTGFF $gene_arr[$val]."\t";
			}
			print OUTGFF 'ID='.$parent.';Name='.$parent."\n";
			$gene_processed_flag = 1;										#set flag once printed
		}
		
		print OUTGFF $line."\n";											#print mRNA record
		
		print STDERR "$parent done..\n"
	}
	else{#all other GFF records
		#fix Name and Parent
		$line =~ s/${mRNA_id}/$mRNA_index_hash{$mRNA_id}/g;

		if ( $line =~ m/,/ ){												#multi parent child
			my @arr = split (/\t/, $line);
			my @attrib_arr = split (/\;/, $arr[8]);
			foreach my $attrib (@attrib_arr){
				if ( $attrib =~ /^Parent\=/ ){
					$attrib =~ s/^Parent\=//;
					my @parents = split ( /,/, $attrib);

					foreach my $parent (@parents){
						if ( $parent !~ /^Dcitr/ ){							#do if not Dcitr id, so only for maker/apollo id
							if (!exists $mRNA_index_hash{$parent}) { die "$parent parent not found in hash"; }
							$line =~ s/${parent}/$mRNA_index_hash{$parent}/g;
						}						
					}
				}			
			}
		}
		print OUTGFF $line."\n";
	}
}

close (OUTGFF);