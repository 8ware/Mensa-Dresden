# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mensa-Dresden.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use feature 'say';
use encoding 'utf8';

use Test::More tests => 1;
BEGIN { use_ok('Mensa::Dresden', ':all') };

use File::Basename;
use Cwd 'abs_path';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $t_dir = abs_path dirname($0);
# redirect, available: w0-d0.html, w1-d1.html, w2-d3.html
$Mensa::Dresden::URL = "file://$t_dir/res/";

my $steak_filter = create_filter('name', qr/steak/i);
my $beefsteak_filter = create_filter('name', qr/Rinderhüftsteak/);
my $meat_filter = create_filter('ingredients', qr/kein Fleisch/, 1);
my $antitofu_filter = create_filter('name', qr/tofu/i, 1);
my $meatball_filter = create_filter('name', qr/frikadelle/i);

my $mensa = Mensa::Dresden->new('Alte Mensa');#, $beefsteak_filter, $meat_filter);
$mensa->add_filter($steak_filter);
$mensa->add_filter($beefsteak_filter);
$mensa->add_filter($meat_filter);
$mensa->add_filter($meatball_filter);
$mensa->add_filter($antitofu_filter);
$mensa->create_filter('ingredients', qr/vegan/, 1);
$mensa->create_filter('name', qr/^Terrine/, 1);
my @meals = $mensa->get_offering(1, 1); # TODO test for (0, 0)-param

say '=' x 20;

say $_->to_string() . "\n" for @meals;

# w0-d0.html ############################################
#
# Hacksteak mit Bratensoße, buntem Gemüse und Petersilienkartoffeln
# > Schweinefleisch, Rindfleisch
#
# Drei Kartoffel-Frischkäsetaschen mit buntem Gemüse
# > kein Fleisch
#
# Wok & Grill: Garnelenpfanne mit buntem Gemüse aus dem Wok, dazu Basmati Reis
# > Alkohol, Knoblauch
#
# Gefülltes Pizzabrötchen
# > kein Fleisch
#
# Pizzabrot mit Kräuterbutter und Käse,
# > -
#
# Pasta: Käserahmsoße mit Blattspinat
# > kein Fleisch, Rindfleisch
#
# Pasta: Tomatensoße mit Jagdwurst
# > Schweinefleisch, Rindfleisch, Knoblauch 
#
# w1-d1.html ############################################
#
# Rindergulasch ungarischer Art mit Rosenkohl, Hefeknödeln oder Petersilienkartoffeln
# > Rindfleisch
#
# Tofufrikadelle mit Zwiebel und Paprika an scharfer Tomatensalsa und Pastasotto
# > kein Fleisch, Alkohol, Knoblauch
#
# Wok & Grill: Rückensteak vom Schwein mit Orangen-Pfeffersoße
# > Schweinefleisch
#
# Hausgemachte Pasta, heute Amori mit Kräuter-Pilzpesto
# > Schweinefleisch
#
# Pizza Bel Paese mit Tomaten und Hirtenkäse
# > kein Fleisch, Knoblauch
#
# Pizza mit Peperonisalami, Zwiebeln und Paprika
# > Schweinefleisch, Rindfleisch, Knoblauch
#
# Pasta: Tomatensoße mit Paprika
# > kein Fleisch, Knoblauch
#
# Pasta: Pute in fruchtiger Currysoße
# > Knoblauch
#
# Auflauf: Aprikosen-Quarkauflauf mit Sauerkirschen
# > kein Fleisch
#
# Terrine: Brühgräupchen mit Kassler und Kohlrabi
# > Schweinefleisch, Rindfleisch
#
# w2-d3.html ############################################
#
# Hackfleischbällchen in Kapernsoße mit Möhrengemüse, dazu Reis oder Petersilienkartoffeln
# > Schweinefleisch, Rindfleisch
#
# Schweinskammsteak Zigeuner Art mit Erbsen und Pommes frites
# > Schweinefleisch, Rindfleisch
#
# Frühlingsrolle an geschmortem Spinat mit Ingwer,Sojasoße und Knoblauch , dazu Reis
# > kein Fleisch, Knoblauch
#
# Wok & Grill: Garnelenpfanne mit buntem Gemüse aus dem Wok an Mie Nudeln
# > Alkohol, Knoblauch
#
# Hausgemachte frische Pasta, heute Linguine Carbonara
# > Schweinefleisch, Knoblauch
#
# Pizza Funghi mit Champignons, Zwiebeln und Mais
# > Knoblauch
#
# Pizza Bombay mit Hähnchenfleisch, Ananas und Currycreme
# > Knoblauch
#
# Pasta: Frischkäse-Kräutersoße
# > kein Fleisch
#
# Pasta: Zigeunersoße
# > Schweinefleisch, Rindfleisch, Knoblauch
#
# Auflauf: Kartoffel-Bohnenauflauf
# > -

