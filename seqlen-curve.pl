#!/usr/bin/perl -w
# MGEL
# Surya Saha 10/24/05
# reading fasta file and writing out length histogram, quantiles, summary and stem chart 

use strict;
use warnings;
use IO::File;
use Switch;

unless (@ARGV == 1){
	print "USAGE: $0 <input fasta file>\n";
	exit;
}

#declarations
my ($i,$j,$data,$len,$srcfname,$count,%SeqData,$cmd,$ctr_0to20,$ctr_21to30,$ctr_31to40,
$ctr_41to50,$ctr_51to60,$ctr_61to70,$ctr_tot);

#init variables
$count=0;
$srcfname=$ARGV[0];
chomp ($srcfname);

unless(open(INFILEDATA,"<$srcfname")){print "not able to open ".$srcfname."\n\n";exit;}
unless(open(R,">$srcfname-seqlencurve.R")){print "not able to open $srcfname-seqlencurve.R\n";exit 1;}
unless(open(OUT,">$srcfname.len_summary")){print "not able to open $srcfname.len_summary\n";exit 1;}

$cmd="sink(\"${srcfname}\.R\.out\")\npdf(\"${srcfname}\.hist\.pdf\")\nseqlens<-c(";
#$ctr_0to20=$ctr_21to30=$ctr_31to40=$ctr_41to50=$ctr_51to60=$ctr_61to70=$ctr_tot=0;
while($data=<INFILEDATA>){
	if($data=~ /^>/ or eof) {
		if (!eof) {$count++;}##do not increment count for EOF
		
		if($count>1){
			if(exists $SeqData{$len}){$SeqData{$len}++}
			else {$SeqData{$len}=1}
			$cmd=$cmd."$len,";
#			switch($len){
#				case [0..20]{$ctr_0to20++;}
#				case [21..30]{$ctr_21to30++;}
#				case [31..40]{$ctr_31to40++;}
#				case [41..50]{$ctr_41to50++;}
#				case [51..60]{$ctr_51to60++;}
#				case [61..70]{$ctr_61to70++;}
#			}
			$ctr_tot++;
		}
		#init variables for this sequence
		$len=0;
		next;
	}
	$data=~ s/\s//g;
	$len+=length $data;
}
close (INFILEDATA);

$cmd=~ s/,$//; $cmd =$cmd."\)\nhist(seqlens, xlab\=\"Sequence lengths\"\, main\=\"Length profile\"\)\n";
$cmd=$cmd."print\(\"SUMMARY\"\)\nsummary\(seqlens\)\nprint\(\"QUANTILES\"\)\nquantile\(seqlens\,probs\=seq\(0\,1\,0.05\)\)\n";
$cmd=$cmd."print\(\"STEM DIAGRAM\"\)\nstem\(seqlens\)\n";
print R $cmd; close (R);
system("R CMD BATCH $srcfname-seqlencurve.R");

print OUT "Length Summary\n\nTotal sequences: $ctr_tot\n";
#print OUT "Length Summary\n\nTotal sequences: $ctr_tot\nLength 1 to 20: $ctr_0to20\nLength 21 to 30: $ctr_21to30\n";
#print OUT "Length 31 to 40: $ctr_31to40\nLength 41 to 50: $ctr_41to50\nLength 51 to 60: $ctr_51to60";
#print OUT "\nLength 61 to 70: $ctr_61to70\n\nLength\tCount\n";
print OUT "\n\nLength\tCount\n";

foreach $i (sort {$a <=> $b} (keys(%SeqData))){ print OUT "$i\t$SeqData{$i}\n";}
print OUT "\n\n";
close(OUT);

exit;