#!/usr/bin/perl

# borrowed from Try::Tiny

use strict;
#use warnings;

use Test::More;

BEGIN {
	plan skip_all => "Perl 5.10 required" unless eval { require 5.010; 1 };
	plan tests => 6;
}


BEGIN { use_ok 'Try::Tiny::SmartCatch' }

use 5.010;

my ( $foo, $bar, $other );

$_ = "magic";

try sub {
	die "foo";
}, catch_all sub {

	like( $_, qr/foo/ );

	when (/bar/) { $bar++ };
	when (/foo/) { $foo++ };
	default { $other++ };
};

is( $_, "magic", '$_ not clobbered' );

ok( !$bar, "bar didn't match" );
ok( $foo, "foo matched" );
ok( !$other, "fallback didn't match" );
