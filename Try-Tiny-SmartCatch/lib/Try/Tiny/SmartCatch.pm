package Try::Tiny::SmartCatch;

use 5.006;
use strict;
use warnings;

use Scalar::Util qw/ blessed /;

use vars qw(@EXPORT @EXPORT_OK $VERSION @ISA);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
}

@EXPORT = @EXPORT_OK = qw(try catch_when catch_default then finally);

$Carp::Internal{+__PACKAGE__}++;

=head1 NAME

Try::Tiny::SmartCatch - lightweight Perl module for powerful exceptions handling

=head1 VERSION

Version 0.3

=cut

$VERSION = '0.3';

=head1 SYNOPSIS

    use Try::Tiny::SmartCatch;

    # call some code and just silence errors:
    try sub {
        # some code which my die
    };

    # call some code with expanded error handling (throw exceptions as object)
    try sub {
        die (Exception1->new ('some error'));
    },
    catch_when 'Exception1' => sub {
        # handle Exception1 exception
    },
    catch_when ['Exception2', 'Exception3'] => sub {
        # handle Exception2 or Exception3 exception
    },
    catch_default sub {
        # handle all other exceptions
    },
    finally sub {
        # and finally run some other code
    };

    # call some code with expanded error handling (throw exceptions as strings)
    try sub {
        die ('some error1');
    },
    catch_when 'error1' => sub {
        # search for 'error1' in message
    },
    catch_when qr/error\d/ => sub {
        # search exceptions matching message to regexp
    },
    catch_when ['error2', qr/error\d/'] => sub {
        # search for 'error2' or match 'error\d in message
    },
    catch_default sub {
        # handle all other exceptions
    },
    finally sub {
        # and finally run some other code
    };

    # try some code, and execute the other if it pass
    try sub {
        say 'some code';
        return 'Hello, world!';
    },
    catch_default sub {
        say 'some exception caught: ', $_;
    },
    then sub {
        say 'all passed, no exceptions found. Message from try block: ' . $_[0];
    };

=head1 DESCRIPTION

C<Try::Tiny::SmartCatch> is a simple way to handle exceptions. It's mostly a copy
of C<Try::Tiny> module by Yuval Kogman, but with some additional features I need.

Main goal for this changes is to add ability to catch B<only desired> exceptions.
Additionally, it uses B<no more anonymous subroutines> - there are public sub's definitions.
This gave you less chances to forgot that C<return> statement exits just from exception
handler, not surrounding function call.

If you want to read about other assumptions, read about our predecessor: L<Try::Tiny>.

More documentation for C<Try::Tiny::SmartCatch> is at package home: L<http://github.com/mysz/try-tiny-smartcatch>

=head1 EXPORT

All functions are exported by default using L<Exporter>.

=head1 SUBROUTINES/METHODS

=head2 try ($;@)

Works like L<Try::Tiny> C<try> subroutine, here is nothing to add :)

The only difference is that here must be given evident sub reference, not anonymous block:

    try sub {
        # some code
    };

=cut

sub try ($;@) {
    my ( $try, @code_refs ) = @_;

    my ( @catch_when, $catch_default, $then, @finally );

    # find labeled blocks in the argument list.
    # catch and finally tag the blocks by blessing a scalar reference to them.
    foreach my $code_ref (@code_refs) {
        next if (!$code_ref);

        my $ref = ref ($code_ref);

        if ($ref eq 'Try::Tiny::SmartCatch::Catch::When') {
            push (@catch_when, map { [ $_, $$code_ref{code}, ] } (@{$code_ref->get_types}));
        }
        elsif ($ref eq 'Try::Tiny::SmartCatch::Catch::Default') {
            $catch_default = $$code_ref{code}
                if (!defined ($catch_default));
        }
        elsif ($ref eq 'Try::Tiny::SmartCatch::Finally') {
            push (@finally, ${$code_ref});
        }
        elsif ($ref eq 'Try::Tiny::SmartCatch::Then') {
            $then = ${$code_ref}
                if (!defined ($then));
        }
        else {
            require Carp;
            Carp::confess ("Unknown code ref type given '${ref}'. Check your usage & try again");
        }
    }

    # save the value of $@ so we can set $@ back to it in the beginning of the eval
    my $prev_error = $@;

    my ( @ret, $error, $failed );

    # FIXME consider using local $SIG{__DIE__} to accumulate all errors. It's
    # not perfect, but we could provide a list of additional errors for
    # $catch->();

    {
        # localize $@ to prevent clobbering of previous value by a successful
        # eval.
        local $@;

        # failed will be true if the eval dies, because 1 will not be returned
        # from the eval body
        $failed = not eval {
            $@ = $prev_error;

            @ret = $try->();

            return 1; # properly set $fail to false
        };

        # copy $@ to $error; when we leave this scope, local $@ will revert $@
        # back to its previous value
        $error = $@;
    }

    # set up a scope guard to invoke the finally block at the end
    my @guards =
        map { Try::Tiny::SmartCatch::ScopeGuard->_new ($_, $failed ? $error : ()) }
        @finally;

    # at this point $failed contains a true value if the eval died, even if some
    # destructor overwrote $@ as the eval was unwinding.
    if ($failed) {
        # if we got an error, invoke the catch block.
        if (scalar (@catch_when) || $catch_default) {
            my ($catch_data, );

            # This works like given($error), but is backwards compatible and
            # sets $_ in the dynamic scope for the body of C<$catch>
            for ($error) {
                foreach $catch_data (@catch_when) {
                    if (
                        (blessed ($error) && $error->isa ($$catch_data[0])) ||
                        (!blessed ($error) && (
                            (ref ($$catch_data[0]) eq 'Regexp' && $error =~ /$$catch_data[0]/) ||
                            (!ref ($$catch_data[0]) && index ($error, $$catch_data[0]) > -1)
                        ))
                    ) {
                        return &{$$catch_data[1]} ($error);
                    }
                }

                if ($catch_default) {
                    return &$catch_default ($error);
                }

                die ($error);
            }

            # in case when() was used without an explicit return, the C<for>
            # loop will be aborted and there's no useful return value
        }

        return;
    }
    else {
        @ret = $then->(@ret)
            if ($then);

        # no failure, $@ is back to what it was, everything is fine
        return wantarray ? @ret : $ret[0];
    }
}

=head2 catch_when ($$;@)

Intended to be used in the second argument position of C<try>.

Works similarly to L<Try::Tiny> C<catch> subroutine, but have a little different syntax:

    try sub {
        # some code
    },
    catch_when 'Exception1' => sub {
        # catch only Exception1 exception
    },
    catch_when ['Exception1', 'Exception2'] => sub {
        # catch Exception2 or Exception3 exceptions
    };

If raised exception is a blessed reference (or object), C<Exception1> means that exception
class has to be or inherits from C<Exception1> class. In other case, it search for given
string in exception message (using C<index> function or regular expressions - depending on
type of given operator). For example:

    try sub {
        die ('some exception message');
    },
    catch_when 'exception' => sub {
        say 'exception caught!';
    };

Other case:

    try sub {
        die ('some exception3 message');
    },
    catch_when qr/exception\d/ => sub {
        say 'exception caught!';
    };

Or:

    try sub {
        # ValueError extends RuntimeError
        die (ValueError->new ('Some error message'));
    },
    catch_when 'RuntimeError' => sub {
        say 'RuntimeError exception caught!';
    };

=cut

sub catch_when ($$;@) {
    my ($types, $block, ) = (shift (@_), shift (@_), );

    my $catch = Try::Tiny::SmartCatch::Catch::When->new ($block, $types);
    return $catch, @_;
}

=head2 catch_default ($;@)

Works exactly like L<Try::Tiny> C<catch> function (OK, there is difference:
need to specify evident sub block instead of anonymous block):

    try sub {
        # some code
    },
    catch_default sub {
        say 'caught every exception';
    };

=cut

sub catch_default ($;@) {
    my ($block, ) = shift (@_);

    my $catch = Try::Tiny::SmartCatch::Catch::Default->new ($block);
    return $catch, @_;
}

=head2 then ($;@)

C<then> block is executed after C<try> clause, if none of C<catch_when> or
C<catch_default> blocks was executed (it means, if no exception occured).
It;s executed before C<finally> blocks.

    try sub {
        # some code
    },
    catch_when 'MyException' => sub {
        say 'caught MyException exception';
    },
    then sub {
        say 'No exception was raised';
    },
    finally sub {
        say 'executed always';
    };

=cut

sub then ($;@) {
    my ($block, @rest, ) = @_;

    return (
        bless (\$block, 'Try::Tiny::SmartCatch::Then'),
        @rest
    );
}

=head2 finally ($;@)

Works exactly like L<Try::Tiny> C<finally> function (OK, again, explicit sub
instead of implicit):

    try sub {
        # some code
    },
    finally sub {
        say 'executed always';
    };

=cut

sub finally ($;@) {
    my ($block, @rest, ) = @_;

    return (
        bless (\$block, 'Try::Tiny::SmartCatch::Finally'),
        @rest,
    );
}

package # hide from PAUSE
    Try::Tiny::SmartCatch::ScopeGuard;
{

    sub _new {
        shift;
        bless [ @_ ];
    }

    sub DESTROY {
        my @guts = @{ shift () };
        my $code = shift (@guts);
        $code->(@guts);
    }
}

package Try::Tiny::SmartCatch::Catch::Default;
{
    sub new {
        my $self = {};
        $self = bless ($self, $_[0]);
        $$self{code} = $_[1];
        return $self;
    }
}

package Try::Tiny::SmartCatch::Catch::When;
{
    sub new {
        my $self = {};
        $self = bless ($self, $_[0]);
        $$self{code} = $_[1];
        $self->set_types ($_[2]) if (defined ($_[2]));
        return $self;
    }

    sub set_types {
        my ($self, $types, ) = @_;
        $$self{types} = ref ($types) eq 'ARRAY' ? $types : [$types, ];
    }

    sub get_types {
        my ($self, ) = @_;
        return wantarray ? @{defined ($$self{types}) ? $$self{types} : []} : $$self{types};
    }
}

=head1 SEE ALSO

=over 4

=item L<https://github.com/mysz/try-tiny-smartcatch>

Try::Tiny::SmartCatch home.

=item L<Try::Tiny>

Minimal try/catch with proper localization of $@, base of L<Try::Tiny::SmartCatch>

=item L<TryCatch>

First class try catch semantics for Perl, without source filters.

=back

=head1 AUTHOR

Marcin Sztolcman, C<< <marcin at urzenia.net> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://github.com/mysz/try-tiny-smartcatch/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Try::Tiny::SmartCatch

You can also look for information at:

=over 4

=item * Try::Tiny::SmartCatch home & source code

L<http://github.com/mysz/try-tiny-smartcatch>

=item * Issue tracker (report bugs here)

L<http://github.com/mysz/try-tiny-smartcatch/issues>

=item * Search CPAN

L<http://search.cpan.org/dist/Try-Tiny-SmartCatch/>

=back

=head1 ACKNOWLEDGEMENTS

Yuval Kogman for his L<Try::Tiny> module
mst - Matt S Trout (cpan:MSTROUT) <mst@shadowcat.co.uk> - for good package name and few great features

=head1 LICENSE AND COPYRIGHT

    Copyright (c) 2012 Marcin Sztolcman. All rights reserved.

    Base code is borrowed from Yuval Kogman L<Try::Tiny> module,
    released under MIT License.

    This program is free software; you can redistribute
    it and/or modify it under the terms of the MIT license.

=cut

1;
