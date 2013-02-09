#!/usr/bin/env perl

use strict;
use warnings;
use 5.006;

use Try::Tiny::SmartCatch 0.5;

try sub {
    local ($!);
    my ($fh);
    open ($fh, '<', '/etc/shells') or die ($!);
    return $fh;
},
then sub {
    my ($fh) = @_;

    1 while (<$fh>);
    print "There is $. shells in your system configuration.\n";
    close ($fh);
},
catch_when 'No such file or directory' => sub {
    print "File is missing\n";
},
catch_when 'Permission denied' => sub {
    print "Permissions error\n";
},
catch_default sub {
    print "Other error: $_";
};

