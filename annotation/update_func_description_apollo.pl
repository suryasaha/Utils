#!/usr/bin/perl

=head1 NAME

update_func_description.pl

=head1 SYNOPSIS

update_func_description_apollo.pl -c curated descriptions -i index file -a AHRD descriptions -o updated descriptions file

=head1 COMMAND-LINE OPTIONS

 -c curated descriptions from apollo (required)
 -i index file with OGS id and maker or apollo id (required)
 -a AHRD descriptions based on OGS id (required)
 -o updated descriptions file with OGS id (required)
 -d debugging messages (1 or 0)
 -h Help

=cut

use strict;
use warnings;

use Getopt::Std;
use File::Slurp;

our ( $opt_c, $opt_i, $opt_a, $opt_o, $opt_d, $opt_h );
getopts('c:i:a:o:d:h');
if ($opt_h) {
	help();
	exit;
}

if ( !$opt_c || !$opt_i || !$opt_a || !$opt_o ) {
	print "\n file is required. See help below\n\n\n";
	help();
}

#get input files
my $curated_input_file = $opt_c;
my $input_curated      = read_file($curated_input_file)
	or die "Could not open curated input file: $curated_input_file\n";
my $index_input_file = $opt_i;
my $input_index      = read_file($index_input_file)
	or die "Could not open index input file: $index_input_file\n";
my $AHRD_input_file = $opt_a;
my $input_AHRD      = read_file($AHRD_input_file)
	or die "Could not open AHRD input file: $AHRD_input_file\n";
my $output_file = $opt_o;

my %apollo_curated_function;
my @lines          = split( /\n/, $input_curated );
foreach my $line (@lines) {
	chomp($line);
	my @line_arr = split ("\t", $line);
	$apollo_curated_function{$line_arr[0]}=$line_arr[1];            #apollo id = curated function
}

my %OGS_maker_index;
@lines          = split( /\n/, $input_index );
foreach my $line (@lines) {
	chomp($line);
	my @line_arr = split ("\t", $line);
	$OGS_maker_index{$line_arr[1]}=$line_arr[0];                    # OGS id = maker is
}

my %OGS_ahrd_function;
@lines          = split( /\n/, $input_AHRD );
foreach my $line (@lines) {
	chomp($line);
	my @line_arr = split ("\t", $line);
	$OGS_ahrd_function{$line_arr[0]}=$line_arr[1];                  # OGS id = AHRD function string
}

my ($OGS_id, $ahrd_function, $output_data, $curated_count );
$output_data = '';
$curated_count = 0;

while (($OGS_id, $ahrd_function) = each %OGS_ahrd_function){
	if ( ! exists $OGS_maker_index{$OGS_id} ) { die "each OGS id will have a maker id\n"; }
	my $maker_apollo_id = $OGS_maker_index{$OGS_id};
	my $suffix; #-RA,-RB,-RC.... 1-16 in this dataset
	my @OGS_arr = split ('\.', $OGS_id);

	#get isoform number (1 in Dcitr00g00990.1.1, 2 in Dcitr00g01090.1.2)
	if ( $OGS_arr[2] == 1 ){ $suffix = '-RA'; }
	elsif ( $OGS_arr[2] == 2 ){ $suffix = '-RB'; }
	elsif ( $OGS_arr[2] == 3 ){ $suffix = '-RC'; }
	elsif ( $OGS_arr[2] == 4 ){ $suffix = '-RD'; }
	elsif ( $OGS_arr[2] == 5 ){ $suffix = '-RE'; }
	elsif ( $OGS_arr[2] == 6 ){ $suffix = '-RF'; }
	elsif ( $OGS_arr[2] == 7 ){ $suffix = '-RG'; }
	elsif ( $OGS_arr[2] == 8 ){ $suffix = '-RH'; }
	elsif ( $OGS_arr[2] == 9 ){ $suffix = '-RI'; }
	elsif ( $OGS_arr[2] == 10 ){ $suffix = '-RJ'; }
	elsif ( $OGS_arr[2] == 11 ){ $suffix = '-RK'; }
	elsif ( $OGS_arr[2] == 12 ){ $suffix = '-RL'; }
	elsif ( $OGS_arr[2] == 13 ){ $suffix = '-RM'; }
	elsif ( $OGS_arr[2] == 14 ){ $suffix = '-RN'; }
	elsif ( $OGS_arr[2] == 15 ){ $suffix = '-RO'; }
	elsif ( $OGS_arr[2] == 16 ){ $suffix = '-RP'; }

	#add in curated function if present
	if ( exists $apollo_curated_function{$maker_apollo_id} ){

		if ($opt_d){
			print STDERR "$maker_apollo_id\n";
		}

		$curated_count++;
		my $curated_function = $apollo_curated_function{$maker_apollo_id};

		if ($opt_d){
			print STDERR "Found curated function $curated_function for $OGS_id with maker id $maker_apollo_id\n";
		}

		my $updated_function = $curated_function.$suffix.'. ';
		my $new_ahrd_function;

		#AHRD
		#Polyprotein (AHRD V3.11 *-* tr|A0A0L7L4A5|A0A0L7L4A5_9NEOP). Similar to MCOT21850.0.CC. AED 0.01 => Manual desc (AHRD V3.11 *-* Polyprotein tr|A0A0L7L4A5|A0A0L7L4A5_9NEOP). Similar to MCOT21850.0.CC. AED 0.01
		#if ( $ahrd_function =~ /AHRD/ ){

		if ($opt_d){
			print STDERR "Auto: $ahrd_function\n";
		}

		#Assuming all proteins have AHRD string
		my @temp_arr = split (' \(', $ahrd_function);
		my $AHRD_function = $temp_arr[0]; #ugly!!
		#$AHRD_function =~ s/^[\S\s]+ \(/\(/;
		#$AHRD_function =~ s/ \($//;

		if ($opt_d){
			print STDERR "AHRD: $AHRD_function\n";
		}

		$ahrd_function =~ s/^[\S\s]+ \(/\(/;
		my @ahrd_function_arr = split (' ', $ahrd_function);
		#adding 1st 3 values (AHRD V3.11 *-*
		$new_ahrd_function = shift @ahrd_function_arr;
		$new_ahrd_function = $new_ahrd_function.' '.shift @ahrd_function_arr;
		$new_ahrd_function = $new_ahrd_function.' '.shift @ahrd_function_arr;
		#then the AHRD function
		$new_ahrd_function = $new_ahrd_function.' '.$AHRD_function;
		#and the rest
		foreach my $val ( @ahrd_function_arr ){
			$new_ahrd_function = $new_ahrd_function.' '.$val;
		}
		#}

		#no AHRD
		#Unknown protein

		#elsif ( $ahrd_function =~ /^Unknown protein/ ){

		if ( $ahrd_function =~ /^Unknown protein/ ){
			$ahrd_function =~ s/^Unknown protein. //;
			$new_ahrd_function = $ahrd_function;
			print STDERR "Cool! Assigned $curated_function to unknown protein $OGS_id\n";
		}
		else{
			die "this should not have happened!!\n";
		}
		$updated_function = $updated_function. $new_ahrd_function;

		#print to out
		$output_data = $output_data.$OGS_id."\t".$updated_function."\n";

		if ($opt_d){
			print STDERR "Updated: $updated_function\n";
		}
	}
	else{#no curated funciton
	#print to out
	$output_data = $output_data.$OGS_id."\t".$ahrd_function."\n";
	}
}

print STDERR "updated descriptions for $curated_count proteins\n";

unless ( open( OFUNC, ">$output_file" ) ) {
	print STDERR "Cannot open $output_file\n";
	exit 1;
}
print OFUNC $output_data;
close(OFUNC);

#----------------------------------------------------------------------------

sub help {
	print STDERR <<EOF;
  $0:

    Description:

     Update functional description generated by AHRD, interproscan etc. with curated functions from Apollo. AHRD description is moved inside (). -RA, -RB... suffixes are added to curated descriptions.

    Usage:
      update_func_description_apollo.pl -c curated descriptions -i index file -a AHRD descriptions -o updated descriptions file

    Flags:

	 -c curated descriptions from apollo (required)
	 -i index file with OGS id and maker id (required)
	 -a AHRD descriptions based on OGS id (required)
	 -o updated descriptions file with OGS id (required)
	 -d debugging messages (1 or 0)
	 -h Help

EOF
	exit(1);
}

=head1 LICENSE

  Same as Perl.

=head1 AUTHORS

  Surya Saha <suryasaha@cornell.edu , @SahaSurya>

=cut
