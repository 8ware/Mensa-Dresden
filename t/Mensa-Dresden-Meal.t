use strict;
use warnings;

use feature 'say';

use Test::More tests => 5;
BEGIN { use_ok('Mensa::Dresden::Meal', ':all') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use XML::LibXML;

my $test_url = 'http://example.org/meal';
my $test_name = 'this is a test-name';
my $test_ingr_1 = GARLIC;
my $test_ingr_2 = VEGAN;
my $xml = XML::LibXML->load_xml(string => <<XML);
<?xml version="1.0" encoding="UTF-8" ?>
<offering>
	<mensa name="Alte Mensa">
		<meal url="$test_url">
			<name>$test_name</name>
			<ingredient>$test_ingr_1</ingredient>
			<ingredient>$test_ingr_2</ingredient>
		</meal>
	</mensa>
</offering>
XML
my $meal = Mensa::Dresden::Meal->new($xml->getElementsByTagName('meal'));

is($meal->url, $test_url, "[url] returns right url");
is($meal->name, $test_name, "[name] returns right name");
is_deeply([ $meal->ingredients ], [ $test_ingr_1, $test_ingr_2 ],
		"[ingredients] returns all ingredients");

TODO: {
	local $TODO = 'schema validation not implemented, yet';
	my $fail_xml = XML::LibXML->load_xml(string => <<XML);
<?xml version="1.0" encoding="UTF-8" ?>
<offering>
<mensa name="Alte Mensa">
	<meal name="$test_name">
		<ingredient>$test_ingr_1</ingredient>
		<ingredient>$test_ingr_2</ingredient>
	</meal>
</mensa>
</offering>
XML
	my $meal = $fail_xml->getElementsByTagName('meal');
	eval "Mensa::Dresden::Meal->new($meal)";
	ok($@, "[new] invalid XML fails");
};

