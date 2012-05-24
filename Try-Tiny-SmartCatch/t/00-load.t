#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Try::Tiny::Extended' ) || print "Bail out!\n";
}

diag( "Testing Try::Tiny::Extended $Try::Tiny::Extended::VERSION, Perl $], $^X" );
