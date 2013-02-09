#!/usr/bin/env perl

use strict;
use warnings;
use 5.006;

use Try::Tiny::SmartCatch;

# call some function, ignore fails
try sub {
    # ...
    die ('some error');
},
catch_default sub {
    print "Some error occured: $_";
};

# above is equivalent of:
# eval {
#     die ('some error');
# };
# if ($@) {
#     print "Some error occured: $@";
# }
