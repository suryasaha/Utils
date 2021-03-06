#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Feb 25, 2011

use strict;
use warnings;
use Getopt::Long;
eval {
	require Bio::SearchIO;
};
use Bio::SearchIO; 

=head1 NAME

 Blast2HitGFF3.pl - Create GFF file of blast hits from Blast text report  

=head1 SYNOPSIS

  % Blast2HitGFF3.pl --report blast.out --cutoff <1.0>
  
=head1 DESCRIPTION

 Reads in BLAST report file. Should work for any type of Blast. CHECK!! 
  
=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --report  <.out>    Blast report in text format (required)
   --cutoff  <1.0>     A float value for maximum e value <1.0> 
   --source  <>        Source of seqs in hit blast database (RefSeq,Genbank)
   --out     <.gff>    GFF3 output filename
   --connect <0/1>     Connect HSPs if hit is on the same subject sequence and in same orientation

=head1 NOTES
 HSPs are ordered by evalue and NOT by subject in the report by default. So connections may not be made if parser finds the next hit on another subject sequence.


=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut


my ($rep,$cutoff,$src,$out,$connect,$flag,$in,@temp,$result,$hit,$hsp,$i,$j);

GetOptions (
	'report=s' => \$rep,
	'cutoff:f' => \$cutoff,
	'source:s' => \$src,
	'out:s'    => \$out,
	'connect:i' => \$connect ) or (system('pod2text',$0), exit 1);

# defaults and checks
defined($rep) or (system('pod2text',$0), exit 1);
if (!(-e $rep)){print STDERR "$rep not found: $!\n"; exit 1;}
if ( defined($connect) && $connect != 0 && $connect != 1 ) {
	system( 'pod2text', $0 ), exit 1;
}
$connect ||= 0;
$cutoff  ||=1.0;
$src     ||= 'RefSeq';
$out     ||= "$rep\.gff";

print STDERR "Using E value cutoff of $cutoff ...\nSource as $src ...\n";

$in = new Bio::SearchIO(-format => 'blast', -file   => $rep);

$flag=0;
my $counter=1;
my ($name,$desc, $GFF);
while($result = $in->next_result) {
	## $result is a Bio::Search::Result::ResultI compliant object
	if($result->no_hits_found()){next;}
	
	#get hit data
	if($result->num_hits>0){
		if($flag==0){
			unless( open $GFF, '>', "$out" ){print "not able to open $out\n\n";exit 1;}
			print $GFF "\#\#gff-version 3\n\#\#Generated by Blast2HitGFF3.pl\n\#\#Algorithm: ",
				$result->algorithm," Version: ",$result->algorithm_version,"\n";
			print $GFF "\#\#DB name: ",$result->database_name," Sequences: ",$result->database_entries,
				" Size: ",$result->database_letters,"\n";
			$flag=1;
		}
#		@temp=split(/\|/,$result->query_name);
#		print XLS "\nQuery\t",$result->query_name,"\nDesc\t",$result->query_description,"\n";

		$name = $result->query_name ? $result->query_name : 'No name';
		$name =~ s/;/ /g; #to remove GFF3 notes separator if present
		$desc = $result->query_description ? $result->query_description : 'No description';
		$desc =~ s/;/ /g; #to remove GFF3 notes separator if present
		
		while($hit = $result->next_hit ) {
	    	## $hit is a Bio::Search::Hit::HitI compliant object
	    	if ($hit->significance < $cutoff){
			my($is_first_hsp, $hit_strand, $ID);
			$is_first_hsp = 1;
			
			while($hsp = $hit->next_hsp()){
				## $hsp is a Bio::Search::HSP::HSPI object
				
				if ( $connect ){

					
					if ( $is_first_hsp ){
						$ID = $counter;
						
						$hit_strand = $hsp->strand('hit');
						print $GFF $hit->name,"\t$src\tmatch\t",$hsp->start('hit'),"\t",$hsp->end('hit'),"\t",
							$hsp->bits(),"\t";
						if($hsp->strand('hit') == -1){print $GFF '-';}
						elsif($hsp->strand('hit') == 1){print $GFF '+';}
						if ( $name ne 'No name' && $desc ne 'No description' ){
							print $GFF "\t.\tID=",$ID,";Name=",$name,";Note=$desc Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
							$hsp->evalue(),' Length ',$hsp->length(),"\n";
						}
						elsif ( $name eq 'No name' && $desc ne 'No description' ){
							print $GFF "\t.\tID=",$ID,";Name=",$desc,";Note=Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
							$hsp->evalue(),' Length ',$hsp->length(),"\n";
						}
						elsif ( $name eq 'No name' && $desc eq 'No description' ){
							print $GFF "\t.\tID=",$ID,";Name=NA;Note=Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
							$hsp->evalue(),' Length ',$hsp->length(),"\n";
						}
						else{
							print STDERR "This should not happen\n\n"; exit 1;
						}
						$is_first_hsp = 0;
					}
					elsif ( $is_first_hsp != 1 && $hit_strand == $hsp->strand('hit') ){
						print $GFF $hit->name,"\t$src\tmatch\t",$hsp->start('hit'),"\t",$hsp->end('hit'),"\t",
							$hsp->bits(),"\t";
						if($hsp->strand('hit') == -1){print $GFF '-';}
						elsif($hsp->strand('hit') == 1){print $GFF '+';}
						if ( $name ne 'No name' && $desc ne 'No description' ){
							print $GFF "\t.\tID=",$ID,";Name=",$name,";Note=$desc Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
							$hsp->evalue(),' Length ',$hsp->length(),"\n";
						}
						elsif ( $name eq 'No name' && $desc ne 'No description' ){
							print $GFF "\t.\tID=",$ID,";Name=",$desc,";Note=Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
							$hsp->evalue(),' Length ',$hsp->length(),"\n";
						}
						elsif ( $name eq 'No name' && $desc eq 'No description' ){
							print $GFF "\t.\tID=",$ID,";Name=NA;Note=Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
							$hsp->evalue(),' Length ',$hsp->length(),"\n";
						}
						else{
							print STDERR "This should not happen\n\n"; exit 1;
						}					
					}
					else{
						print $GFF $hit->name,"\t$src\tmatch_part\t",$hsp->start('hit'),"\t",$hsp->end('hit'),"\t",
							$hsp->bits(),"\t";
						if($hsp->strand('hit') == -1){print $GFF '-';}
						elsif($hsp->strand('hit') == 1){print $GFF '+';}
						if ( $name ne 'No name' && $desc ne 'No description' ){
							print $GFF "\t.\tID=",$counter,";Name=",$name,";Note=$desc Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
							$hsp->evalue(),' Length ',$hsp->length(),"\n";
						}
						elsif ( $name eq 'No name' && $desc ne 'No description' ){
							print $GFF "\t.\tID=",$counter,";Name=",$desc,";Note=Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
							$hsp->evalue(),' Length ',$hsp->length(),"\n";
						}
						elsif ( $name eq 'No name' && $desc eq 'No description' ){
							print $GFF "\t.\tID=",$counter,";Name=NA;Note=Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
							$hsp->evalue(),' Length ',$hsp->length(),"\n";
						}
						else{
							print STDERR "This should not happen\n\n"; exit 1;
						}
						$counter++;
					}
				}
				else{
					print $GFF $hit->name,"\t$src\tmatch_part\t",$hsp->start('hit'),"\t",$hsp->end('hit'),"\t",
						$hsp->bits(),"\t";
					if($hsp->strand('hit') == -1){print $GFF '-';}
					elsif($hsp->strand('hit') == 1){print $GFF '+';}
					if ( $name ne 'No name' && $desc ne 'No description' ){
						print $GFF "\t.\tID=",$counter,";Name=",$name,";Note=$desc Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
						$hsp->evalue(),' Length ',$hsp->length(),"\n";
					}
					elsif ( $name eq 'No name' && $desc ne 'No description' ){
						print $GFF "\t.\tID=",$counter,";Name=",$desc,";Note=Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
						$hsp->evalue(),' Length ',$hsp->length(),"\n";
					}
					elsif ( $name eq 'No name' && $desc eq 'No description' ){
						print $GFF "\t.\tID=",$counter,";Name=NA;Note=Percent_identity ",sprintf("%.2f",$hsp->percent_identity),' Evalue ',
						$hsp->evalue(),' Length ',$hsp->length(),"\n";
					}
					else{
						print STDERR "This should not happen\n\n"; exit 1;
					}
					$counter++;
				}
			}
	    	}
	    }
	}
	$i=$result;
}

@temp=$i->available_parameters();
print $GFF "\#\#Parameters\n\#\#";
foreach my $j (@temp){print $GFF $j,': ',$i->get_parameter($j),' ';} print $GFF "\n";
@temp=$i->available_statistics();
print $GFF "\#\#Statistics\n\#\#";
foreach my $j (@temp){print $GFF $j,': ',$i->get_statistic($j),' ';} print $GFF "\n";

if($flag==0){print STDERR "\n\nNo hits found!!\n";}
else{close($GFF);}
exit;

