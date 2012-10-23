#!/usr/bin/perl -w
#  vim:sw=4:ts=4:
#
#  Download the current NVRAM contents
#
#  Options:
#    -c config_file.yaml          - Config filename (YAML)

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Getopt::Std qw(getopts);
use LWP::UserAgent qw();
use YAML qw();

use DDWRTBackup qw();

use vars qw($opt_c);

$| = 1;
getopts('c:');

my $config_file = $opt_c || die "Need option -c config_file";

if (!-f $config_file) {
	die "No file $config_file";
}

my $config = YAML::LoadFile($config_file);

$config->{hostname} || die "Need config hostname";
$config->{port} || die "Need config port";
$config->{realm} || die "Need config realm";
$config->{username} || die "Need config username";
$config->{password} || die "Need config password";

my $router_url = sprintf("http://%s:%s", $config->{hostname}, $config->{port});
my $host_port = sprintf("%s:%s", $config->{hostname}, $config->{port});

my $ua = LWP::UserAgent->new();
$ua->credentials($host_port, $config->{realm}, $config->{username}, $config->{password});

my $response = $ua->get("$router_url/nvrambak.bin");

if (!$response->is_success()) {
	printf STDERR ("Failure: %s\n", $response->status_line());
	exit(8);
}

my $content = $response->content();

if (open(OF, '>', 'config.response')) {
	print OF $content;
	close(OF);
}

my $backup = DDWRTBackup->new();
$backup->data($content);

my $hr = $backup->asHash();

foreach my $key (sort (keys %$hr)) {
	my $value = $hr->{$key};

	printf("%-40s | (%s)\n",
		$key,
		(defined $value) ? $value : 'undef',
	);
}

print STDERR "Success!\n";

exit(0);
