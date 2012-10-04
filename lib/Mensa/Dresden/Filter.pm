package Mensa::Dresden::Filter;

use 5.014002;
use strict;
use warnings;

=head1 NAME

Mensa::Dresden::Filter - Utility-class to filter out meals

=head1 SYNOPSIS

  use Mensa::Dresden::Filter ':all';

  $steak_filter = Mensa::Dresden::Filter->new(
      NAME, qr/steak/i
  );
  
  $anti_vegan_filter = Mensa::Dresden::Filter->new(
      INGREDIENTS, qr/vegan/, NEGATIVE
  );

=head1 DESCRIPTION

This utility-class serves as filter for meals. A filter consists
of a criterion, a regular expression and a flag which impacts the
filter's behavior. As the filter is applied via the C<pass>-method
the criterion is evaluated against the expression, while the flag
effects the boolean result.

=head2 EXPORT

None by default. The C<all>-tag exports the constants which are
listed in the CONSTANTS section. 

=cut

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( all => [ qw(
	NAME INGREDIENTS
	POSITIVE NEGATIVE
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.01';


=head2 CONSTANTS

=over 4

=item B<NAME>

Represents the C<name>-criterion which applies the filter to the
name of the meal.

=item B<INGREDIENTS>

Represents the C<ingredients>-criterion which applies the filter
to each ingredient of the meal.

=item B<POSITIVE>

Indicates that the filter let only meals pass if the criterion
matches the expression. Because this behavior is the default one
this flag does not impact the filter's functionality.

=item B<NEGATIVE>

Indicates that the filter is inverted and only meals can pass
which criterion does not match the expression.

=back

=cut

use constant {
	NAME => 'name',
	INGREDIENTS => 'ingredients',

	POSITIVE => 0,
	NEGATIVE => 1
};

=head2 METHODS

=over 4

=item B<new>

Accepts the filter-criterion (e.g. C<name> or C<ingredients>), a regular
expression and optionally the inversion-flag (see constants) in this order.
The regular expression is wrapped with the regex-quote and the ignore-case
flag if not happened. An already interpolated expression (using the
C<qr>-operator) will exactly behave as passed to this method, due the regex
is not interpolated twice.

=cut

sub new {
	my $class = shift;
	my $criterion = shift;
	my $regex = shift;
	my $negative = shift || 0;
	my $self = {
		criterion => $criterion,
		regex => qr/$regex/i,
		negative => $negative ? 1 : 0 # enforce 1 or 0
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
	my $negative = $self->{negative};
	my $result = 0;
	for ($meal->$criterion) {
		$result |= /$regex/;
	}
	return $negative ^ $result;
}

=item B<is_negative>

Returns C<true> if the negative-/inversion-flag was set;
C<false> otherwise.

=cut

sub is_negative() {
	my $self = shift;
	return $self->{negative};
}

=back

=cut


1;
__END__
=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by 8ware

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

