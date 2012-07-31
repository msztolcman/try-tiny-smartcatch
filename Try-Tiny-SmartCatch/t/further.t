#!/usr/bin/perl

use strict;
# use warnings;

use Test::More tests => 14;

BEGIN { use_ok 'Try::Tiny::SmartCatch' };

try sub {
	my $a = 1+1;
}, catch_default sub {
	fail('Cannot go into catch_default block because we did not throw an exception');
}, then sub {
	pass('Moved into then from try');
}, finally sub {
    pass('Run finally block with no exception and with then block');
};

try sub {
	die('Die');
}, catch_default sub {
	ok($_ =~ /Die/, 'Error text as expected');
	pass('Into catch_default block as we died in try');
}, then sub {
	fail('Cannot go into then block because an exception was raised');
}, finally sub {
    pass('Run finally block with exception raised');
};

try sub {
	die('Die');
}, then sub {
	fail('Cannot go into then block because an exception was raised');
}, catch_default sub {
	ok($_ =~ /Die/, 'Error text as expected');
};

try sub {
	die('Die');
}, then sub {
	fail('Cannot go into then block when try throws an exception');
};

try sub {
  # do not die
}, then sub {
  pass('First then clause run');
}, then sub {
  fail('Second then clause run');
}, finally sub {
    pass('Run finally block with no exception and with two then blocks');
};

try sub {
  return (qw/a b c/);
},
then sub {
    pass('Run then block where no exception was raised');
    is_deeply(\@_, [qw/a b c/], 'Got correct arguments from try clause');
};

try sub {
  return (qw/a b c/);
},
then sub {
  pass('Run then block where no exception was raised');
  is_deeply(\@_, [qw/a b c/], 'Got correct arguments from try clause');
},
finally sub {
  pass('Run finally block with no exception and with then block');
};

1;
