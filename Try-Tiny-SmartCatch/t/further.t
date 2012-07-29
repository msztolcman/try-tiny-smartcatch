#!/usr/bin/perl

use strict;
# use warnings;

use Test::More tests => 14;

BEGIN { use_ok 'Try::Tiny::SmartCatch' };

try sub {
	my $a = 1+1;
}, catch_default sub {
	fail('Cannot go into catch_default block because we did not throw an exception');
}, further sub {
	pass('Moved into further from try');
}, finally sub {
    pass('Run finally block with no exception and with further block');
};

try sub {
	die('Die');
}, catch_default sub {
	ok($_ =~ /Die/, 'Error text as expected');
	pass('Into catch_default block as we died in try');
}, further sub {
	fail('Cannot go into further block because an exception was raised');
}, finally sub {
    pass('Run finally block with exception raised');
};

try sub {
	die('Die');
}, further sub {
	fail('Cannot go into further block because an exception was raised');
}, catch_default sub {
	ok($_ =~ /Die/, 'Error text as expected');
};

try sub {
	die('Die');
}, further sub {
	fail('Cannot go into further block when try throws an exception');
};

try sub {
  # do not die
}, further sub {
  pass('First further clause run');
}, further sub {
  fail('Second further clause run');
}, finally sub {
    pass('Run finally block with no exception and with two further blocks');
};

try sub {
  return (qw/a b c/);
},
further sub {
    pass('Run further block where no exception was raised');
    is_deeply(\@_, [qw/a b c/], 'Got correct arguments from try clause');
};

try sub {
  return (qw/a b c/);
},
further sub {
  pass('Run further block where no exception was raised');
  is_deeply(\@_, [qw/a b c/], 'Got correct arguments from try clause');
},
finally sub {
  pass('Run finally block with no exception and with further block');
};

1;
