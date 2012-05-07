Introduction
============

Try::Tiny::Extended is Perl module for easy handling exceptions.

It's mostly the same as [Try::Tiny](https://metacpan.org/module/Try::Tiny) module, but there
few changes to it's specification:

* allow caught just single type of exception
* explicit sub definitions instead of anonymous

Syntax
======

Just silence errors:

    try sub {
        die ('some error');
    };

Run some code and catch all exceptions:

    try sub {
        die ('some error');
    },
    catch_all sub {
        say "Caught an exception: $_";
    };

Catch only exceptions containing string 'error' in message:

    try sub {
        die ('some error');
    },
    catch 'error' => sub {
        say 'Caught exception with "error" substring in message';
    };

Or nearly the same with regexps:

    try sub {
        die ('some error1');
    },
    catch qr/\berror\d\b/ => sub {
        say 'Caught exception message matched to regexp: "\berror\d\b"';
    };

Catch only exceptions of `BaseError` class:

    try sub {
        die (BaseError->new ('some error'));
    },
    catch 'BaseError' => sub {
        say 'Caught "BaseError" exception';
    };

Catch exceptions `Error1` or `Error2`:

    try sub {
        die (Error1->new ('some error'));
    },
    catch [qw/Error1 Error2/] => sub {
        say 'Caught "Error1" or "Error2" exception';
    };

Catch exceptions inherited from ArithmeticError:

    try sub {
        die (OverflowError->new ('some error'));
    },
    catch 'ArithmeticError' => sub {
        say 'Caught some arithmetic error';
    };

Catch exception and run `finally` block:

    try sub {
        die ('some error');
    },
    catch 'error' => sub {
        say 'Caught some error');
    },
    finally sub {
        say 'Finally block';
    };

And so on...
