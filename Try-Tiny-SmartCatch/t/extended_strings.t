#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
	plan tests => 17;
}


BEGIN { use_ok 'Try::Tiny::SmartCatch' }

is ((try sub { die 'some error' }, catch_when 'some error'  => sub { 42 }), 42, 'exit from catch_when clause (exception as string)');
is ((try sub { die 'some error' }, catch_when qr/some.error/  => sub { 42 }), 42, 'exit from catch_when clause (exception as regexp)');

note ('test for caught single exception (string)');
try sub {
    die ('some error1');
},
catch_when 'error1' => sub {
    pass ('Correctly caught "error1" exception');
},
catch_when ['error2', 'error3', ] => sub {
    fail ('Uncorrectly caught "error2"/"error3" exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught single exception (regexp)');
try sub {
    die ('some error1');
},
catch_when qr/error\d/ => sub {
    pass ('Correctly caught "error1" exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught multi exceptions (1) (string)');
try sub {
    die ('some error2');
},
catch_when 'error1' => sub {
    fail ('Uncorrectly caught "error1" exception');
},
catch_when ['error2', 'error3', ] => sub {
    pass ('Correctly caught "error2"/"error3" exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught multi exceptions (2) (string)');
try sub {
    die ('some error3');
},
catch_when 'error1' => sub {
    fail ('Uncorrectly caught "error1" exception');
},
catch_when ['error2', 'error3', ] => sub {
    pass ('Correctly caught "error2"/"error3" exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught multi exceptions (1) (regexp)');
try sub {
    die ('some error2');
},
catch_when 'error1' => sub {
    fail ('Uncorrectly caught "error1" exception');
},
catch_when [qr/error\d/, qr/errors\d/, ] => sub {
    pass ('Correctly caught "error\d"/"errors\d" exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught multi exceptions (2) (regexp)');
try sub {
    die ('some errors2');
},
catch_when 'error1' => sub {
    fail ('Uncorrectly caught "error1" exception');
},
catch_when [qr/error\d/, qr/errors\d/, ] => sub {
    pass ('Correctly caught "error\d"/"errors\d" exception');
},
catch_default sub {
    fail ('Uncorrectly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};

note ('test for caught all exceptions');
try sub {
    die ('some error4');
},
catch_when 'error1' => sub {
    fail ('Uncorrectly caught "error1" exception');
},
catch_when ['error2', 'error3', ] => sub {
    fail ('Uncorrectly caught "error2"/"error3" exception');
},
catch_default sub {
    pass ('Correctly caught catch_default');
},
finally sub {
    pass ('Correctly executed finally clause');
};


