#!/usr/bin/env perl

use strict;
use warnings;
use 5.006;

# look below: we import :all tag! It's required for throw ()
use Try::Tiny::SmartCatch 0.5 qw/:all/;
my ($fh);
try sub {
    local ($!);
    open ($fh, '<', '/non-existent');
    throw (IOError->new ("$!", $!+0))
        if ($! =~ /No such file or directory/);
    throw (OtherError->new ("$!", $!+0))
        if ($!);
},
catch_when 'IOError' => sub {
    print "File is missing\n";
},
catch_when 'BaseError' => sub {
    print "Other error: [", $_->code, "] ", $_->msg, ".\n";
},
catch_default sub {
    print "Q";
},
finally sub {
    close ($fh) if ($fh);
};

try sub {
    local ($!);
    open ($fh, '<', '/etc/sudoers');
    throw (IOError->new ("$!", $!+0))
        if ($! =~ /No such file or directory/);
    throw (OtherError->new ("$!", $!+0))
        if ($!);
},
catch_when 'IOError' => sub {
    print "File is missing\n";
},
catch_when 'BaseError' => sub {
    print "Other error: [", $_->code, "] ", $_->msg, ".\n";
},
catch_default sub {
    print "Q";
},
finally sub {
    close ($fh) if ($fh);
};

package BaseError;
sub new {
    my ($class, $msg, $code) = @_;

    my $self = {
        code => $code,
        msg  => $msg
    };

    return bless ($self, $class);
}
sub code { return $_[0]{code} }
sub msg { return $_[0]{msg} }

package IOError; use base 'BaseError';
package PermissionsError; use base 'BaseError';
package OtherError; use base 'BaseError';

