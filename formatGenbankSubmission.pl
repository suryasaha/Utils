#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Feb 5, 2011

use strict;
use warnings;
use Getopt::Long;
use POSIX;
eval {
	require Bio::SeqIO;
};
use Bio::SeqIO;

=head1 NAME

formatGenbankSubmission.pl - Prepare Fasta file for Genbank submission 

=head1 DESCRIPTION

http://www.ncbi.nlm.nih.gov/genbank/wgs.submit/
This script reads in a Fasta sequence file and creates .FSA and .AGP files for WGS Genbank 
submission. 

=head1 COMMAND-LINE OPTIONS

Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. 
Some options are mandatory (see below).

   --inFasta   <>  Fasta file with contigs/scaffolds (required)
   --header    <>  Header string for contigs (required)
   --minLen    <>  Minimum length for a contig (def 199bp)
   --Ns        <>  N's allowed in a contig as ambiguous bases. Scaffolds are split at for longer stretches of N's (recommended 10,required) 
      
=head1 AUTHOR

Surya Saha, ss2489@cornell.edu

=cut

my ($i,$j,$k,$subseq,$scaf,$header,$Ns,$mlen,@temp,@temp1,$ctr,$seq);

GetOptions (
	'inFasta=s' => \$scaf,
	'header=s' => \$header,
	'minLen:i' => \$mlen,
	'Ns=i' => \$Ns) or (system('pod2text',$0), exit 1);

# defaults and checks
defined($scaf) or (system('pod2text',$0), exit 1);
if (!(-e $scaf)){print STDERR "$scaf not found: $!\n"; exit 1;}
defined($header) or (system('pod2text',$0), exit 1);
$mlen ||= 199;
defined($Ns) or (system('pod2text',$0), exit 1);
$Ns ||=10;

my $in = Bio::SeqIO->new(-file=>$scaf, -format=>'Fasta');
unless(open(AGP,">${scaf}.agp")){print "not able to open ${scaf}.agp\n\n";exit 1;}
unless(open(FSA,">${scaf}.fsa")){print "not able to open ${scaf}.fsa\n\n";exit 1;}

print AGP "##agp-version	2.0
# ORGANISM: ??
# TAX_ID: ??
# ASSEMBLY NAME: ??
# ASSEMBLY DATE: DD-Month-YYYY
# GENOME CENTER: ??
# DESCRIPTION: Example AGP specifying the assembly of scaffolds from WGS contigs
";

$i=1;
while (my $obj = $in->next_seq()){
	$k=$j=1;
	$seq=$obj->seq();
	@temp=split(/n{${Ns},}/i,$seq);#case insensitive match to N's
	my($start,$end);
	foreach $subseq (@temp){
		if (length($subseq) >= $mlen){
			#FSA record
			print FSA ">Contig${i}.${j} $header\n"; 
			#print FSA $k,"\n";
			#@temp1=split(/(.{60})/,$k);
			#splitting into 60bp peices b4 printing
			@temp1= ($subseq =~ m/(.{1,60})/gs);
			foreach (@temp1) {chomp $_; print FSA $_."\n";}
			
			#AGP record, use index()
			#http://www.ncbi.nlm.nih.gov/projects/genome/assembly/agp/AGP_Specification_v2.0.shtml
			if($j==1){#only 1 object in component/ no splitting of scaffold/ No >10N's
				$start=index($seq,$subseq)+1;
				$end= $start+length($subseq)-1;
				print AGP "Contig${i}\t$start\t$end\t",$k++,"\tW\tContig${i}.${j}\t1\t";
				print AGP length($subseq),"\t\+";
				print AGP "\n";
			}
			elsif($j>1){#account for N's
				#print N row 
				$start=index($seq,$subseq)+1;
				print AGP "Contig${i}\t",($end+1),"\t",($start-1),"\t";
				print AGP $k++,"\tN\t",(($start-1)-($end+1)+1),"\tscaffold\tyes\tpaired-ends\n";
				
				#print contig row
				$end= $start+length($subseq)-1;
				print AGP "Contig${i}\t$start\t$end\t",$k++,"\tW\tContig${i}.${j}\t1\t";
				print AGP length($subseq),"\t\+";
				print AGP "\n";
			}
			
			$j++;
		}
		else
		{
			print STDERR "Substring of ".$obj->description()." ignored\n";
		}
	}
	$i++;
}

close(AGP); close (FSA);
print STDERR "Add info to AGP file\n";
exit;
