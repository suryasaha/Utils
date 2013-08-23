#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Feb 9, 2012

use lib '/home/surya/bin/modules';
use SS;

use strict;
use warnings;
use Getopt::Long;


=head1 NAME

 gff2MFasta.pl - Write out fasta sequences for regions listed in GFF file 

=head1 SYNOPSIS

  % gff2MFasta.pl --fna file1.fna --gff file2.gff --out out.fna
  
=head1 DESCRIPTION

 To get regions of reference sequence highlighted in Artemis. 
 
=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --fna    <.fna>  Genome sequence in fasta format (required)
   --gff    <.gff>  Artemis generated?? GFF file (required)
   --minlen <500>   Minimum length of illuminated region, if screening
   --out    <.fna>  Name of output mfasta file

=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut

my($fna,$gff,$scr,$out,$mlen,@maskedseq,$seq,$i,$j,$rec,@temp,$ctr,%illumreg);

GetOptions (
	'fna=s' => \$fna,
	'gff=s' => \$gff,
	'minlen:i' => \$mlen,
	'out:s' => \$out) or (system('pod2text',$0), exit 1);

defined($fna) or (system('pod2text',$0), exit 1);
if (!(-e $fna)){print STDERR "$fna not found: $!\n"; exit 1;}
defined($gff) or (system('pod2text',$0), exit 1);
if (!(-e $gff)){print STDERR "$gff not found: $!\n"; exit 1;}
$mlen ||= 500;
$i=$gff; $i=~ s/.gff$//;
$out ||= "$i\.mfasta";
unless(open(INGFF,"<$gff")){print "not able to open $gff\n\n";exit 1;}
unless(open(INFAS,"<$fna")){print "not able to open $fna\n\n";exit 1;}
unless(open(OUT,">$out")){print "not able to open $out\n\n";exit 1;}

# read in files
$seq='';
while($rec=<INFAS>){
	if($rec =~ />/){next;}
	$rec=~ s/\s*//g;#clean
	$seq=$seq.$rec;
}
close(INFAS);

#gff_seqname	artemis	exon	12136	12720	.	+	.	ID=CDS:12136..12720
#gff_seqname	artemis	exon	69917	70358	.	+	.	ID=CDS:69917..70358
#gff_seqname	artemis	exon	71700	72604	.	+	.	ID=CDS:71700..72604
# read in files
$ctr=0;
while($rec=<INGFF>){
	if($rec =~ /#/){next;}
	@temp=split("\t",$rec);

	if($temp[8] ne ''){
		chomp $temp[8]; 
		print OUT "\>$temp[8]\:pos $temp[3]-$temp[4] \:length ",$temp[4]-$temp[3]+1,"\n";
	}
	else{ print OUT "\>$ctr\n"}
	if(($temp[6] eq '+') || ($temp[6] eq '.')){
		print OUT substr($seq,$temp[3]-1,(($temp[4]-1)-($temp[3]-1)+1)),"\n";#coordinate space to index space
	}
	elsif($temp[6] eq '-'){
		print OUT &SS::revcomp(substr($seq,$temp[3]-1,(($temp[4]-1)-($temp[3]-1)+1))),"\n";#coordinate space to index space
	}
	$ctr++;		
}
close(INGFF);
print STDERR "$ctr records processed\n";

exit;