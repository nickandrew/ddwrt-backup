#!/usr/bin/perl -w
#  vim:sw=4:ts=4:

=head1 NAME

DDWRTBackup - A binary DD-WRT backup file

=head1 SYNOPSIS

  my $backup = DDWRTBackup->new($filename);
  my $listref = $backup->asList();

=cut

package DDWRTBackup;

use strict;
use warnings;

use IO::File qw(O_RDONLY);

sub new {
	my ($class, $arg) = @_;

	my $self = {
		list => [],
		prop => {},
	};
	bless $self, $class;

	if ($arg && !ref($arg) && -e $arg) {
		my $if = IO::File->new($arg, O_RDONLY());
		if (!$if) {
			die "Unable to open $arg for read - $!";
		}

		$self->parseFile($if);
		$if->close();
	}

	return $self;
}

sub asList {
	my ($self) = @_;

	return $self->{list};
}

sub Property {
	my ($self, $key) = @_;

	return $self->{prop}->{$key};
}

sub parseFile {
	my ($self, $fh) = @_;

	my $header;
	read($fh, $header, 6) or die;
	$self->{header} = unpack('A*', $header);

	if ($self->{header} ne 'DD-WRT') {
		die "Unknown file header: $self->{header}";
	}

	my $bytes;
	read($fh, $bytes, 2) or die;
	my ($byte1, $byte2) = unpack('c*', $bytes);
	$self->{byte1} = $byte1;
	$self->{byte2} = $byte2;

	if ($byte2 != 0x04) {
		die "Expected 0x04 for byte2 not <$byte2>";
	}

	my $buf;

	while (read($fh, $buf, 1) == 1) {
		my $namelen = unpack('c', $buf);
		my $key;
		read($fh, $key, $namelen) or die;
		read($fh, $buf, 2) or die;
		my $valuelen = unpack('s', $buf);
		my $value;
		if ($valuelen > 0) {
			read($fh, $buf, $valuelen) or die;
			$value = unpack('A*', $buf);
		}

		my $lr = [$key, $value];
		push(@{$self->{list}}, $lr);
		$self->{prop}->{$key} = $value;
	}

	return $self;
}

1;
