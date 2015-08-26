#!/usr/bin/perl -w
# PPath@Cornell/BTI
# Surya Saha 08/23/2015 
# Purpose: 


unless (@ARGV == 1){
	print "USAGE: $0 <.tbl> \n";
	print "Will break if tRNA is the first annotation in the TBL file.\nHandles CDS and tRNA features and ignores sig_peptide features as their coordinates need to be in amino acid space.\nManually remove score line for repeat regions.";
	exit;
}

use strict;
use warnings;

my ($ifname,$rec,$i);

$ifname=$ARGV[0];
unless(open(IN,"<$ifname")){print "not able to open ".$ifname."\n\n";exit;}
unless(open(OUT,">${ifname}.fixed")){print "not able to open ".$ifname.".fixed\n\n";exit;}

#WAS
#>Feature scaffold10_size139168
#60	335	CDS
#			inference	ab initio prediction:Prodigal:2.60
#			inference	protein motif:Pfam:PF08388.5
#			locus_tag	WY13_00001
#			product	Group II intron, maturase-specific domain
#488	1945	CDS
#			gene	fusA_1
#			inference	ab initio prediction:Prodigal:2.60
#			inference	similar to AA sequence:UniProtKB:P80868
#			locus_tag	WY13_00002
#			product	Elongation factor G
#312885	312960	tRNA
#			inference	COORDINATES:profile:Aragorn:1.2
#			protein_id	gnl|AngenentCornell|WX72_00887
#			locus_tag	WX72_00887
#			product	tRNA-Pro(tgg)

#MODIFIED
#>Feature lcl|scaffold10_size139168
#60	335	gene
#			locus_tag	WY13_00001
#60	335	CDS
#			product	Group II intron, maturase-specific domain
#			transl_table	11
#			protein_id	gnl|ncbi|WY13_00001
#			inference	ab initio prediction:Prodigal:2.60
#			inference	protein motif:Pfam:PF08388.5
#488	1945	gene
#			gene	fusA_1
#			locus_tag	WY13_00002
#488	1945	CDS
#			product	Elongation factor G
#			transl_table	11
#			protein_id	gnl|ncbi|WY13_00002
#			inference	ab initio prediction:Prodigal:2.60
#			inference	similar to AA sequence:UniProtKB:P80868
#312885	312960	gene
#			locus_tag	WX72_00887
#312885	312960	tRNA
#			inference	COORDINATES:profile:Aragorn:1.2
#			protein_id	gnl|AngenentCornell|WX72_00887
#			product	tRNA-Pro(tgg)

my @data;
my $cds_trna_counter = 0;
my $scaffold_counter = 0;
my $first = 1;
my $skip = 0;#skip signal peptide annotations

while($rec=<IN>){
	if ($rec =~ /^>/){
		print OUT $rec; #fasta header
		$scaffold_counter++;
		next;
	}
	
	if ((($rec =~ /CDS/) || ($rec =~ /\stRNA\s/)) && !($first)) { #print prev gene and CDS/tRNA record, skip first CDS as no data recorded yet
		my $header = shift @data;
		
		#gene lines
		my $gene_header = $header;
		if ( $gene_header =~ /CDS/){
			$gene_header =~ s/CDS/gene/g;	
		}
		elsif( $gene_header =~ /\stRNA\s/){
			$gene_header =~ s/tRNA/gene/g;	
		}
		
		print OUT $gene_header;
		my @filtered_data;
		while (my $line = shift @data){
			if ($line =~ /\sgene\s/){ print OUT $line;} #gene line
			elsif ($line =~ /\tlocus_tag\t/){ 
				print OUT $line;
				my @locus_tag_arr = split ("\t", $line);
				my $locus_tag = $locus_tag_arr[4];
				my $protein_id_line = "			protein_id	gnl|AngenentCornell|$locus_tag";
				push @filtered_data, $protein_id_line;
			}
			else{ push @filtered_data, $line;}
		}
		
		#cds lines
		print OUT $header;
		foreach my $line (@filtered_data){
			print OUT $line;
		}
		
		$cds_trna_counter++;
		#reset
		@data = ();
		@filtered_data = ();
		$skip = 0;
		
		#store for next
		push @data, $rec;
	}
	else{
		if ($rec =~ /sig_peptide/){
			$skip = 1;
			next;
		}
		if (!$skip){
			push @data, $rec;
		}
		$first = 0;
	}
}

#last cds record
my $cds_header = shift @data;
#gene lines
my $gene_header = $cds_header;
$gene_header =~ s/CDS/gene/g;	
print OUT $gene_header;
my @filtered_data;
while (my $line = shift @data){
	if ($line =~ /\tgene\t/){ print OUT $line;} #gene line
	elsif ($line =~ /\tlocus_tag\t/){ 
		print OUT $line;
		my @locus_tag_arr = split ("\t", $line);
		my $locus_tag = $locus_tag_arr[4];
		my $protein_id_line = "			protein_id	gnl|AngenentCornell|$locus_tag";
		push @filtered_data, $protein_id_line;
	}
	else{ push @filtered_data, $line;}
}

#cds lines
print OUT $cds_header;
foreach my $line (@filtered_data){
	print OUT $line;
}

print STDERR "$scaffold_counter scaffolds parsed\n";
print STDERR "$cds_trna_counter CDSs and tRNAs parsed\n";


close (IN);
close (OUT);
