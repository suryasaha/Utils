package SS;

# Includes
use strict;
use warnings;
use Proc::ProcessTable;

# Supporting functions
########################################################################
sub round3{
	my ($num);
	$num=$_[0];
	$num=$num*1000;
	$num=int($num);
	$num=$num/1000;
	return $num;
}
########################################################################
sub round2{
	my ($num);
	$num=$_[0];
	$num=$num*100;
	$num=int($num);
	$num=$num/100;
	return $num;
}
########################################################################
sub round1{
	my ($num);
	$num=$_[0];
	$num=$num*10;
	$num=int($num);
	$num=$num/10;
	return $num;
}
########################################################################
# get the complement
sub comp{
	my $DNA;
	$DNA=$_[0];
	$DNA=~ s/\s*//g;# clean it
	$DNA=~ tr/ACGTacgt/TGCAtgca/;
	return $DNA;
}
########################################################################
# get the reverse complement
sub revcomp{
	my $DNA;
	$DNA=$_[0];
	$DNA=~ s/\s*//g;# clean it
	$DNA=~ tr/ACGTacgt/TGCAtgca/;
	return scalar reverse $DNA;
}
########################################################################
sub mk_dir{
  my ($name,$i);
  $name=$_[0]; $i=localtime();
  if (-e $name){rename $name,"${name}_$i"; unlink glob "${name}_/* $(name}/.*";rmdir ($name);}
  mkdir ($name, 0755) or warn "Cannot make $name directory: $!\n";
}
########################################################################
sub runtime{
	my($user_t,$system_t,$cuser_t,$csystem_t);	($user_t,$system_t,$cuser_t,$csystem_t) = times;
	print STDERR "System time for process: $system_t\n"; print STDERR "User time for process: $user_t\n\n";
}
########################################################################
sub mem_used{
	my ($i,$t); 
	$t = new Proc::ProcessTable;
	foreach my $got ( @{$t->table} ) {
		next if not $got->pid eq $$; $i=$got->size;
	}
	print STDERR "Process id=",$$,"\n"; print "Memory used(MB)=", $i/1024/1024, "\n";
}
########################################################################
# return first/all index positions where a regex matched in a string
# http://stackoverflow.com/questions/87380/how-can-i-find-the-location-of-a-regex-match-in-perl
sub match_position {
    my ($regex, $string) = @_;
    return if not $string =~ /$regex/;
    return ($-[0], $+[0]);
}
sub match_all_positions {
    my ($regex, $string) = @_;
    my @ret;
    while ($string =~ /$regex/g) {
        push @ret, [ $-[0], $+[0] ];
    }
    return @ret
}

1;
