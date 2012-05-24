#!/usr/bin/perl

# borrowed from Try::Tiny

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "Perl 5.10 is required" unless eval { require 5.010 };
    plan tests => 3;
    use_ok("Try::Tiny::SmartCatch");
}

use 5.010;

my ( $error, $topic );

given ("foo") {
    when (qr/./) {
        try sub {
            die "blah\n";
        }, catch_default sub {
            $topic = $_;
            $error = $_[0];
        }
    };
}

is( $error, "blah\n", "error caught" );

{
    local $TODO = "perhaps a workaround can be found";
    is( $topic, $error, 'error is also in $_' );
}

# ex: set sw=4 et:

