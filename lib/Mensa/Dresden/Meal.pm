package Mensa::Dresden::Meal;

use 5.014002;
use strict;
use warnings;

=head1 NAME

Mensa::Dresden::Meal - The datastructure which contains all meal-related
information

=head1 SYNOPSIS

  use Mensa::Dresden::Meal;

  $meal = Mensa::Dresden::Meal->new($xml_meal);

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=cut

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mensa::Dresden::Meal ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


use Carp;
use XML::LibXML;
use XML::LibXSLT;

my %INGREDIENTS = (
	"Menü enthält Schweinefleisch" => 'PORK',
	"Menü enthält Rindfleisch" => 'BEEF',
	"Menü enthält kein Fleisch" => 'VEGETARIAN',
	"Menü enthält Alkohol" => 'ALCOHOL',
	"Menü enthält Knoblauch" => 'GARLIC',
	"Menü ist vegan" => 'VEGAN'
);

use subs qw(_validate _get_text_content _get_ingredients);

=head2 METHODS

=over 4

=item B<new>

=cut

sub new {
	my $class = shift;
	my $xml = shift;
#	_validate($xml);
	my @ingredients = _get_ingredients($xml);
	my $self = {
		url => $xml->getAttribute('url'),
		name => _get_text_content($xml, 'name'),
		ingredients => \@ingredients
	};
	return bless $self, $class;
}

sub _validate($) {
	my $xml = shift;
	my $schema = XML::LibXML::Schema->new(IO => *DATA);
	$schema->validate($xml);
}

sub _get_text_content($$) {
	my $xml = shift;
	my $name = shift;
	my ($element) = $xml->getChildrenByTagName($name);
	return $element->textContent();
}

sub _get_ingredients($) {
	my $xml = shift;
	my @ingredients;
	for ($xml->getElementsByTagName('ingredient')) {
		push @ingredients, $_->textContent();
	}
	return @ingredients;
}

=item B<name>

=cut

sub name {
	my $self = shift;
	return $self->{name};
}

=item B<url>

=cut

sub url {
	my $self = shift;
	return $self->{url};
}

=item B<ingredients>

=cut

sub ingredients() {
	my $self = shift;
	return @{ $self->{ingredients} };
}

=back

=cut

sub to_string() {
	my $self = shift;
	my $string = '';
	$string .= $self->name . "\n";
	my @ingredients = $self->ingredients();
	@ingredients = '-' unless @ingredients;
	local $" = ', ';
	$string .= "> @ingredients\n";
	$string .= $self->url;
	return $string;
}


1;

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by 8ware

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

__DATA__
<?xml version="1.0" encoding="UTF-8" ?>

<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
		elementFormDefault="qualified"
		version="0.1">

		<xs:complexType name="Offering">
			<xs:sequence>
				<xs:element ref="mensa" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>

		<xs:complexType name="Mensa">
			<xs:sequence>
				<xs:element name="meal" type="Meal" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
			<xs:attribute name="name" type="xs:string" use="required"/>
		</xs:complexType>

		<xs:complexType name="Meal">
			<xs:sequence>
				<xs:element name="name" type="xs:string"/>
			</xs:sequence>
			<xs:attribute name="url" type="xs:anyURL"/>
		</xs:complexType>

		<xs:element name="offering" type="Offering"/>
		<xs:element name="mensa" type="Mensa"/>
		<xs:element name="meal" type="Meal"/>

</xs:schema>

