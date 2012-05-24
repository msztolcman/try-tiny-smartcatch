#!/usr/bin/env perl

use strict;
use warnings;

package BaseError;
sub new { bless {}, $_[0] }

package Error1;
use base 'BaseError';

package Error2;
use base 'BaseError';

package Error3;
use base 'BaseError';

package Error4;
use base 'BaseError';


package main;

use Test::More;

BEGIN {
	plan tests => 14;
}


BEGIN { use_ok 'Try::Tiny::SmartCatch' }

is ((try sub { die Error1->new () }, catch_when 'Error1'  => sub { 42 }), 42, 'exit from catch_when clause (exception as object)');

note ('test for caught single exception');
try sub {
    die (Error1->new ());
},
catch_when 'Error1' => sub {
    pass ('Correctly caught Error1 exception');
},
catch_when ['Error2', 'Error3', ] => sub {
    fail ('Uncorrectly caught Error2/Error3 exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught multi exceptions (1)');
try sub {
    die (Error2->new ());
},
catch_when 'Error1' => sub {
    fail ('Uncorrectly caught Error1 exception');
},
catch_when ['Error2', 'Error3', ] => sub {
    pass ('Correctly caught Error2/Error3 exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught multi exceptions (2)');
try sub {
    die (Error3->new ());
},
catch_when 'Error1' => sub {
    fail ('Uncorrectly caught Error1 exception');
},
catch_when ['Error2', 'Error3', ] => sub {
    pass ('Correctly caught Error2/Error3 exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught all exceptions');
try sub {
    die (Error4->new ());
},
catch_when 'Error1' => sub {
    fail ('Uncorrectly caught Error1 exception');
},
catch_when ['Error2', 'Error3', ] => sub {
    fail ('Uncorrectly caught Error2/Error3 exception');
},
catch_default sub {
    pass ('Correctly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught inherited exception (1)');
try sub {
    die (Error1->new ());
},
catch_when 'BaseError' => sub {
    pass ('Correctly caught BaseError exception');
},
catch_when 'Error1' => sub {
    fail ('Uncorrectly caught Error1 exception');
},
catch_when ['Error2', 'Error3', ] => sub {
    fail ('Uncorrectly caught Error2/Error3 exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught inherited exception (2)');
try sub {
    die (Error1->new ());
},
catch_when 'Error1' => sub {
    pass ('Correctly caught Error1 exception');
},
catch_when ['Error2', 'Error3', ] => sub {
    fail ('Uncorrectly caught Error2/Error3 exception');
},
catch_when 'BaseError' => sub {
    fail ('Uncorrectly caught BaseError exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

