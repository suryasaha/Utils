#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Dec 3, 2010

# To delete 101 bad genes in LAS found by ML

unless(open(BG,"<badgenes.txt")){print "not able to open ....\n\n";exit 1;}
unless(open(GFF,"<NC_012985.gff")){print "not able to open ....\n\n";exit 1;}
unless(open(OUT,">trimmed.NC_012985.gff")){print "not able to open ....\n\n";exit 1;}

my(@bgenes);
while($rec=<BG>){ chomp $rec; push @bgenes,$rec;}
close(BG);

while($rec=<GFF>){
	my ($flag); $flag=0;
	foreach $i (@bgenes){# if this locus tag is present, skip it
		if($rec=~ /$i/){$flag=1; last;}
	}
	if($flag==0){ print OUT $rec;}
}
close(GFF); close (OUT);
exit;