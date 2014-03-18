package Mensa::Dresden::Utils;

use 5.014002;
use strict;
use warnings;

=head1 NAME

Mensa::Dresden::Utils

=head1 SYNOPSIS

  use Mensa::Dresden::Utils ':all';

=head1 DESCRIPTION

=head2 EXPORT

=cut

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	load_config parse_args
	parse_html
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.01';


use Carp;
use YAML::Tiny 'LoadFile';
require Mensa::Dresden;

use LWP::UserAgent;
use HTTP::Request;


=head2 METHODS

=over 4

=cut

sub load_config($\@\@);
sub parse_args(;@);
sub umlauts2ascii(_);

=item B<>

=cut

sub load_config($\@\@) {
	my $path = shift;
	my $canteens = shift;
	my $filters = shift;
	return unless -f $path;

	my ($cs, $fs) = LoadFile($path);
	push $canteens, @{$cs} if defined $cs;

	return unless defined $fs;
	while (my ($criterion, $regexes) = each $fs) {
		for (@{$regexes}) {
			my $filter = Mensa::Dresden::Filter->new(
					$criterion, qr/$_/i, s/^~\s*//
			);
			push $filters, $filter;
		}
	}
}

sub parse_args(;@) {
	# may move GetOptions here
	my %canteens;
	for (keys %Mensa::Dresden::MENSAS) {
		my $name = $_;
		$_ = umlauts2ascii;
		s/\s+mensa$//;
		s/^mensa\s+//;
		$canteens{$_} = $name;
	}
	# normalize 
	@_ = @ARGV unless @_;
	my @args = grep { not /^\s*mensa\s*$/ } @_;
	my @canteens;
	for my $arg (@args) {
		$arg = umlauts2ascii($arg);
		my ($name) = grep { $arg =~ /$_/ } keys %canteens;
		push @canteens, $canteens{$name} if $name;
	}
	return @canteens;
}

sub umlauts2ascii(_) {
	local $_ = shift;
	tr/A-ZÄÖÜ/a-zäöü/;
	s/ä/ae/g;
	s/ö/oe/g;
	s/ü/ue/g;
	s/ß/ss/g;
	return $_;
}

sub parse_html($) {
	my $url = shift;
	my $agent = LWP::UserAgent->new();
	my $request = HTTP::Request->new(GET => $url);
	my $response = $agent->request($request);
	croak("Received '".$response->status_line()."'")
			unless $response->is_success();
	my $html = XML::LibXML->load_html(
		string => $response->content(),
		load_ext_dtd => 0,
		expand_entities => 1,
		recover => 2,
		suppress_warnings => 1,
		suppress_errors => 1
	);
	return $html;
}

=back

=cut


1;

=head1 TODOs

=over 4

=back

=head1 SEE ALSO

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by 8ware

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

