#!/usr/bin/env perl

use strict;
use warnings;
use 5.006;

use Try::Tiny::SmartCatch 0.5;

sub safe_slurp {
    my ($path) = @_;
    return try sub {
        my ($fh);
        open ($fh, '<', $path) or die ($!);
        return <$fh>;
    },
    catch_default sub {
        return wantarray ? () : '';
    };
}

my $file = safe_slurp ('/etc/shells');
print "/etc/shells is ", length ($file), " characters long.\n";

my @lines = safe_slurp ('/etc/shells');
print "/etc/shells has ", scalar (@lines), " lines.\n";

