use strict;
use warnings;

use encoding 'utf8';

=head1 NAME

Mensa::Dresden::Test - test suite of the Mensa::Dresden module

=cut

use Test::More tests => 9;
BEGIN { use_ok('Mensa::Dresden', ':all') };

use File::Basename;
use Cwd 'abs_path';

=head1 DESCRIPTION

Tests all relevant subroutines and functionalities of a Mensa::Dresden
object. To speed up the tests the URL used to receive the canteen's
offering is redirected to t/res, where three sample offerings are located.

=cut

my $t_dir = abs_path dirname($0);
$Mensa::Dresden::URL = "file://$t_dir/res/";

mkdir "$t_dir/tmp" or die "Can't create directory $t_dir/tmp: $!"
		unless -d "$t_dir/tmp";
$Mensa::Dresden::CACHE_PATH = "$t_dir/tmp/mensa";

$Mensa::Dresden::caching = 0;

=head2 TEST-CASES

=over 4

=item B<constructor>

Test of the behavior on an unknown canteen name.

=cut

eval "Mensa::Dresden->new('Mensa Fail')";
ok($@, "[new] fail with unknown canteen name");

my $mensa = Mensa::Dresden->new('Alte Mensa');

our %w0d0 = (
	'Hacksteak mit Bratensoße, buntem Gemüse und Petersilienkartoffeln'
	=> [ qw(Schweinefleisch Rindfleisch) ],
	'Drei Kartoffel-Frischkäsetaschen mit buntem Gemüse'
	=> [ 'kein Fleisch' ],
	'Wok & Grill: Garnelenpfanne mit buntem Gemüse aus dem Wok, dazu Basmati Reis'
	=> [ qw(Alkohol Knoblauch) ],
	'Gefülltes Pizzabrötchen'
	=> [ 'kein Fleisch' ],
	'Pizzabrot mit Kräuterbutter und Käse,'
	=> [],
	'Pasta: Käserahmsoße mit Blattspinat'
	=> [ 'kein Fleisch', 'Rindfleisch' ],
	'Pasta: Tomatensoße mit Jagdwurst'
	=> [ qw(Schweinefleisch Rindfleisch Knoblauch) ]
);
our %w1d1 = (
	'Rindergulasch ungarischer Art mit Rosenkohl, Hefeknödeln oder Petersilienkartoffeln'
	=> [ 'Rindfleisch' ],
	'Tofufrikadelle mit Zwiebel und Paprika an scharfer Tomatensalsa und Pastasotto'
	=> [ 'kein Fleisch', qw(Alkohol Knoblauch) ],
	'Wok & Grill: Rückensteak vom Schwein mit Orangen-Pfeffersoße'
	=> [ 'Schweinefleisch' ],
	'Hausgemachte Pasta, heute Amori mit Kräuter-Pilzpesto'
	=> [ 'Schweinefleisch' ],
	'Pizza Bel Paese mit Tomaten und Hirtenkäse'
	=> [ 'kein Fleisch', 'Knoblauch' ],
	'Pizza mit Peperonisalami, Zwiebeln und Paprika'
	=> [ qw(Schweinefleisch Rindfleisch Knoblauch) ],
	'Pasta: Tomatensoße mit Paprika'
	=> [ 'kein Fleisch', 'Knoblauch' ],
	'Pasta: Pute in fruchtiger Currysoße'
	=> [ 'Knoblauch' ],
	'Auflauf: Aprikosen-Quarkauflauf mit Sauerkirschen'
	=> [ 'kein Fleisch' ],
	'Terrine: Brühgräupchen mit Kassler und Kohlrabi'
	=> [ qw(Schweinefleisch Rindfleisch) ]);
our %w2d3 = (
	'Hackfleischbällchen in Kapernsoße mit Möhrengemüse, dazu Reis oder Petersilienkartoffeln'
	=> [ qw(Schweinefleisch Rindfleisch) ],
	'Schweinskammsteak Zigeuner Art mit Erbsen und Pommes frites'
	=> [ qw(Schweinefleisch Rindfleisch) ],
	'Frühlingsrolle an geschmortem Spinat mit Ingwer,Sojasoße und Knoblauch , dazu Reis'
	=> [ 'kein Fleisch', 'Knoblauch' ],
	'Wok & Grill: Garnelenpfanne mit buntem Gemüse aus dem Wok an Mie Nudeln'
	=> [ qw(Alkohol Knoblauch) ],
	'Hausgemachte frische Pasta, heute Linguine Carbonara'
	=> [ qw(Schweinefleisch Knoblauch) ],
	'Pizza Funghi mit Champignons, Zwiebeln und Mais'
	=> [ 'Knoblauch' ],
	'Pizza Bombay mit Hähnchenfleisch, Ananas und Currycreme'
	=> [ 'Knoblauch' ],
	'Pasta: Frischkäse-Kräutersoße'
	=> [ 'kein Fleisch' ],
	'Pasta: Zigeunersoße'
	=> [ qw(Schweinefleisch Rindfleisch Knoblauch) ],
	'Auflauf: Kartoffel-Bohnenauflauf'
	=> [],
);

sub test_get_offering($$);
sub test_filtering($$@);

=item B<meal scrapping>

Tests to check the extraction/scrapping of the meals from the HTML
resources.

=cut

test_get_offering(0,0);
test_get_offering(1,1);
test_get_offering(3,2);

=item B<meal filtering>

Tests to ensure that the filters are applied in the right order.

=cut

test_filtering(0, 0,
	'Hacksteak mit Bratensoße, buntem Gemüse und Petersilienkartoffeln',
	'Drei Kartoffel-Frischkäsetaschen mit buntem Gemüse',
	[ name => qr/steak/i, POSITIVE ],
	[ name => qr/kartoffel-frischkäsetaschen/i, POSITIVE ]
);
test_filtering(1, 1,
	'Wok & Grill: Rückensteak vom Schwein mit Orangen-Pfeffersoße',
	[ name => qr/steak/i, POSITIVE ],
	[ name => qr/frikadelle/i, POSITIVE ],
	[ name => qr/tofu/i, NEGATIVE ]
);
test_filtering(3, 2,
	'Hackfleischbällchen in Kapernsoße mit Möhrengemüse, dazu Reis oder Petersilienkartoffeln',
	'Schweinskammsteak Zigeuner Art mit Erbsen und Pommes frites',
	'Hausgemachte frische Pasta, heute Linguine Carbonara',
	[ name => qr/mie nudeln/i, NEGATIVE ],
	[ name => qr/^pasta/i, NEGATIVE ],
	[ name => qr/^pizza/i, NEGATIVE ],
	[ name => qr/^auflauf/i, NEGATIVE ],
	[ ingredients => qr/kein Fleisch/i, NEGATIVE ]
);

=item B<caching>

Tests to check the caching mechanism.

=cut

subtest("test caching mechanism" => sub {
		plan(tests => 6);

		ok(! -f "$Mensa::Dresden::CACHE_PATH-00.cache",
				"mensa cache for day 0 in week 0 does not exist");
		ok(! -f "$Mensa::Dresden::CACHE_PATH-11.cache",
				"mensa cache for day 1 in week 1 does not exist");
		ok(! -f "$Mensa::Dresden::CACHE_PATH-23.cache",
				"mensa cache for day 3 in week 2 does not exist");

		$Mensa::Dresden::caching = 1;

		$mensa->get_offering(0, 0);
		$mensa->get_offering(1, 1);
		$mensa->get_offering(3, 2);

		ok(-f "$Mensa::Dresden::CACHE_PATH-00.cache",
				"mensa cache for day 0 in week 0 exists after enabling");
		ok(-f "$Mensa::Dresden::CACHE_PATH-11.cache",
				"mensa cache for day 1 in week 1 exists after enabling");
		ok(-f "$Mensa::Dresden::CACHE_PATH-23.cache",
				"mensa cache for day 3 in week 2 exists after enabling");
});

=back

=head2 TEST-METHODS

=over 4

=item B<test_get_offering>

Expects the day and the week of the offering to be tested. The offering
is requested from the mensa and compared with the expected one which is
automatically got from the day and week parameter.

=cut

sub test_get_offering($$) {
	my ($day, $week) = (shift, shift);
	my %offering;
	{
		no strict 'refs';
		%offering = %{__PACKAGE__."::w$week"."d$day"};
	}
	my @offering = keys %offering;
	return unless @offering;
	subtest("[get_offering] of day $day in week $week" => sub {
			plan(tests => 2 * scalar @offering);
			my @meals = $mensa->get_offering($day, $week);
			for (@meals) {
				my $name = $_->name;
				ok($name ~~ @offering, "meal is an expected one");
				is_deeply([ $_->ingredients ], $offering{$name},
						"all expected ingredients given");
			}
	});
}

=item B<test_filtering>

Acceps the day and the week and a list of (1) expected meals and
(2) anonymous arrays which contain the criterion, the regex and the
positive/negative-flag. The filters will be added to the mensa, then
the offering is requested and the obtained meals are checked for
their expectation.

=cut

sub test_filtering($$@) {
	my ($day, $week) = (shift, shift);
	my ($regexes, @offering) = 0;
	for (@_) {
		if (ref eq 'ARRAY') {
			my ($criterion, $regex, $negative) = @{$_};
			$mensa->create_filter($criterion, $regex, $negative);
			$regexes++;
		} else {
			push @offering, $_;
		}
	}
	subtest("[get_offering] filtered with $regexes regexes" => sub {
			plan(tests => scalar @offering);
			my @meals = $mensa->get_offering($day, $week);
			for (@meals) {
				my $name = $_->name;
				ok($name ~~ @offering, "meal is an expected one");
			}
	});
	$mensa->reset_filters();
}

=back

=head1 TODOs

=over 4

=item check different filter cases/levels

=item implement test for XSL which uses real current HTML from the offerings
      website to verify the validity of the stylesheet (maybe the structure
	  of the canteen sites someday changes)

=back

=cut

unlink <$t_dir/tmp/mensa-*.cache>;
rmdir "$t_dir/tmp" or warn "Can't remove directory $t_dir/tmp: $!";

