#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Dec 2, 2010

use strict;
use warnings;
use Getopt::Long;
use Bio::Perl;
use Bio::SeqIO;
eval {require Bio::SeqIO; };
if ( $@ ) {
print STDERR "Cannot find Bio::SeqIO\n";
print STDERR "You will need the bioperl-run library to run SeqIO\n";
return 0;
}

=head1 NAME

 getIntergenicTranslations.pl - Get reading frames from intergenic regions 

=head1 SYNOPSIS

  % getIntergenicTranslations.pl --fna file1.fna --gff file2.gff --minlen 30 --out out.faa
  
=head1 DESCRIPTION

 Translating FULL intergenic DNA to find pseudogenes in intergenic regions of LAS. 
 Using Refseq gene coordinates. Stopping translation if a STOP codon in encountered. 
 The fasta header of proteins contain genome coordinates required for mapping blastp 
 hits back to the genome. 
 
=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --fna    <.fna>  Genome sequence in fasta format (required)
   --gff    <.gff>	Refseq GFF file (required)
   --minlen <30>	Minimum length of proteins generated
   --out    <.faa>  Name of output file

=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut
my($fna,$gff,$len,$out,$i,$j,$rec,@gff_genes,@temp,$seqObj,$k,$l);

GetOptions (
	'fna=s' => \$fna,
	'gff=s' => \$gff,
	'minlen:i' => \$len,
	'out:s'    => \$out) or (system('pod2text',$0), exit 1);

defined($fna) or (system('pod2text',$0), exit 1);
if (!(-e $fna)){print STDERR "$fna not found: $!\n"; exit 1;}
defined($gff) or (system('pod2text',$0), exit 1);
if (!(-e $gff)){print STDERR "$gff not found: $!\n"; exit 1;}
$len||=30;
$i=$fna;
$i=~ s/.fna//;
$out ||= "$i.intergenic.translated.faa";

unless(open(INGFF,"<$gff")){print "not able to open $gff\n\n";exit 1;}
unless(open(OUT,">$out")){print "not able to open $out\n\n";exit 1;}

# read in files
while($rec=<INGFF>){
	if($rec =~ /#/){next;}
	@temp=split("\t",$rec);
	if($temp[2] eq 'gene'){push @gff_genes, [split("\t",$rec)];}
}
close(INGFF);

$i = Bio::SeqIO->new('-file'=>$fna ,'-format' => 'fasta');
$seqObj=$i->next_seq();
foreach $i (0..($#gff_genes-1)){
	my($start,$end,@rf,$protObj,$tmpSeqObj);
	#for pos strand, frames 0.1,2
	$start=$gff_genes[$i][4]+1;
	$end=$gff_genes[$i+1][3]+1;
	if(($gff_genes[$i][4]+1) < ($gff_genes[$i+1][3]-1)){#to deal with overlapping,adjacent gene calls
		if ((($gff_genes[$i+1][3])-($gff_genes[$i][4])) >= ($len*3)){
			for $k (0..2){
				$l=$seqObj->display_name."start $start\|end $end\|pos|frame $k";
				$tmpSeqObj=Bio::Seq->new(-display_id =>$l, 
					-seq =>$seqObj->subseq($gff_genes[$i][4]+1,$gff_genes[$i+1][3]-1));
				$l=$tmpSeqObj->translate('*', 'X', $k);
				print OUT '>',$tmpSeqObj->display_name(),"\n",$l->seq(),"\n";
			}
					
			#for comp strand, frames 0,1,2
			for $k (0..2){
				$l=$seqObj->display_name."start $start\|end $end\|revcomp|frame $k";
				$tmpSeqObj=Bio::Seq->new(-display_id =>$l, 
					-seq =>$seqObj->trunc($gff_genes[$i][4]+1,$gff_genes[$i+1][3]-1)->revcom()->seq());
				$l=$tmpSeqObj->translate('*', 'X', $k);
				print OUT '>',$tmpSeqObj->display_name(),"\n",$l->seq(),"\n";
			}
		}
	}
}
close(OUT);


exit;