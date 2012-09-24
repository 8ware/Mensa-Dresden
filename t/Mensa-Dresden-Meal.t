# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mensa-Dresden.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use feature 'say';

use Test::More tests => 1;
BEGIN { use_ok('Mensa::Dresden::Meal') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $s = 'abcd';
my $r = $s =~ s/^a//;
say $r;
$r = $s =~ s/^z//;
say $r;

