#!/usr/bin/env perl

use strict;
use warnings;
use 5.006;

use Try::Tiny::SmartCatch 0.5;

my ($fh);
try sub {
    local ($!);
    open ($fh, '<', '/non-existent') or die ($!);
},
catch_when 'No such file or directory' => sub {
    print "File is missing\n";
},
catch_when 'Permission denied' => sub {
    print "Permissions error\n";
},
catch_default sub {
    print "Other error: $_";
},
finally sub {
    close ($fh) if ($fh);
};

try sub {
    local ($!);
    open ($fh, '<', '/etc/sudoers') or die ($!);
},
catch_when 'No such file or directory' => sub {
    print "File is missing\n";
},
catch_when 'Permission denied' => sub {
    print "Permissions error\n";
},
catch_default sub {
    print "Other error: $_";
},
finally sub {
    close ($fh) if ($fh);
};

