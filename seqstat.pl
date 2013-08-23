#!/usr/bin/perl -w
# MGEL
# Surya Saha 10/02/05
# reading fasta files and writing out sequence statistics for each seq and common
# use tips from "comp gene finding in plants" compositional analysis section

use strict;
use warnings;
use IO::File;
use Class::Struct;

unless (@ARGV == 1){
	print "USAGE: $0 <input fasta file>\n";
	exit;
}

#declarations
my ($minA,$minT,$minG,$minC,$minN,$minGC,$maxA,$maxT,$maxG,$maxC,$maxN,$maxGC,$sA,$sT,$sG,$sC,$sN,$sGC);
my ($A,$T,$G,$C,$N,$GC,$mA,$mT,$mG,$mC,$mN,$mGC,$i,$srcfname,$destfname,$seqname,$count,$data,$len,$totlen,@SeqDataArr);

#declaring the struct
struct ('SeqData',{name=>'$',A=>'$',T=>'$',G=>'$',C=>'$',N=>'$',GC=>'$'});

$srcfname=$ARGV[0];
chomp ($srcfname);

unless(open(INFILEDATA,"<$srcfname")){print "not able to open ".$srcfname."\n\n";exit;}

#init variables
$seqname='';
$count=0;
$sA=$sT=$sG=$sC=$sN=$sGC=$totlen=0;

while($data=<INFILEDATA>){
#	if($data=~ /^>/ or eof) {
	if($data=~ /^>/) {
		##init vars for median
		if($count==1){
			$minA=$maxA=$A;	$minT=$maxT=$T;
			$minG=$maxG=$G;	$minC=$maxC=$C;
			$minN=$maxN=$N;
			$minGC=$maxGC=$G+$C;##using $g and $C as $GC has not been assigned a value yet
		}	
		if($count>0){##printing the final values for the sequence
			#$len+=length $data;
			print "\n";
			print $seqname," len: ",$len,"\n";
			#print $data,"\n";
			$i=(100*$A/$len); $i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
			print "A: ",$i,"% ($A)\n";
			$i=(100*$T/$len);
			$i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
			print "T: ",$i,"% ($T)\n";
			$i=(100*$G/$len);
			$i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
			print "G: ",$i,"% ($G)\n";
			$i=(100*$C/$len);
			$i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
			print "C: ",$i,"% ($C)\n";
			if ($N>0) {##make sure that no of N>0
				$i=(100*$N/$len); $i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
				print "N: ",$i,"% ($N)\n";
			}
			else{
				print "N: 0.000% (0)\n";
			}
			$GC=$G+$C;
			$i=(100*$GC/$len); $i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;			
			print "GC: ",$i,"% ($GC)";
			
			##for median
			if ($A>$maxA){$maxA=$A;}	if ($A<$minA){$minA=$A;}
			if ($T>$maxT){$maxT=$T;}	if ($T<$minT){$minT=$T;}
			if ($G>$maxG){$maxG=$G;}	if ($G<$minG){$minG=$G;}
			if ($C>$maxC){$maxC=$C;}	if ($C<$minC){$minC=$C;}
			if ($N>$maxN){$maxN=$N;}	if ($N<$minN){$minN=$N;}
			if ($GC>$maxGC){$maxGC=$GC;}	if ($GC<$minGC){$minGC=$GC;}
			
			##for calculating the mean at the end
			$sA+=$A;	$sT+=$T;
			$sG+=$G;	$sC+=$C;
			if ($N>0) {$sN+=$N;}
			$sGC+=$GC;
			
			##for calculating standard deviation at the end
			$SeqDataArr[$count-1]=SeqData->new(name=>$seqname,A=>$A,T=>$T,
						G=>$G,C=>$C,N=>$N,GC=>$GC);
						
			## for calculating the avg length
			$totlen+=$len;
		}

		$seqname=$data;	$seqname=~ s/^>//;	chomp $seqname;
		if (!eof) {$count++;}##do not increment count for EOF
		#init variables for this sequence
		$A=$T=$G=$C=$N=$GC=$len=0;
		next;
	}
	
	##actually count the contents of the sequence
	for($i=0;$i< length($data);$i++){
		my $temp=substr ($data,$i,1);
		if ($temp eq "A" or $temp eq "a") {$A++;} if ($temp eq "T" or $temp eq "t") {$T++;}
		if ($temp eq "G" or $temp eq "g") {$G++;} if ($temp eq "C" or $temp eq "c") {$C++;}
		if ($temp eq "N" or $temp eq "n") {$N++;}
	}
	$data=~ s/\s//g;
	$len+=length $data;
}
close (INFILEDATA);

#print last seq data
print "\n";
print $seqname," len: ",$len,"\n";
#print $data,"\n";
$i=(100*$A/$len); $i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
print "A: ",$i,"% ($A)\n";
$i=(100*$T/$len);
$i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
print "T: ",$i,"% ($T)\n";
$i=(100*$G/$len);
$i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
print "G: ",$i,"% ($G)\n";
$i=(100*$C/$len);
$i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
print "C: ",$i,"% ($C)\n";
if ($N>0) {##make sure that no of N>0
	$i=(100*$N/$len); $i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;
	print "N: ",$i,"% ($N)\n";
}
else{
	print "N: 0.000% (0)\n";
}
$GC=$G+$C;
$i=(100*$GC/$len); $i=~ s/(^\d{1,}\.\d{3})(.*$)/$1/;			
print "GC: ",$i,"% ($GC)";

##for median
if ($A>$maxA){$maxA=$A;}	if ($A<$minA){$minA=$A;}
if ($T>$maxT){$maxT=$T;}	if ($T<$minT){$minT=$T;}
if ($G>$maxG){$maxG=$G;}	if ($G<$minG){$minG=$G;}
if ($C>$maxC){$maxC=$C;}	if ($C<$minC){$minC=$C;}
if ($N>$maxN){$maxN=$N;}	if ($N<$minN){$minN=$N;}
if ($GC>$maxGC){$maxGC=$GC;}	if ($GC<$minGC){$minGC=$GC;}

##for calculating the mean at the end
$sA+=$A;	$sT+=$T;
$sG+=$G;	$sC+=$C;
if ($N>0) {$sN+=$N;}
$sGC+=$GC;

##for calculating standard deviation at the end
$SeqDataArr[$count-1]=SeqData->new(name=>$seqname,A=>$A,T=>$T,
			G=>$G,C=>$C,N=>$N,GC=>$GC);
			
## for calculating the avg length
$totlen+=$len;


$mA=int($sA/$count); $mT=int($sT/$count);
$mG=int($sG/$count); $mC=int($sC/$count);
$mN=int($sN/$count); $mGC=int($sGC/$count);

print "\n\nTotal : ",$count," sequences\nAvg Length: ";
printf "%.3f",$totlen/$count;

print "\nTotal values:\n";
print "Bases :",$totlen,"\n";
print "A :",$sA,"\nT :",$sT,"\n"; print "G :",$sG,"\nC :",$sC,"\n";
if ($mN>0) {print "N :",$sN,"\n";}

print "\nMean values:\n";
print "A :",$mA,"\nT :",$mT,"\n"; print "G :",$mG,"\nC :",$mC,"\n";
if ($mN>0) {print "N :",$mN,"\n";}

print "GC:",$mGC,"\nMedian values:\n";
print "A: ",int(($maxA+$minA)/2),"\nT: ",int(($maxT+$minT)/2),"\n";
print "G: ",int(($maxG+$minG)/2),"\nC: ",int(($maxC+$minC)/2),"\n";
if ($mN>0) {print "N: ",int(($maxN+$minN)/2),"\n";}
print "GC: ",int(($maxGC+$minGC)/2);

print "\nRanges:\n";
print "max A: ",$maxA,"\t","min A: ",$minA,"\n"; print "max T: ",$maxT,"\t","min T: ",$minT,"\n";
print "max G: ",$maxG,"\t","min G: ",$minG,"\n"; print "max C: ",$maxC,"\t","min C: ",$minC,"\n";
print "max N: ",$maxN,"\t","min N: ",$minN,"\n"; print "max GC: ",$maxGC,"\t","min GC: ",$minGC;

print "\nStandard deviations:\n";
##reusing old variables
$sA=$sT=$sG=$sC=$sN=$sGC=0;

## A
for ($i=0;$i<@SeqDataArr;$i++){
	my $temp=$SeqDataArr[$i]->A-$mA;
	##reusing old variables
	$sA+=$temp*$temp;
}
$sA=$sA/$count; $sA=abs(sqrt($sA));
print "A: "; printf "%.3f",$sA; print "\n";

## T
for ($i=0;$i<@SeqDataArr;$i++){
	my $temp=$SeqDataArr[$i]->T-$mT;
	##reusing old variables
	$sT+=$temp*$temp;
}
$sT=$sT/$count; $sT=abs(sqrt($sT));
print "T: "; printf "%.3f",$sT; print "\n";

## G
for ($i=0;$i<@SeqDataArr;$i++){
	my $temp=$SeqDataArr[$i]->G-$mG;
	##reusing old variables
	$sG+=$temp*$temp;
}
$sG=$sG/$count; $sG=abs(sqrt($sG));
print "G: "; printf "%.3f",$sG; print "\n";

## C
for ($i=0;$i<@SeqDataArr;$i++){
	my $temp=$SeqDataArr[$i]->C-$mC;
	##reusing old variables
	$sC+=$temp*$temp;
}
$sC=$sC/$count; $sC=abs(sqrt($sC));
print "C: "; printf "%.3f",$sC; print "\n";

## N
for ($i=0;$i<@SeqDataArr;$i++){
	my $temp=$SeqDataArr[$i]->N-$mN;
	##reusing old variables
	$sN+=$temp*$temp;
}
$sN=$sN/$count; $sN=abs(sqrt($sN));
print "N: "; printf "%.3f",$sN; print "\n";

## GC
for ($i=0;$i<@SeqDataArr;$i++){
	my $temp=$SeqDataArr[$i]->GC-$mGC;
	##reusing old variables
	$sGC+=$temp*$temp;
}
$sGC=$sGC/$count; $sGC=abs(sqrt($sGC));
print "GC: "; printf "%.3f",$sGC; print "\n\n";

exit;
