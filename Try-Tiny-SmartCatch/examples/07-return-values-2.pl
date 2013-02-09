#!/usr/bin/env perl

use strict;
use warnings;
use 5.006;

use Try::Tiny::SmartCatch 0.5;

sub has_pattern {
    my ($path, $pattern) = @_;
    return try sub {
        my ($fh);
        open ($fh, '<', $path) or die ($!);
        return $fh;
    },
    then sub {
        my ($fh) = @_;

        my $data = join ('', <$fh>);
        return $data =~ /$pattern/ ? 1 : 0;
    },
    catch_default sub {
        return 0;
    };
}

my $has_zsh = has_pattern ('/etc/shells', qr/^.*\/zsh$/m);
print "You ", ($has_zsh ? "have" : "have not"), " zsh in your /etc/shells.\n";

