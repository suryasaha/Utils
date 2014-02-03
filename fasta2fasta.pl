#!/usr/bin/perl -w
# MGEL
# Surya Saha 05/28/04
# reading fasta file,writing out fasta file, names from given file
# seq not found to err file

use strict;
use warnings;

unless (@ARGV == 3){
	print "USAGE: $0 <input fasta file>  <destination fasta file> <listfile>\n";
	exit;
}

print "WARNING : make sure that the list file has an empty line at the end\n";
print "WARNING : make sure that the list file has only UNIQUE names\n";

my $srcfname=$ARGV[0];
chomp ($srcfname);
my $destfname=$ARGV[1];
chomp ($destfname);
my $listfname=$ARGV[2];
chomp ($listfname);
my $seqname='';
my $indata='';
my $haderr=0;

unless(open(OUTFILEDATA,">$destfname")){print "not able to open ".$destfname."\n\n";exit;}
unless(open(LISTFILEDATA,$listfname)){print "not able to open ".$listfname."\n\n";exit;}

while($seqname=<LISTFILEDATA>){# for each seq name in listfile
	#$seqname=~ s/\s*//; #removing white space at end
	chomp $seqname;
	unless(open(INFILEDATA,$srcfname)){print "not able to open ".$srcfname."\n\n";exit;}
	my $found=0;
	my $flag=0;
	while ($indata=<INFILEDATA>){# input file loop
		#chomp $indata;
		my $tmpdata=$indata;
		#$tmpdata=~ s/\s*//; #removing white space 
		if($flag==0 && ($tmpdata=~ /$seqname/)){# match seq name with > included
		#if($flag==0 && ($indata eq ">".$seqname)){# match seq name with > included
			print OUTFILEDATA $indata;
			$flag=1; #set flag for next loop
			$found=1;
			next;
		}
		elsif ($flag==1 and $found==1 and ! ($indata=~ />/)){
			print OUTFILEDATA $indata;
			next;
		}
		elsif ($flag==1 and $found==1 and $indata=~ />/){
			#$flag=0; #reset flag for next sequence in list file
			goto OUT;
		}
	}
	OUT:
	close INFILEDATA;
	
	if ($found==0){
		unless(open(ERRFILEDATA,">>$destfname.notfound"))
			{print "not able to open ".$destfname."notfound\n\n";exit;}
		print ERRFILEDATA $seqname;
		#print $seqname." not found!!\n";
		close ERRFILEDATA;
		$haderr=1;
	}
}

if ($haderr==1){
	print "\nsequences not found are in ".$destfname.".notfound file\n";
}

close OUTFILEDATA;
close LISTFILEDATA;
exit;
