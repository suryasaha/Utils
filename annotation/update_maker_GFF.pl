#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use File::Slurp;

=head1 NAME

 update_maker_GFF.pl - Add OGS ids and functional descriptions, Remove maker crud from mRNA records

=head1 SYNOPSIS

  % update_maker_GFF.pl -g maker gff -i index file -o descriptions file --out updated.gff

=head1 DESCRIPTION

 Add OGS ids and functional descriptions (ID,description), Remove maker crud from mRNA records. Presuming that all protein IDs (DcitrP) in the index file have corresponding maker GFF records. Writing the following fields for mRNA (DcitrM) records ID Parent Name _AED _eAED _QI Note

=head1 COMMAND-LINE OPTIONS

 Command-line options can be abbreviated to single-letter options, e.g. -f instead of --file. Some options
are mandatory (see below).

   --gff    <.gff>  GFF file (required)
   --index    index file (required)
   --desc    description file (required)
   --out    <.gff>  GFF file (required)

=head1 AUTHOR

 Surya Saha, ss2489@cornell.edu

=cut

my ( $maker_gff, $maker_OGS_index, $OGS_desc, $out_gff );
GetOptions (
	'gff=s' => \$maker_gff,
  'index=s' => \$maker_OGS_index,
  'desc=s' => \$OGS_desc,
	'out:s' => \$out_gff) or (system('pod2text',$0), exit 1);

defined($maker_gff) or (system('pod2text',$0), exit 1);
if (!(-e $maker_gff)){print STDERR "$maker_gff not found: $!\n"; exit 1;}
defined($maker_OGS_index) or (system('pod2text',$0), exit 1);
if (!(-e $maker_OGS_index)){print STDERR "$maker_OGS_index not found: $!\n"; exit 1;}
defined($OGS_desc) or (system('pod2text',$0), exit 1);
if (!(-e $OGS_desc)){print STDERR "$OGS_desc not found: $!\n"; exit 1;}

my $input_maker_gff      = read_file($maker_gff)
	or die "Could not open curated input file: $maker_gff\n";
my $input_index      = read_file($maker_OGS_index)
	or die "Could not open index input file: $maker_OGS_index\n";
my $input_OGS_desc      = read_file($OGS_desc)
	or die "Could not open desc input file: $OGS_desc\n";


my @maker_gff_arr  = split( /\n/, $input_maker_gff );

my %OGS_function;
my @lines = split( /\n/, $input_OGS_desc );
foreach my $line (@lines) {
	chomp($line);
	my @line_arr = split ("\t", $line);
	$OGS_function{$line_arr[0]}=$line_arr[1];
}

# my $out_gff_data = "##gff-version 3\n";
# #sequence-region comment lines
# foreach my $comment ( grep (/^##sequence-region/, @maker_gff_arr) ){
#   $out_gff_data = $out_gff_data.$comment."\n";
# }
#for parallel runs
my $out_gff_data = '';

#order GFF by index as some mRNAs out of order
@lines          = split( /\n/, $input_index );
my %seen;
foreach my $line (@lines) {
  my @line_arr = split ("\t", $line);
  my $maker_mRNA_id = $line_arr[0];
	my $maker_mRNA_id_core = $maker_mRNA_id; #maker-ScVcwli_3595-pred_gff_maker-gene-32.0-mRNA-7
	$maker_mRNA_id_core =~ s/[\d]+$//; #removing trailing number,  maker-ScVcwli_3595-pred_gff_maker-gene-32.0-mRNA-

	#have we seen this before
	if ( exists $seen{$maker_mRNA_id_core} ) { print STDERR "ignoring $maker_mRNA_id\n"; next;}
	else { $seen{$maker_mRNA_id_core} = ''; }

  my $OGS_id = $line_arr[1]; #DcitrP014695.1.1
	print STDERR "Processing $maker_mRNA_id aka $OGS_id ...\n";
  my $OGS_gene_id = $OGS_id;
  $OGS_gene_id =~ s/\.[\d]+$//; #DcitrP014695.1

	my $OGS_mRNA_id = $OGS_id;
	$OGS_mRNA_id =~ s/^DcitrP/DcitrM/; #DcitrM099555.1.1
	my $OGS_mRNA_id_core = $OGS_mRNA_id;
	$OGS_mRNA_id_core =~ s/[\d]+$//; #DcitrM099555.1.

  my $maker_gene = $maker_mRNA_id;
  $maker_gene =~ s/-mRNA-[\d]+$//;

  #gene rec if mRNA-1
  if ( $maker_mRNA_id =~ /-mRNA-1$/ ){
		my @gene_data_arr = grep ( /\tgene\t/, grep ( /$maker_gene;/, @maker_gff_arr ) ); #nested GREP :-)
    if (scalar @gene_data_arr > 1 ) {
			foreach (@gene_data_arr) { print $_."\n"; }
			die "should only find 1 gene record. found ".scalar @gene_data_arr." for $maker_gene\n";
		}
		my @gene_arr = split ("\t", $gene_data_arr[0]);
    $gene_arr[8] =~ s/$maker_gene/$OGS_gene_id/g; #fix name with DcitrP
    my @gene_attr_arr = split (";", $gene_arr[8]);
    #only keeping ID and Name, 1st 2 attributes
		my @new_gene_attr_arr = @gene_attr_arr[0..1];
		my $OGS_gene_id_alias = $OGS_gene_id; $OGS_gene_id_alias =~ s/\.[\d]+$//; #adding alias DcitrP014695
		$new_gene_attr_arr[2] = "Alias=$OGS_gene_id_alias";
		$gene_arr[8] = join( ";", @new_gene_attr_arr);
		$out_gff_data = $out_gff_data. join ("\t", @gene_arr) ."\n";
	}

  #mRNA, mRNA is DcitrM

	#get ALL mRNAs and children exons, CDSs, UTRs for this gene so we get GFF records in order: mRNA-1 mRNA-2 .....
  my @mRNA_children_arr = grep ( /$maker_mRNA_id_core[\d]+[:;]/, @maker_gff_arr );

	# foreach (@mRNA_children_arr) { say STDERR $_;}
	# print STDERR "\n\n";

	#formatted @arr for sorting by mRNA id
	my @formatted_mRNA_children_arr;
	#exon counter for each mRNA
	my %mRNA_exon_counter;

	foreach my $mRNA_child ( @mRNA_children_arr ){
    #mRNA
    if ( $mRNA_child =~ /\tmRNA\t/ ){#add Notes and select attributes
      my @mRNA_arr = split ("\t", $mRNA_child );
      my @mRNA_attr_arr = split ";" , $mRNA_arr[8];
      #ID Parent Name _AED _eAED _QI Note
			my $mRNA_count = $1 if ( $mRNA_attr_arr[0] =~ /ID=$maker_mRNA_id_core([\d]+)/i ); #get mRNA count from maker GFF itself, this is correct!
			if ( !defined $mRNA_count ){ die "no mRNA count found in $mRNA_child\n"; }
      #$mRNA_attr_arr[0] =~ s/$maker_mRNA_id_core/mRNA\:$OGS_mRNA_id/; #ID
			$mRNA_attr_arr[0] = "ID=${OGS_mRNA_id_core}${mRNA_count}";
      $mRNA_attr_arr[1] = "Parent=$OGS_gene_id"; #Parent
      #$mRNA_attr_arr[2] =~ s/\=.*$/\=mRNA\:$OGS_mRNA_id/; #Name
			$mRNA_attr_arr[2] = "Name=${OGS_mRNA_id_core}${mRNA_count}";
			if (!exists $OGS_function{"${OGS_gene_id}.${mRNA_count}"}) { die "${OGS_gene_id}.${mRNA_count} not found in desc hash.\n"; } #get desc for DcitrP014695.1.?
      $mRNA_attr_arr[6] = 'Note='.$OGS_function{"${OGS_gene_id}.${mRNA_count}"}; #Note
      $mRNA_arr[8] = join (";" , @mRNA_attr_arr[0..6]); #splice ID to Notes
			$mRNA_arr[9] = "${OGS_mRNA_id_core}${mRNA_count}"; #adding for sorting
			push @formatted_mRNA_children_arr, \@mRNA_arr; print STDERR "Added "; foreach (@mRNA_arr){ print STDERR $_.' '; } print STDERR "\n";

			# if (!exists $OGS_function{$OGS_id}) { die "$OGS_id not found in desc hash.\n"; }
      # $mRNA_attr_arr[6] = 'Note='.$OGS_function{$OGS_id}; #Note
      # $mRNA_arr[8] = join (";" , @mRNA_attr_arr[0..6]); #splice ID to Notes
			# $mRNA_arr[9] = $OGS_mRNA_id; #adding for sorting
			# push @formatted_mRNA_children_arr, \@mRNA_arr; print STDERR "Added "; foreach (@mRNA_arr){ print STDERR $_.' '; } print STDERR "\n";
    }
		elsif ( $mRNA_child =~ /\texon\t/ ){

			#single but ANY parent
			if ( $mRNA_child !~ /\,/){
				# my $exon_count = $1 if ( $mRNA_child =~ /ID=$maker_mRNA_id_core[\d]+\:([\d]+)/i ); #get exon count from maker GFF itself, this is correct!
				# if ( !defined $exon_count ){ die "no exon count found in $mRNA_child\n"; }
				my $mRNA_count = $1 if ( $mRNA_child =~ /ID=$maker_mRNA_id_core([\d]+)\:/i ); #get mRNA count from maker GFF itself, this is correct!
				if ( !defined $mRNA_count ){ die "no mRNA count found in $mRNA_child\n"; }
				my @formatted_mRNA_child_arr = split ("\t", $mRNA_child );
				#assigning exon counts irrespective of strand
				my $exon_count;
				if ( exists $mRNA_exon_counter{"${OGS_mRNA_id_core}${mRNA_count}"}) { $exon_count = ++$mRNA_exon_counter{"${OGS_mRNA_id_core}${mRNA_count}"} }
				else { $exon_count = 1; $mRNA_exon_counter{"${OGS_mRNA_id_core}${mRNA_count}"} = 1; }
				$formatted_mRNA_child_arr[8] = "ID=exon:${OGS_mRNA_id_core}${mRNA_count}.${exon_count};Parent=${OGS_mRNA_id_core}${mRNA_count}";
				$formatted_mRNA_child_arr[9] = "${OGS_mRNA_id_core}${mRNA_count}"; #adding for sorting

				# $mRNA_child =~ s/$maker_mRNA_id\:[\d]+/exon\:$OGS_mRNA_id\.$exon_count/; #ID
				# $mRNA_child =~ s/$maker_mRNA_id/$OGS_mRNA_id/; #Parent
				# $mRNA_child = $mRNA_child ."\t$OGS_mRNA_id"; #adding for sorting
				# my @formatted_mRNA_child_arr = split ("\t", $mRNA_child );
				push @formatted_mRNA_children_arr, \@formatted_mRNA_child_arr; print STDERR "Added "; foreach (@formatted_mRNA_child_arr){ print STDERR $_.' '; } print STDERR "\n";
			}
			else{
				#multi parent
				#maker mRNA id can be any parent!!
				# my $exon_count = $1 if ( $mRNA_child =~ /ID=$maker_mRNA_id_core[\d]+\:([\d]+)/i ); #get exon count from maker GFF itself, this is correct!
				# if ( !defined $exon_count ){ die "no exon count found in $mRNA_child\n"; }
				# my $mRNA_count = $1 if ( $mRNA_child =~ /ID=$maker_mRNA_id_core([\d]+)\:/i ); #get mRNA count from maker GFF itself, this is correct!
				# if ( !defined $mRNA_count ){ die "no exon count found in $mRNA_child\n"; }

				my @exon_arr = split ("\t", $mRNA_child );
				my @exon_attr_arr = split (";", $exon_arr[8]);
				foreach my $exon_attr ( @exon_attr_arr ){
					if ( $exon_attr =~ /ID=/){ #ignoring
						#$exon_arr[8] = "ID=exon:${OGS_mRNA_id}.${exon_count}";
						#$exon_arr[8] = "ID=exon:${OGS_mRNA_id}.${exon_ctr};Parent=";
					}
					elsif ( $exon_attr =~ /Parent=/ ){
						$exon_attr =~ s/Parent=//;
						my $OGS_mRNA_id_prefix = $OGS_mRNA_id; $OGS_mRNA_id_prefix =~ s/[\d]+$//; #DcitrM014695.
						my @exon_parent_arr = split (",", $exon_attr);
						foreach my $exon_parent ( @exon_parent_arr ){
							my $exon_parent_suffix;
							#print STDERR "exon parent $exon_parent\n";
							$exon_parent_suffix = $1 if ( $exon_parent =~ /([\d]+$)/i ); #getting  maker mRNA parent number
							if ( !defined $exon_parent_suffix ){ die "no suffix found for $exon_parent\n"; }
							my $exon_count;
							if ( exists $mRNA_exon_counter{"${OGS_mRNA_id_core}${exon_parent_suffix}"}) { $exon_count = ++$mRNA_exon_counter{"${OGS_mRNA_id_core}${exon_parent_suffix}"} }
							else { $exon_count = 1; $mRNA_exon_counter{"${OGS_mRNA_id_core}${exon_parent_suffix}"} = 1; }

							#create new exon record
							my @new_exon_arr = @exon_arr[0..7];
							$new_exon_arr[8] = "ID=exon:${OGS_mRNA_id_prefix}${exon_parent_suffix}.${exon_count};Parent=${OGS_mRNA_id_prefix}${exon_parent_suffix}";
							$new_exon_arr[9] = "${OGS_mRNA_id_prefix}${exon_parent_suffix}"; #adding for sorting
							push @formatted_mRNA_children_arr, \@new_exon_arr; print STDERR "Added "; foreach (@new_exon_arr){ print STDERR $_.' '; } print STDERR "\n";
						}
					}
				}
			}
		}
		elsif ( $mRNA_child =~ /\tCDS\t/ ){
			my $CDS_parent_count = $1 if ( $mRNA_child =~ /([\d]+$)/i ); #getting  maker mRNA parent number
			if ( !defined $CDS_parent_count ){ die "no suffix found for $CDS_parent_count\n"; }
			my @formatted_mRNA_child_arr = split ("\t", $mRNA_child );
			$formatted_mRNA_child_arr[8] = "ID=CDS:${OGS_mRNA_id_core}${CDS_parent_count};Parent=${OGS_mRNA_id_core}${CDS_parent_count}";
			$formatted_mRNA_child_arr[9] = "${OGS_mRNA_id_core}${CDS_parent_count}";

			#say STDERR 'CDS '.$mRNA_child;
			push @formatted_mRNA_children_arr, \@formatted_mRNA_child_arr; print STDERR "Added CDS "; foreach (@formatted_mRNA_child_arr){ print STDERR $_.' '; } print STDERR "\n";

			# $mRNA_child =~ s/$maker_mRNA_id_core[\d]+\:cds/CDS\:${OGS_mRNA_id_core}${mRNA_count}/; #ID
			# my $CDS_parent = $1 if ( $mRNA_child =~ /Parent=(.+$)/i ); #getting  maker mRNA parent number
			# if ( !defined $CDS_parent ){ die "no suffix found for $CDS_parent\n"; }
			# $mRNA_child =~ s/$CDS_parent/$OGS_mRNA_id/; #Parent
			# $mRNA_child = $mRNA_child ."\t$OGS_mRNA_id"; #adding for sorting
			# say STDERR 'CDS '.$mRNA_child;
			# my @formatted_mRNA_child_arr = split ("\t", $mRNA_child );
			# push @formatted_mRNA_children_arr, \@formatted_mRNA_child_arr; print STDERR "Added CDS "; foreach (@formatted_mRNA_child_arr){ print STDERR $_.' '; } print STDERR "\n";
		}
		elsif ( $mRNA_child =~ /\tfive_prime_UTR\t/ ){
			my $UTR_parent_count = $1 if ( $mRNA_child =~ /([\d]+$)/i ); #getting  maker mRNA parent number
			if ( !defined $UTR_parent_count ){ die "no suffix found for $UTR_parent_count\n"; }
			my @formatted_mRNA_child_arr = split ("\t", $mRNA_child );
			$formatted_mRNA_child_arr[8] = "ID=five_prime_UTR:${OGS_mRNA_id_core}${UTR_parent_count};Parent=${OGS_mRNA_id_core}${UTR_parent_count}";
			$formatted_mRNA_child_arr[9] = "${OGS_mRNA_id_core}${UTR_parent_count}";

			push @formatted_mRNA_children_arr, \@formatted_mRNA_child_arr; print STDERR "Added 5' UTR "; foreach (@formatted_mRNA_child_arr){ print STDERR $_.' '; } print STDERR "\n";

			# $mRNA_child =~ s/$maker_mRNA_id_core[\d]+\:five_prime_utr/five_prime_utr\:$OGS_mRNA_id/; #ID
			# my $UTR_parent = $1 if ( $mRNA_child =~ /Parent=(.+$)/i ); #getting  maker mRNA parent number
			# if ( !defined $CDS_parent ){ die "no suffix found for $CDS_parent\n"; }
			# $mRNA_child =~ s/$CDS_parent/$OGS_mRNA_id/; #Parent
			# $mRNA_child = $mRNA_child ."\t$OGS_mRNA_id"; #adding for sorting
			# my @formatted_mRNA_child_arr = split ("\t", $mRNA_child );
			# push @formatted_mRNA_children_arr, \@formatted_mRNA_child_arr; print STDERR "Added 5' UTR "; foreach (@formatted_mRNA_child_arr){ print STDERR $_.' '; } print STDERR "\n";
		}
		elsif ( $mRNA_child =~ /\tthree_prime_UTR\t/ ){
			my $UTR_parent_count = $1 if ( $mRNA_child =~ /([\d]+$)/i ); #getting  maker mRNA parent number
			if ( !defined $UTR_parent_count ){ die "no suffix found for $UTR_parent_count\n"; }
			my @formatted_mRNA_child_arr = split ("\t", $mRNA_child );
			$formatted_mRNA_child_arr[8] = "ID=three_prime_UTR:${OGS_mRNA_id_core}${UTR_parent_count};Parent=${OGS_mRNA_id_core}${UTR_parent_count}";
			$formatted_mRNA_child_arr[9] = "${OGS_mRNA_id_core}${UTR_parent_count}";

			push @formatted_mRNA_children_arr, \@formatted_mRNA_child_arr; print STDERR "Added 3' UTR "; foreach (@formatted_mRNA_child_arr){ print STDERR $_.' '; } print STDERR "\n";

			# $mRNA_child =~ s/$maker_mRNA_id\:three_prime_utr/three_prime_utr\:$OGS_mRNA_id/; #ID
			# $mRNA_child =~ s/$maker_mRNA_id/$OGS_mRNA_id/; #Parent
			# $mRNA_child = $mRNA_child ."\t$OGS_mRNA_id"; #adding for sorting
			# my @formatted_mRNA_child_arr = split ("\t", $mRNA_child );
			# push @formatted_mRNA_children_arr, \@formatted_mRNA_child_arr; print STDERR "Added 3' UTR "; foreach (@formatted_mRNA_child_arr){ print STDERR $_.' '; } print STDERR "\n";
		}
    else{
			die "this should not happen!\n";
    }
  }

	#die "Formatted name array length ".scalar @formatted_mRNA_children_arr." not equal to input mRNA children arr length ".scalar @mRNA_children_arr."\n" if ( scalar @mRNA_children_arr != @formatted_mRNA_children_arr );

	#sort formatted_mRNA_children_arr by mRNA id by mRNA id and then start loc
	my @sorted_formatted_mRNA_children_arr = sort { $a->[9] cmp $b->[9] || $a->[3] <=> $b->[3] } @formatted_mRNA_children_arr;

	#write formatted_mRNA_children_arr to out_gff
	foreach my $rec ( @sorted_formatted_mRNA_children_arr ){
		pop @$rec; #removing mRNA id in last col
		$out_gff_data = $out_gff_data. join ("\t", @$rec) ."\n";
	}
}

unless ( open( OFUNC, ">$out_gff" ) ) {
	print STDERR "Cannot open $out_gff\n";
	exit 1;
}
print OFUNC $out_gff_data;
close(OFUNC);


=head1 LICENSE

  Same as Perl

=head1 AUTHORS

  Surya Saha <suryasaha@cornell.edu , @SahaSurya>

=cut
