#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Dec 1, 2010

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

 getIntergenicReadingFramesGFF.pl - Get reading frames from intergenic regions 

=head1 SYNOPSIS

  % getIntergenicReadingFramesGFF.pl --fna file1.fna --gff file2.gff --minlen 30 --out out.faa
  
=head1 DESCRIPTION

 To find pseudogenes in intergenic regions of LAS. Using Refseq gene coordinates. Stopping
 translation if a STOP codon in encountered. The fasta header of proteins contain genome 
 coordinates required for mapping blastp hits back to the genome. 
 
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
my($fna,$gff,$len,$out,$i,$j,$rec,@gff_genes,@temp,$seqObj,$k,$l,%ctrs);

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
$out ||= "$i.translated.faa";

unless(open(INGFF,"<$gff")){print "not able to open $gff\n\n";exit 1;}
unless(open(OUT,">$out")){print "not able to open $out\n\n";exit 1;}

$ctrs{'genes'}=0;
$ctrs{'short-'}=0;
$ctrs{'short+'}=0;

# read in files
while($rec=<INGFF>){
	if($rec =~ /#/){next;}
	@temp=split("\t",$rec);
	if($temp[2] eq 'gene'){push @gff_genes, [split("\t",$rec)]; $ctrs{'genes'}++;}
}
close(INGFF);

$i = Bio::SeqIO->new('-file'=>$fna ,'-format' => 'fasta');
$seqObj=$i->next_seq();
foreach $i (0..($#gff_genes-1)){
	my($start,$end,$pos,@rf,$str,$rstr,$protObj,$tmpSeqObj);
	if(($gff_genes[$i][4]+1) < ($gff_genes[$i+1][3]-1)){#to deal with overlapping,adjacent gene calls
		#debugging
		#print STDERR "length : ",$gff_genes[$i+1][3]-$gff_genes[$i][4],"\n";
		$start=$gff_genes[$i][4]+1;
		$str=$seqObj->subseq($gff_genes[$i][4]+1,$gff_genes[$i+1][3]-1);
		#for pos strand, frames 0,1,2
		@rf=split(/TGA|TAA|TAG/,$str); $pos=0;
		foreach $j (@rf){
			if ((length $j) >= ($len*3)){#if above length cutoff
				for $k (0..2){
					$l=$seqObj->display_name.'start '.($start+index($str,$j,$pos)).
						"\|end ".($start+index($str,$j,$pos)+(length $j))."\|pos\|frame $k";
					$tmpSeqObj=Bio::Seq->new(-display_id =>$l, -seq =>$j);#new obj for protein
					$l=$tmpSeqObj->translate('*', 'X', $k);
					print OUT '>',$tmpSeqObj->display_name(),"\n",$l->seq(),"\n";
				}
			}
			else{
				#debugging 
				#print length $j," too short\n"; 
				#$ctrs{'short+'}++;
			}
			$pos=(length $j)+3;#incr pos for index search
		}
		#for comp strand, frames 0,1,2
		$end=$gff_genes[$i+1][3]-1;
		$rstr=$seqObj->trunc($gff_genes[$i][4]+1,$gff_genes[$i+1][3]-1)->revcom()->seq();
		@rf=split(/TGA|TAA|TAG/,$rstr); $pos=0;
		foreach $j (@rf){
			if ((length $j) >= ($len*3)){#if above length cutoff
				for $k (0..2){
					$l=$seqObj->display_name.'start '.($end-(index($rstr,$j,$pos)+(length $j))).
						"\|end ".($end-(index($rstr,$j,$pos)))."\|revcomp\|frame $k";
					$tmpSeqObj=Bio::Seq->new(-display_id =>$l, -seq =>$j);#new obj for protein
					$l=$tmpSeqObj->translate('*', 'X', $k);
					print OUT '>',$tmpSeqObj->display_name(),"\n",$l->seq(),"\n";
				}
			}
			else{
				#debugging
				#print length $j," too short\n";
				#$ctrs{'short-'}++;
			}
			$pos=(length $j)+3;#incr pos for index search
		}
	}
}
close(OUT);

#debugging
#print STDERR "Genes $ctrs{'genes'}\nShort on pos $ctrs{'short+'}\nShort on comp $ctrs{'short-'}\n";

exit;
