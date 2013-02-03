use strict;
use warnings;

use feature 'say';

use Test::More tests => 2;
BEGIN { use_ok('Mensa::Dresden::Utils', ':all') };

my @args = qw(mensa siedepunkt mensa neue mensa);
my @got = parse_args(@args);
is_deeply(\@got, [ 'Mensa Siedepunkt', 'Neue Mensa' ],
		"parse given mensa arguments");

