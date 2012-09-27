# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mensa-Dresden.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use feature 'say';
use encoding 'utf8';

use Test::More tests => 1;
BEGIN { use_ok('Mensa::Dresden') };

use File::Basename;
use Cwd 'abs_path';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Mensa::Dresden::Filter;

my $t_dir = abs_path dirname($0);
# redirect, available: w0-d0.html, w1-d1.html, w2-d3.html
$Mensa::Dresden::URL = "file://$t_dir/res/";

my $filter = Mensa::Dresden::Filter->new('ingredients', qr/kein Fleisch/, 1);

my $mensa = Mensa::Dresden->new('Alte Mensa');#, $filter);
my @meals = $mensa->get_offering(0, 0); # TODO test for (0, 0)-param

for (@meals) {
	say $_->name();
	my @ingredients = $_->ingredients;
	@ingredients = '-' unless @ingredients;
	local $" = ', ';
	say "> @ingredients\n";
}

