package Mensa::Dresden::Meal;

use 5.014002;
use strict;
use warnings;

=head1 NAME

Mensa::Dresden::Meal - The datastructure which contains all
meal-related information

=head1 SYNOPSIS

  use Mensa::Dresden::Meal;

  $meal_xml = XML::LibXML->load_xml(string => <<XML);
  <?xml version="1.0" encoding="UTF-8" ?>
  <offering>
   	  <mensa name="$mensa_name">
          <meal url="$url">
              <name>$name</name>
              <ingredient>$ingredient_1</ingredient>
              <ingredient>$ingredient_2</ingredient>
          </meal>
      </mensa>
  </offering>
  XML

  $meal = Mensa::Dresden::Meal->new($meal_xml);

=head1 DESCRIPTION

This datastructure contains all meal relevant information. It is
used to deliver the offering in a well defined structure which
is applicable to be filtered.

=head2 EXPORT

None by default. The C<all>-tag imports the ingredient-constants
(see section CONSTANTS).

=cut

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	PORK BEEF VEGETARIAN ALCOHOL GARLIC VEGAN
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.01';


use Carp;
use Fcntl 'SEEK_SET';
use XML::LibXML;
use XML::LibXSLT;

=head2 CONSTANTS

Following constants can be used to filter the meals.

=over 4

=item B<PORK>

Constant indicating the meal contains pork.

=item B<BEEF>

Constant indicating the meal contains beef.

=item B<VEGETARIAN>

Constant indicating the meal is vegetarian.

=item B<ALCOHOL>

Constant indicating the meal contains alcohol.

=item B<GARLIC>

Constant indicating the meal contains garlic.

=item B<VEGAN>

Constant indicating the meal is vegan.

=back

=cut

use constant {
	PORK => 'Schweinefleisch',
	BEEF => 'Rindfleisch',
	VEGETARIAN => 'kein Fleisch',
	ALCOHOL => 'Alkohol',
	GARLIC => 'Knoblauch',
	VEGAN => 'vegan'
};


my $schema = XML::LibXML::Schema->new(string => join ('', <DATA>));

use subs qw(validate get_name get_ingredients);

=head2 METHODS

=over 4

=item B<new>

Instantiates a new meal by extracting all required information
from the given XML node.

=cut

sub new {
	my $class = shift;
	my $xml = shift;
#	validate($xml);
	my $self = {
		url => $xml->getAttribute('url'),
		name => get_name($xml),
		ingredients => [ get_ingredients($xml) ]
	};
	return bless $self, $class;
}

#
# Validates the given XML against the schema.
#
sub validate($) {
	my $xml = shift;
	eval { $schema->validate($xml) };
	croak("No valid meal XML: $@") if $@;
}

#
# Extracts the text content from the given XML node.
#
sub get_name($) {
	my $xml = shift;
	my ($element) = $xml->getChildrenByTagName('name');
	return $element->textContent();
}

#
# Extracts all ingredients from the given XML node.
#
sub get_ingredients($) {
	my $xml = shift;
	return map {
		$_->textContent()
	} $xml->getElementsByTagName('ingredient');
}

=item B<name>

Returns the name of the meal.

=cut

sub name {
	my $self = shift;
	return $self->{name};
}

=item B<url>

Returns the URL to the meal's detail-site.

=cut

sub url {
	my $self = shift;
	return $self->{url};
}

=item B<ingredients>

Returns the ingredients of the meal as list.

=cut

sub ingredients() {
	my $self = shift;
	return @{ $self->{ingredients} };
}

=item B<to_string>

Returns a printable string which contains the information of the meal
as follows:

  name of the meal
  > ingredients
  http://example.org/meal's-detail-site

=cut

sub to_string() {
	my $self = shift;
	my $string = '';
	$string .= $self->name . "\n";
	my @ingredients = $self->ingredients;
	@ingredients = '-' unless @ingredients;
	local $" = ', ';
	$string .= "> @ingredients\n";
	$string .= $self->url;
	return $string;
}

=back

=cut


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
<xs:schema
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
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
		<xs:attribute name="url" type="xs:anyURI"/>
	</xs:complexType>

	<xs:element name="offering" type="Offering"/>
	<xs:element name="mensa" type="Mensa"/>
	<xs:element name="meal" type="Meal"/>

</xs:schema>

