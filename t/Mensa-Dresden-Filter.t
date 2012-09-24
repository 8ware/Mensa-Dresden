# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mensa-Dresden.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use feature 'say';

use Test::More 'no_plan';#tests => 1;
BEGIN { use_ok('Mensa::Dresden::Filter') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use XML::LibXML;
use Mensa::Dresden::Meal;

my $filter = Mensa::Dresden::Filter->new(
#	Mensa::Dresden::Meal::NAME,
	'name',
	qr/test/
);

my $xml = XML::LibXML->load_xml(string => <<XML);
<?xml version="1.0" encoding="UTF-8" ?>
<offering>
	<mensa name="Alte Mensa">
		<meal url="http://example.org/meal">
			<name>this is a test-name</name>
			<ingredient>Knoblauch</ingredient>
			<ingredient>vegan</ingredient>
		</meal>
	</mensa>
</offering>
XML

my @meals;
my $meal = Mensa::Dresden::Meal->new($xml->getElementsByTagName('meal'));

push @meals, $meal if $filter->pass($meal);

is(@meals, 1, "test filter::pass on name");

$filter = Mensa::Dresden::Filter->new('name', qr/name/, 1);

push @meals, $meal if $filter->pass($meal);

is(@meals, 1, "test filter::pass on name [inverse]");

$filter = Mensa::Dresden::Filter->new('ingredients', qr/vegan/, 1);

push @meals, $meal if $filter->pass($meal);

is(@meals, 1, "test filter::pass on ingredients [inverse]");

