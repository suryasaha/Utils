#!/usr/bin/perl -w
# MGEL
# Surya Saha 05/28/04
# reading fasta file,writing out fasta file, names from given file
# seq not found to .notfound file

use strict;
use warnings;

unless (@ARGV == 3){
	print "USAGE: $0 <input fasta file>  <destination fasta file> <listfile>\n";
	print "Can handle special characters in sequence names but will NOT use them for comparison\n";
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
my $fasta='';
my $seqname='';
my $haderr=0;

unlink "$destfname.notfound";
unlink $destfname;

unless(open(OUTFILEDATA,">$destfname")){print "not able to open ".$destfname."\n\n";exit;}
unless(open(LISTFILEDATA,$listfname)){print "not able to open ".$listfname."\n\n";exit;}

while($seqname=<LISTFILEDATA>){# for each seq name in listfile
	my $rawseqname=$seqname;
	#print STDERR "Before trimming list ".$seqname;
	$seqname=~ s/\s*//g; #removing white space
	$seqname =~ s/\W*//g; #removing non alphanumeric or _ , non-word
	#print STDERR "Post trimming list ".$seqname."\n";	
	unless(open(INFILEDATA,$srcfname)){print "not able to open ".$srcfname."\n\n";exit;}
	my $found=0;
	my $flag=0;
	while ($fasta=<INFILEDATA>){# input fasta loop
		#chomp $fasta;
		my $tmpdata=$fasta;
		
		if (($flag==0) && ($tmpdata =~ /^>/)){
			#print STDERR "Before trimming ".$tmpdata;
			$tmpdata =~ s/\s*//g; #removing white space
			$tmpdata =~ s/\W*//g;
			#print STDERR "Post trimming ".$tmpdata."\n";

			if($flag==0 && ($tmpdata eq $seqname)){# match seq name with > included
				print OUTFILEDATA $fasta;
				$flag=1; #set flag for next loop
				$found++;
				print STDERR "Found ".$rawseqname;
			}
		}
		elsif ($flag==1 and $found==1 and ! ($fasta=~ />/)){
			print OUTFILEDATA $fasta;
			next;
		}
		elsif ($flag==1 and $found==1 and $fasta=~ />/){
			goto OUT;
		}
	}
	OUT:
	close INFILEDATA;
	if ($found==0){
		unless(open(ERRFILEDATA,">>$destfname.notfound"))
			{print "not able to open ".$destfname."notfound\n\n";exit;}
		print ERRFILEDATA $seqname."\n";
		print "Cannot find ".$rawseqname;
		close ERRFILEDATA;
		$haderr=1;
	}
}

if ($haderr==1){
	print "\nSequences not found are in ".$destfname.".notfound file\n";
}


close OUTFILEDATA;
close LISTFILEDATA;
exit;
