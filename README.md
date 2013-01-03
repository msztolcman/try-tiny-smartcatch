Introduction
============

Try::Tiny::SmartCatch is lightweight Perl module for powerful exceptions
handling.

Syntax
======

```perl
use Try::Tiny::SmartCatch;

try sub {}, # at least one try block
catch_when 'ExceptionName' => sub {}, # zero or more catch_when blocks
catch_when 'exception message' => sub {},
catch_when qr/exception  message regexp/ => sub {},
then sub {}, # if no exception is raised, execute then block
catch_default sub {}, # zero or one catch_default block
finally sub {}; #zero or more finally blocks

use Try::Tiny::SmartCatch qw/throw/; # import only throw or:
use Try::Tiny::SmartCatch qw/:all/; # import all functions
throw ('some exception');
throw (SomeException->new ('message'));
```

But first...
============

Please, read [Try::Tiny](https://metacpan.org/module/Try::Tiny) manual first.
Most code of ```Try::Tiny::SmartCatch``` is borrowed from it, so most caveats,
problems or goals is the same!

I don't want to copy manual section from it too ;)

Description
===========

Goals are mostly the same as [Try::Tiny](https://metacpan.org/module/Try::Tiny)
module, but there are few changes to it's specification. Main difference
is possibility to catch just some kinds of exceptions in place of catching
everything. Another one is slightly changed syntax.

When raised exception is an object, ```Try::Tiny::SmartCatch``` will test for
exception type (using ```UNIVERSAL::isa```). When raised exception is just
a text message (like: ```die ('message')```), there can be specified part of
message to test for.

There are also explicit ```sub``` blocks. In opposite to ```Try::Tiny```,
every block in ```Try::Tiny::SmartCatch```: ```try```, ```catch_when```, ```catch_default```,
```then``` and ```finally``` must have explicit subroutines specified. Thanks to trick
with function prototype, calling ```Try::Tiny::try``` or ```Try::Tiny::catch```
creates implicit subroutines:

```perl
sub test_function {
    try {
        # yes, here is implicit subroutine!
        # return statement here exits just from try block,
        # not from test_function!
        return 1;
    };

    say 'Hello!';
}

test_function ();
```

Above snippet produces us text on STDOUT: ```Hello!```

But more obvious would be no output... (by ```return``` statement). This is because of
implicit subroutine created with braces: ```{}``` after ```try```,
 ```catch``` or ```finally``` from ```Try::Tiny```. ```Try::Tiny::SmartCatch``` is
more explicit - you must always use ```sub``` when defining blocks (look
at [Syntax](#Syntax) above).

An exception object or message is passed to defined blocks in two ways:
* in ```$_``` variable
* as function arguments, so through ```@_``` array.

```Try::Tiny::SmartCatch``` defines also ```throw``` function (not imported
by default). Currently it is an alias for ```die```, but is more explicit then ```die``` :)

It can be imported separately:
```perl
use Try::Tiny::SmartCatch qw/throw/;
```

Or with rest of functions:
```perl
use Try::Tiny::SmartCatch qw/:all/;
```

Piece of code
=============

Text exceptions
---------------

Catch only exceptions containing string 'No such file or directory' in message:

```perl
try sub {
    my ($fh, );
    open ($fh, '<', '/non_existent_file') or throw (qq/Can't open file for reading: $!/);
},
catch_when 'No such file or directory' => sub {
    say 'caught error: ', $_;
};
```

Or nearly the same with regexps, but case insensitive:

```perl
try sub {
    my ($fh, );
    open ($fh, '<', '/non_existent_file') or throw (qq/Can't open file for reading: $!/);
},
catch_when qr/no such file or directory/i => sub {
    say 'caught error: ', $_;
};
```

We can mix both types:

```perl
try sub {
    my ($fh, );
    open ($fh, '<', '/non_existent_file') or throw (qq/Can't open file for reading: $!/);

    # some operations on file
},
catch_when ['No such file or directory', qr/Some.+other.+text/i] => sub {
    say 'caught error: ', $_;
};
```

Object exceptions
-----------------

If raised exception is an object, you can catch every type of exception in
separate block of code.

Suppose we have exceptions:

```
Exception
|- IOException
   |- PermissionsException
   |- FileNotFoundException
   |- CharacterEncodingException
|- RuntimeException
```

It's easy now to respond to suitable error:

```perl
my ($fh, );
try sub {
    throw (FileNotFoundException->new (qq/File not found/))
        if (!-f $path);
    throw (PermissionsException->new (qq/Can't read file: not enough permissions/))
        if (!-r $path);
    open ($fh, '<', $path) or throw (RuntimeException->new (qq/Cannot open file $path for reading: $!/));

    # make some file operations here
},
catch_when 'FileNotFoundException' => sub {
    # create empty file
    open ($fh, '>', $path) && close ($fh);
},
catch_when 'PermissionsException' => sub {
    mail ('me@example.com', "Permission error at $path: ", $_);
};
```

In example above we have different reactions dependent on type of exception. If
there was an ```FileNotFoundException```, we just create this file. On
```PermissionsException``` want to have an email about this.

Of course, it's easy to catch 2 or more exceptions types, for example
```PermissionsException``` and ```RuntimeException``` should be handled in the
same way:

```perl
my ($fh, );
try sub {
    throw (FileNotFoundException->new (qq/File not found/))
        if (!-f $path);
    throw (PermissionsException->new (qq/Can't read file: not enough permissions/))
        if (!-r $path);
    open ($fh, '<', $path) or throw (RuntimeException->new (qq/Cannot open file $path for reading: $!/));

    # make some file operations here
},
catch_when 'FileNotFoundException' => sub {
    # create empty file
    open ($fh, '>', $path) && close ($fh);
},
catch_when ['PermissionsException', 'RuntimeException'] => sub {
    mail ('me@example.com', "Some error at $path: ", $_);
};
```

But what if we want to catch every exception related to IO? Well, to make it
harder, we want to create empty file if it doesn't exists yet, but sent an
email in any other ```IOException```. For example:

```perl
my ($fh, );
try sub {
    throw (FileNotFoundException->new (qq/File not found/))
        if (!-f $path);
    throw (PermissionsException->new (qq/Can't read file: not enough permissions/))
        if (!-r $path);
    open ($fh, '<', $path) or throw (RuntimeException->new (qq/Cannot open file $path for reading: $!/));

    # make some file operations here
},
catch_when 'FileNotFoundException' => sub {
    # create empty file
    open ($fh, '>', $path) && close ($fh);
},
# we catch here any IOException, also subclasses of it
catch_when 'IOException' => sub {
    mail ('me@example.com', "Some error at $path: ", $_);
};
```

Then block
-------------

```then``` block is called only if no exception is raised from ```try``` clause.
It's usefull, when you want to separate some blocks of code. ```then``` clause
has passed return value from ```try``` subroutine.

Return value from ```then``` block is returned as return value of ```try``` call.

```perl
my $data_length = try sub {
    my ($fh, );
    open ($fh, '<', '/etc/fstab') or throw ('Can\'t open file: ' . $!);
    return $fh;
},
catch_all sub {
    say $_;
},
then sub {
    my ($fh, ) = @_;
    
    my ($string, );
    try sub {
        sysread ($fh, $string, -s $fh, 0) or throw ($!);
    },
    catch_all sub {
        say $_;
    },
    then sub {
        say 'Read whole file at once!';
    };

    return length ($string);
},
finally sub {
    close ($fh);
};

say 'We read ' . $data_length ' bytes!';
```

Finally block
-------------

Hm, we also should always close file handler, so we can use ```finally``` block:

```perl
my ($fh, );
try sub {
    throw (FileNotFoundException->new (qq/File not found/))
        if (!-f $path);
    throw (PermissionsException->new (qq/Can't read file: not enough permissions/))
        if (!-r $path);
    open ($fh, '<', $path) or throw (RuntimeException->new (qq/Cannot open file $path for reading: $!/));

    # make some file operations here
},
# This catch block is specified before block of IOException
catch_when 'FileNotFoundException' => sub {
    open ($fh, '>', $path);
    close ($fh);
},
# we catch here any IOException, also subclasses of it
catch_when 'IOException' => sub {
    mail ('me@example.com', "Some error at $path: ", $_);
},
finally sub {
    close ($fh) if ($fh);
};
```

Return values
-------------

When ```try``` block evaluates and exception will not be raised, it returns
given anonymous subroutine return value. So, if given block returns some
object, as a return value of ```try``` block you got this object.

This behavior is slightly modified if there is specified ```then``` block - as
return value of whole ```try``` call is given return value from ```then``` block.

If there is an exception inside ```try``` block, return value of whole block
is return value of ```catch_*``` block which caught this kind exception. For example:

```perl
my $value = try sub { throw ('error') },
catch_when 'error' => sub { say 'error'; 1 },
catch_when 'exception' => sub { say 'exception'; 2 },
catch_default sub { say 'default error handling'; 3 },
then sub { say 'then is called'; 4 };
```

In ```$value``` you get ```1```. If the message in ```try``` block will
change to 'exception', ```$value``` will have ```2```. If the message will
change into something other value, in ```$value``` will be an integer ```3```.
In case, when in ```try``` block we don't raise an exception, in ```$value``` you
got ```4```.

Silence errors
-----

Sometimes we want to just silence errors:

```perl
use autodie qw/open/;

try sub {
    open (my $fh, '<', '/etc/fstab');

    # some operations on /etc/fstab here
};
```

In example above we just try to open /etc/fstab, and do some operations there.
Without ```try``` block, your program will stop in place of ```open``` call,
if there were any error.

catch_default
-------------

There is also posibility to catch all types of exceptions:

```perl
try sub {
    throw ('some error');
},
catch_default sub {
    say "Caught an exception: $_";
};
```

Multiplicity
------------

```try``` block must exists exactly once. ```catch_when``` and ```finally```
blocks are allowed to exists zero or more times. ```catch_default``` and ```then```
must be zero or one time.

The only required block is ```try```, any other block can be bypassed.

Caveats
=======

```Try::Tiny::SmartCatch``` bases on ```Try::Tiny``` code, so all caveats
described in [```Try::Tiny``` Caveats section](http://metacpan.org/module/Try::Tiny#CAVEATS)
works here too. Please, read [manual from ```Try::Tiny``` module](http://metacpan.org/module/Try::Tiny).

Acknowledgements
================

* Yuval Kogman for his [Try::Tiny](https://metacpan.org/module/Try::Tiny) module
* mst - Matt S Trout (cpan:MSTROUT) <mst@shadowcat.co.uk> - for good package name and few great features

