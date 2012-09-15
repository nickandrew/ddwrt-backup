#!/usr/bin/perl -w
#  vim:sw=4:ts=4:
#
# Decode a backup file

use Data::Dumper qw(Dumper);

use DDWRTBackup qw();

use strict;
use warnings;

my $f = shift @ARGV || die "Need arg filename";

if (!-f $f) {
	die "No such file: $f";
}

my $backup = DDWRTBackup->new($f);
my $list = $backup->asList();

foreach my $lr (@$list) {
	my ($key, $value) = @$lr;

	printf("%-40s | (%s)\n",
		$key,
		(defined $value) ? $value : 'undef',
	);
}

exit(0);
