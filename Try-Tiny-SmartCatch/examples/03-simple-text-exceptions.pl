#!/usr/bin/env perl

use strict;
use warnings;
use 5.006;

use Try::Tiny::SmartCatch;

try sub {
    my $value = int (rand (10));
    die ('odd') if ($value % 2 != 0);
    die ('even') if ($value % 2 == 0);
},
catch_when 'odd' => sub {
    print "value is odd\n";
},
catch_when 'even' => sub {
    print "value is even\n";
};
