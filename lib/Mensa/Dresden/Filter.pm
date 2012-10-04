package Mensa::Dresden::Filter;

use 5.014002;
use strict;
use warnings;

=head1 NAME

Mensa::Dresden::Filter - Datastructure to filter out meals

=head1 SYNOPSIS

  use Mensa::Dresden::Filter ':all';

  $steak_filter = Mensa::Dresden::Filter->new(
      'name', qr/(?!tofu)steak/i
  );

  $anti_vegan_filter = Mensa::Dresden::Filter->new(
      'ingredients', qr/vegan/, IGNORE
  );

=head1 DESCRIPTION

This datastructure serves as filter for meals.

=head2 EXPORT

None by default.

=head2 OPTIONS

=cut

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( all => [ qw(
	INVERSE NAME INGREDIENTS
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


our $DEBUG = 0;

=head2 CONSTANTS

=over 4

=item B<NAME>

=item B<INGREDIENTS>

=item B<INVERSE>

=back

=cut

use constant {
	NAME => 'name',
	INGREDIENTS => 'ingredients',

	INVERSE => 1
};

=head2 METHODS

=over 4

=item B<new>

Accepts the filter-criterion (e.g. C<name> or C<ingredients>), a regular
expression and optionally the inversion-flag in that order (see constants).

=cut

sub new {
	my $class = shift;
	my $criterion = shift;
	my $regex = shift;
	my $inverse = shift;
	my $self = {
		criterion => $criterion,
		regex => qr/$regex/i,
		inverse => $inverse || 0
	};
	return bless $self, $class;
}

=item B<pass>

Accepts an instance of Mensa::Dresden::Meal and returns C<true> if this
meal has passed the filter.

=cut

sub pass($) {
	my $self = shift;
	my $meal = shift;
	my $criterion = $self->{criterion};
	my $regex = $self->{regex};
	my $inverse = $self->{inverse};
	say uc ($criterion) . "[ " . ($inverse ? '!' : '=') . "~ $regex ]" if $DEBUG;
	my $result = 0;
	for ($meal->$criterion) {
		$result |= /$regex/;
		say "$_ =~ /$regex/i = " . m/$regex/i . " RES[ $result ]" if $DEBUG;
		say "$_ =~ /".qr/rind/i."/i" if $DEBUG;
	}
	say "RETURN[ " . ($inverse ^ $result) . " ]" if $DEBUG;
	return $inverse ^ $result;
}

=item B<is_negative>

=cut

sub is_negative() {
	my $self = shift;
	return $self->{inverse};
}

sub is_positive() {
	my $self = shift;
	return not $self->{inverse};
}

=back

=cut


1;
__END__
