package Mensa::Dresden;

use 5.014002;
use strict;
use warnings;

=head1 NAME

Mensa::Dresden - Perl interface to receive offerings of Dresden's canteens

=head1 SYNOPSIS

  use Mensa::Dresden ':all';

  $steak_filter = create_filter(name => qr/steak/i);
  $anti_tofu_filter = create_filter(name => qr/tofu/i, NEGATIVE);

  $mensa = Mensa::Dresden->new('Alte Mensa', $steak_filter);

  $antivegan = $mensa->create_filter(ingredients => qr/vegan/, NEGATIVE);
  $mensa->add_filter($anti_tofu_filter);

  @meals = $mensa->get_offering();
  @meals = $mensa->get_offering(TOMORROW);
  @meals = $mensa->get_offering(MONDAY, NEXT_WEEK);

=head1 DESCRIPTION

This module provides a simple interface to receive the offerings of
Dresden's canteens. Because tastes differ some filters can be specified
to eliminate loathsome meals. The mensa-script which comes along with
this distribution implements a simple command line interface to check
the canteens offering.

If the scalar C<$Mensa::Dresden::caching> is true, which is the
default value, the fetched HTML resource is cached in the /tmp
directory. This enhances the speed of the module which otherwise
is dependent the network-speed. The benefit will appear as the
offering is requested a second time. You may put a call of the
mensa-script in your auto-start, to cache it immediately on start.

=head2 EXPORT

None by default, but there are several constants and some methods which can
be imported by the C<all>-tag. Additionally all date-related constants are
exported if the C<date>-tag is specified. Similar, all filter-related stuff
is provided if the C<filter>-tag is given. The next section (CONSTANTS) shows
which constants are available.

=cut

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	all => [ qw(
		TODAY TOMORROW
		MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY SUNDAY
		THIS_WEEK NEXT_WEEK AFTERNEXT_WEEK
		create_filter NAME INGREDIENTS POSITIVE NEGATIVE
		PORK BEEF VEGETARIAN ALCOHOL GARLIC VEGAN
	) ],
	date => [ qw(
		TODAY TOMORROW
		MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY SUNDAY
		THIS_WEEK NEXT_WEEK AFTERNEXT_WEEK
	) ],
	filter => [ qw(
		create_filter NAME INGREDIENTS POSITIVE NEGATIVE
		PORK BEEF VEGETARIAN ALCOHOL GARLIC VEGAN
	) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.02';


use Carp;
use Fcntl 'SEEK_SET';
use HTTP::Request;
use LWP::UserAgent;
use XML::LibXML;
use XML::LibXSLT;

use Mensa::Dresden::Filter ':all';
use Mensa::Dresden::Meal ':all';

=head2 CONSTANTS

=head3 FILTER-RELATED

These constants are useful to create filters. See the description
of the C<create_filter>-method and the C<Dresden::Mensa::Filter>
module for further information.

=over 4

=item B<NAME>

The identifier for name-specific filters.

=item B<INGREDIENTS>

The identifier for ingredient-specific filters. Following constants
can be used to specify an ingredient-filter:

=over 8

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

=item B<POSITIVE>

This flag has no effect on the filter but is given for completeness.

=item B<NEGATIVE>

This flag indicates that the filter will be inverted.

=back

=head3 DATE-RELATED

The date related constants serve as a more readable form to specify
what meals are requested of which date, relative to the today's date.
See the desciption of the C<get_offering>-method for more information.

=over 4

=item B<TODAY>

Represents the today's day-number. As the C<get_offering>-method
supposes the current day if the arguments are omitted, this constant
is listed only for completeness.

=item B<TOMORROW>

Represents the tomorrow's day-number.

=item B<MONDAY> B<TUESDAY> B<WEDNESDAY> B<THURSDAY> B<FRIDAY>
      B<SATURDAY> B<SUNDAY>

Represents the numbers of the denoted days.

=item B<THIS_WEEK> B<NEXT_WEEK> B<AFTERNEXT_WEEK>

Represents the numbers for the current, next and after next week.

=back

=cut

use constant {
	TODAY => (localtime time)[6],
	TOMORROW => ((localtime time)[6] +1) % 7,

	MONDAY => 1,
	TUESDAY => 2,
	WEDNESDAY => 3,
	THURSDAY => 4,
	FRIDAY => 5,
	SATURDAY => 6,
	SUNDAY => 0,

	THIS_WEEK => 0,
	NEXT_WEEK => 1,
	AFTERNEXT_WEEK => 2
};


#
# The base URL of the canteen offerings.
#
our $URL = 'http://www.studentenwerk-dresden.de/mensen/speiseplan/';

#
# The canteen-names with their appropriate mensa-IDs.
#
our %MENSAS = (
	'Neue Mensa' => 8,
	'Alte Mensa' => 18,
	'Mensa Reichenbachstraße' => 9,
	'Mensologie' => 5,
	'Mensa Siedepunkt' => 6,
	'Mensa Johannstadt' => 32,
	'Mensa Blau' => 12,
	'BioMensa U-Boot' => undef, # no ID given, yet
	'Mensa TellerRandt' => 7,
	'Mensa Zittau' => 1,
	'Mensa Stimm-Gabel' => 13,
	'Mensa Palucca Schule' => 14,
	'Mensa Görlitz' => 15,
	'Mensa Haus VII' => 16,
	'Mensa Sport' => 19,
	'Mensa Kreuzgymnasium' => 20
);

our $CACHE_PATH = '/tmp/mensa';
our $CACHE_EXT  = '.cache';
sub CACHE($$) {
	my ($week, $day) = @_;
	return "$CACHE_PATH-$week$day$CACHE_EXT";
}

use subs qw(load_stylesheet get_url fetch_html filter filter_with);

our $caching = 1;

my $stylesheet = load_stylesheet();

=head2 METHODS

=over 4

=item B<new>

Creates a new instance of a Dresden's canteen. The first argument is the
canteen's name while all succeeding arguments must be filters. See the
C<create_filter>- and C<add_filter>-method for more information.

=cut

sub new {
	my $class = shift;
	my $mensa = shift;
	my @filters = @_;
	my @mensas = keys %MENSAS;
	return bless {
		name => $mensa,
		p_filters => [ grep { not $_->is_negative } @filters ],
		n_filters => [ grep { $_->is_negative } @filters ]
	}, $class if $mensa ~~ @mensas;
	croak("Unknown mensa: $mensa");
}

=item B<get_name>

Returns the name of the canteen.

=cut

sub get_name() {
	my $self = shift;
	return $self->{name};
}

#
# The constants which indicate the usage of positive and negative filters.
# Intended for a more readable usage of the 'filter'-method.
#
use constant {
	positive => 0,
	negative => 1
};

=item B<get_offering>

Accepts two arguments. The first one is the day, where 0 indicates sunday and
3 indicates wednesday. The second argument is the week, where 0 represents the
current, 1 the next and 2 the after next week. If both is omitted the current
day and week is supposed while the current week is assumed if only the week
parameter is omitted. After the offering was scrapped, the meals are filtered
as follows:

=cut

sub get_offering(;$$) {
	my $self = shift;
	my $day = defined $_[0] ? shift : (localtime time)[6];
	my $week = defined $_[0] ? shift : 0;

	my $url = get_url($week, $day);
	my $html = fetch_html($url);
	$html->toFile(CACHE($week, $day), 1)
			if $caching and not -f CACHE($week, $day);
	my $offering = $stylesheet->transform($html,
		XML::LibXSLT::xpath_to_string(name => $self->{name}),
	);

	my @meals;
	for ($offering->getElementsByTagName('meal')) {
		my $meal = Mensa::Dresden::Meal->new($_);
		push @meals, $meal;
	}
	return $self->filter(@meals);
}

#
# Delivers the URL which is dependent on the given day and week.
#
sub get_url($$) {
	my ($week, $day) = @_;
	croak("Not a valid value: week=$week") if $week < 0 or $week > 2;
	croak("Not a valid value: day=$day") if $day < 0 or $day > 6;
	return $caching && -f CACHE($week, $day)
			? 'file://' . CACHE($week, $day) : $URL . "w$week-d$day.html";
}

#
# Fetches the HTML resource from the given URL and returns it as
# XML document.
#
sub fetch_html($) {
	my $url = shift;
	my $agent = LWP::UserAgent->new();
	my $request = HTTP::Request->new(GET => $url);
	my $response = $agent->request($request);
	croak("Received ".$response->status_line()) unless $response->is_success();
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

#
# Loads the stylesheet which is used to transform the HTML resource
# into a more appropriate XML representation.
#
sub load_stylesheet() {
	my $xslt = XML::LibXSLT->new();
	my $position = tell DATA;
	my $xsl = XML::LibXML->load_xml(IO => *DATA);
	seek DATA, $position, SEEK_SET;
	my $stylesheet = $xslt->parse_stylesheet($xsl);
	return $stylesheet;
}

#
# Filters the given meals. The filter mechanism works as follows:
# 1. Apply all positive filters to all meals, if at least one matches
#    add the meal to the list of filtered ones.
# 2. Apply all negative filters to the already filtered meals, if at
#    least one does not match, remove the meal, i.e. don't add it.
# 3. If no meals were left after step 1 and 2 apply all negative
#    filters to all meals and add the meal only of if all filtern match
# 4. If still no meals are left, return all meals.
#
sub filter(@) {
	my $self = shift;
	my @meals = @_;
	my @filtered_meals;
	@filtered_meals = $self->filter_with(positive, @meals);
	@filtered_meals = $self->filter_with(negative, @filtered_meals);
	return @filtered_meals if @filtered_meals;
	@filtered_meals = $self->filter_with(negative, @meals);
	return @filtered_meals if @filtered_meals;
	return @meals;
}

#
# Applies the filter of the mensa to the given meals. The first argument
# indicates whether to use the positive or negative filters. If true the
# negative filters are used. The behavior of positive and negative filters
# differ. If at least one positive filter matches, the meal passes and
# will be added to the filtered-array. Otherwise all negative filters must
# match to retain the meal.
#
sub filter_with($@) {
	my $self = shift;
	my $negative = shift;
	my @meals = @_;
	my @filters = @{ $self->{($negative ? 'n' : 'p').'_filters'} };
	return @meals unless @filters;
	my @filtered;
	for my $meal (@meals) {
		my $matches = grep { $_->pass($meal) } @filters;
		push @filtered, $meal
				if not $negative and $matches or $matches == @filters;
	}
	return @filtered;
}

=item B<create_filter>

Creates a new filter. The first argument is the criterion which should be
filtered, i.e. one of C<name> or C<ingredients>. To avoid typos the
C<NAME>- and C<INGREDIENTS>-constant should be used for identification.
The second argument is the regular expression which the criterion must match
to get not rejected. The third parameter is optional and indicates whether
the filter is positive or negative, i.e. a negative filter let the meal pass
only if the criterion does not match the expression. To keep it more readable
one can use the C<NEGATIVE>-constant to get this done (the C<POSITIVE>-constant
can also be used, but is implicitly supposed if omitted). Besides, if this
routine is used as object-method the filter is added immediately, so the
C<add_filter>-method must not be invoked separately.

=cut

sub create_filter {
	my $self = shift;
	my $filter;
	if ($self =~ /^Mensa::Dresden=HASH\(0x[\da-f]{7}\)/) {
		$filter = create_filter(@_);
		$self->add_filter($filter);
	} else {
		unshift @_, $self unless $self eq 'Mensa::Dresden';
		my ($criterion, $regex, $negative) = @_;
		$filter = Mensa::Dresden::Filter->new(
				$criterion, qr/$regex/i, $negative
		);
	}
	return $filter;
}

=item B<add_filter>

Adds the given filters to the canteen.

=cut

sub add_filter(@) {
	my $self = shift;
	for (@_) {
		carp("Not a filter: $_") and next
				unless /^Mensa::Dresden::Filter=HASH\(0x[\da-f]{7}\)/;
		my $filter_type = ($_->is_negative ? 'n' : 'p') . '_filters';
		push $self->{ $filter_type }, $_;
	}
}

=item B<reset_filters>

Removes all added filters.

=cut

sub reset_filters() {
	my $self = shift;
	$self->{p_filters} = [];
	$self->{n_filters} = [];
}

=back

=cut


1;

=head1 TODOs

=over 4

=item extract the detail photo URL

=item check for network-connection

=item use namespace::clean to hide internals

=back

=head1 SEE ALSO

For a more detailed usage of a filter see Dresden::Mensa::Filter.

http://www.studentenwerk-dresden.de/mensen/speiseplan/

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by 8ware

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:fn="http://www.w3.org/2005/xpath-functions"
		xmlns:x="http://www.w3.org/1999/xhtml"
		version="1.0">
		<xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>

	<xsl:param name="name"/>
	<xsl:variable name="base">http://www.studentenwerk-dresden.de/mensen/speiseplan/</xsl:variable>

	<xsl:template match="/">
		<xsl:element name="offering">
			<xsl:for-each select="//div[@id='spalterechtsnebenmenue']/table[@class='speiseplan'
					and thead/tr/th[@class='text']=$name]">
				<xsl:element name="mensa">
					<xsl:attribute name="name">
						<xsl:value-of select="thead/tr/th[@class='text']"/>
					</xsl:attribute>
					<xsl:for-each select="tbody/tr">
						<xsl:if test="string-length(td[@class='text']/a/@href) > 0">
							<xsl:element name="meal">
								<xsl:attribute name="url">
									<xsl:variable name="detailURI" select="td[@class='text']/a/@href"/>
									<!--xsl:value-of select="td[@class='text']/a/@href"/-->
									<xsl:choose>
										<xsl:when test="starts-with($detailURI, $base)">
											<xsl:value-of select="$detailURI"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="concat($base, $detailURI)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
								<xsl:element name="name">
									<xsl:value-of select="td[@class='text']/a"/>
								</xsl:element>
								<xsl:for-each select="td[@class='stoffe']/a/img">
									<xsl:element name="ingredient">
										<xsl:choose>
											<xsl:when test="contains(@title, 'vegan')">
												<xsl:value-of select="substring(@title, 10)"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="substring(@title, 14)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:element>
								</xsl:for-each>
							</xsl:element>
						</xsl:if>
					</xsl:for-each>
				</xsl:element>
			</xsl:for-each>
		</xsl:element>
	</xsl:template>

</xsl:stylesheet>

