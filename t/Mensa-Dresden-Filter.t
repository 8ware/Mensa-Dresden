use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('Mensa::Dresden::Filter', ':all') };

use XML::LibXML;
use Mensa::Dresden::Meal;

eval "Mensa::Dresden::Filter->new(fail => qr/criterion/)";
ok($@, "[new] unsupported criterion");

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
my $meal = Mensa::Dresden::Meal->new($xml->getElementsByTagName('meal'));

my $filter;

$filter = Mensa::Dresden::Filter->new(name => qr/test/);
ok($filter->pass($meal), "[pass] on name (passes)");
ok(!$filter->is_negative(), "[is_negative] returns false");

$filter = Mensa::Dresden::Filter->new('name', qr/name/, NEGATIVE);
ok(!$filter->pass($meal), "[pass] on name [negative] (fails)");

$filter = Mensa::Dresden::Filter->new('ingredients', qr/vegan/, NEGATIVE);
ok(!$filter->pass($meal), "[pass] on ingredients [negative] (fails)");
ok($filter->is_negative(), "[is_negative] returns true");

