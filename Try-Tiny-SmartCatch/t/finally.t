#!/usr/bin/perl

# borrowed from Try::Tiny

use strict;
#use warnings;

use Test::More tests => 24;

BEGIN { use_ok 'Try::Tiny::SmartCatch' };

try sub {
	my $a = 1+1;
}, catch_all sub {
	fail('Cannot go into catch block because we did not throw an exception')
}, finally sub {
	pass('Moved into finally from try');
};

try sub {
	die('Die');
}, catch_all sub {
	ok($_ =~ /Die/, 'Error text as expected');
	pass('Into catch block as we died in try');
}, finally sub {
	pass('Moved into finally from catch');
};

try sub {
	die('Die');
}, finally sub {
	pass('Moved into finally from catch');
}, catch_all sub {
	ok($_ =~ /Die/, 'Error text as expected');
};

try sub {
	die('Die');
}, finally sub {
	pass('Moved into finally block when try throws an exception and we have no catch block');
};

try sub {
  die('Die');
}, finally sub {
  pass('First finally clause run');
}, finally sub {
  pass('Second finally clause run');
};

try sub {
  # do not die
}, finally sub {
  if (@_) {
    fail("errors reported: @_");
  } else {
    pass("no error reported") ;
  }
};

try sub {
  die("Die\n");
}, finally sub {
  is_deeply(\@_, [ "Die\n" ], "finally got passed the exception");
};

try sub {
    try sub {
        die "foo";
    },
    catch_all sub {
        die "bar";
    },
    finally sub {
        pass("finally called");
    };
};

$_ = "foo";
try sub {
    is($_, "foo", "not localized in try");
},
catch_all sub {
},
finally sub {
    is(scalar(@_), 0, "nothing in \@_ (finally)");
    is($_, "foo", "\$_ not localized (finally)");
};
is($_, "foo", "same afterwards");

$_ = "foo";
try sub {
    is($_, "foo", "not localized in try");
    die "bar\n";
},
catch_all sub {
    is($_[0], "bar\n", "error in \@_ (catch)");
    is($_, "bar\n", "error in \$_ (catch)");
},
finally sub {
    is(scalar(@_), 1, "error in \@_ (finally)");
    is($_[0], "bar\n", "error in \@_ (finally)");
    is($_, "foo", "\$_ not localized (finally)");
};
is($_, "foo", "same afterwards");
1;
