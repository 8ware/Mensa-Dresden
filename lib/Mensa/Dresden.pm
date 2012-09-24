package Mensa::Dresden;

use 5.014002;
use strict;
use warnings;

=head1 NAME

Mensa::Dresden - Perl interface to receive offerings of Dresden's canteens

=head1 SYNOPSIS

  use Mensa::Dresden ':filter';

  $mensa = Mensa::Dresden->new(
      'Alte Mensa',
	  create_filter(NAME, qr/steak/),
	  create_filter(INGREDIENTS, qr/vegan/, INVERSE)
  );

  @meals = $mensa->get_offering();
  @meals = $mensa->get_offering(TOMORROW);
  @meals = $mensa->get_offering(MONDAY, NEXT_WEEK);

=head1 DESCRIPTION

=head2 EXPORT

None by default, but there are several constants and some methods which can
be imported by the C<all>-tag. Additionally all date-related constants are
exported if the C<date>-tag is specified. Also, all filter-related stuff is
provided if the B<filter>-tag is given. The next section (CONSTANTS) shows
which constants and variables are available.

=cut

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	all => [ qw(
		TOMORROW
		MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY SUNDAY
		THIS_WEEK NEXT_WEEK AFTERNEXT_WEEK
		INVERSE NAME INGREDIENTS create_filter
	) ],
	date => [ qw(
		TOMORROW
		MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY SUNDAY
		THIS_WEEK NEXT_WEEK AFTERNEXT_WEEK
	) ],
	filter => [ qw(
		INVERSE NAME INGREDIENTS create_filter
	) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


use Carp;
use Fcntl 'SEEK_SET';
use HTTP::Request;
use LWP::UserAgent;
use XML::LibXML;
use XML::LibXSLT;

use Mensa::Dresden::Filter ':all';
use Mensa::Dresden::Meal;

=head2 CONSTANTS

=head3 FILTER RELATED

These constants are useful to create filters. (see the description
of the C<create_filter>-method for more information!)

=over 4

=item B<INVERSE>

This flag indicates that a filter will be inverted.

=item B<NAME>

The identifier for name-specific filters.

=item B<INGREDIENTS>

The identifier for ingredient-specific filters.

=back

=head3 DATE RELATED

The date related constants serve as a more readable form to specify
what meals are requested of which date, relative to the today's date.
(see the desciption of the C<get_offering>-method for more information!)

=over 4

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
	TOMORROW => (localtime time)[6] +1 % 7,

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


our $URL = 'http://www.studentenwerk-dresden.de/mensen/speiseplan/';

#
# the canteen-names with their appropriate mensa-IDs
#
our %MENSAS = (
	'Neue Mensa' => 8,
	'Alte Mensa' => 18,
	'Mensa Reichenbachstraße' => 9,
	'Mensologie' => 5,
	'Mensa Siedepunkt' => 6,
	'Mensa Johannstadt' => 32,
	'Mensa Blau' => 12,
	'BioMensa U-Boot' => undef,
	'Mensa TellerRandt' => 7,
	'Mensa Zittau' => 1,
	'Mensa Stimm-Gabel' => 13,
	'Mensa Palucca Schule' => 14,
	'Mensa Görlitz' => 15,
	'Mensa Haus VII' => 16,
	'Mensa Sport' => 19,
	'Mensa Kreuzgymnasium' => 20
);


use subs qw(get_url fetch_html load_stylesheet);

=head2 METHODS

=over 4

=item B<new>

Creates a new instance of a Dresden's canteen. The first argument is the
canteen's name while all succeeding arguments must be filters.

=cut

sub new {
	my $class = shift;
	my $mensa = shift;
	my @filters = @_;
	my @mensas = keys %MENSAS;
	return bless {
		name => $mensa,
		filters => \@filters
	}, $class if $mensa ~~ @mensas;
	croak("Unknown mensa: $mensa");
}

=item B<get_offering>

Accepts two arguments. The first one is the day, where 0 indicates sunday and
3 indicates wednesday. The second argument is the week, where 0 represents the
current, 1 the next and 2 the after next week. If both is omitted the current
day and week is supposed while the current week is assumed if only the week
parameter is omitted.

=cut

sub get_offering(;$$) {
	my $self = shift;
	my $day = defined $_[0] ? shift : (localtime time)[6];
	my $week = defined $_[0] ? shift : 0;
	my @filters = @{ $self->{filters} };
	my $stylesheet = load_stylesheet();
	my $url = get_url($week, $day);
	my $html = fetch_html($url);
	my $offering = $stylesheet->transform(
		$html,
#		XML::LibXSLT::xpath_to_string(base => $URL),
		XML::LibXSLT::xpath_to_string(base => ""),
		XML::LibXSLT::xpath_to_string(name => $self->{name})
	);
	my @meals;
	for ($offering->getElementsByTagName('meal')) {
#		$_->setAttribute('url', $URL . $_->getAttribute('url'));
		my $meal = Mensa::Dresden::Meal->new($_);
		push @meals, $meal
				if not @filters or grep { $_->pass($meal) } @filters;
	}
	return @meals;
}

sub get_url($$) {
	my ($week, $day) = @_;
	croak("Not a valid value: week=$week") if $week < 0 or $week > 2;
	croak("Not a valid value: day=$day") if $day < 0 or $day > 6;
	return $URL . "w$week-d$day.html";
}

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

sub load_stylesheet() {
	my $xslt = XML::LibXSLT->new();
	my $position = tell DATA;
	my $xsl = XML::LibXML->load_xml(IO => *DATA);
	seek DATA, $position, SEEK_SET;
	my $stylesheet = $xslt->parse_stylesheet($xsl);
	return $stylesheet;
}

=item B<get_name>

Returns the name of the canteen.

=cut

sub get_name() {
	my $self = shift;
	return $self->{name};
}

=item B<create_filter>

Creates a new filter. The first argument is the thing which should be
filtered, i.e. one of C<name> or C<ingredients>. To avoid typos the
C<NAME>- and C<INGREDIENTS>-constant should be used for identification.
The second argument is the regular expression which the thing must match
to get not rejected. The third parameter is optional and indicates whether
the filter is inverted, i.e. the thing must not match the expression to
get retained. To keep it more readable one can use the C<INVERSE>-constant
to get this done.

=cut

sub create_filter($$;$) {
	my ($criterion, $regex, $invert) = @_;
	return Mensa::Dresden::Filter->new(
		$criterion, qr/$regex/i, $invert || 0
	);
}

=back

=cut


1;

=head1 TODOs

=over 4

=item provide caching mechanism

If C<cache> is enabled the module will save the fetched html in a
temp-directory to enhance the speed of the module which otherwise
is dependent on the network-speed. The benefit will appear as the
offering is requested a second time.

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
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:x="http://www.w3.org/1999/xhtml">
	<xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>

	<xsl:param name="base"/>
	<xsl:param name="name"/>

	<xsl:template match="/">
		<xsl:element name="offering">
			<xsl:for-each select="//div[@id='spalterechtsnebenmenue']/table[@class='speiseplan'
						and thead/tr/th[@class='text']=$name]">
				<xsl:element name="mensa">
					<xsl:attribute name="name">
						<xsl:value-of select="thead/tr/th[@class='text']"/>
					</xsl:attribute>
					<xsl:for-each select="tbody/tr">
						<!--xsl:if test="not(fn:empty(td[@class='text']/a))"-->
						<xsl:if test="string-length(td[@class='text']/a/@href) > 0">
							<xsl:element name="meal">
								<xsl:attribute name="url">
									<xsl:value-of select="concat($base, td[@class='text']/a/@href)"/>
									<!--xsl:value-of select="resolve-uri(td[@class='text']/a/@href, $base)"/-->
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

