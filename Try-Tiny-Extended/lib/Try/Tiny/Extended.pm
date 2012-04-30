package Try::Tiny::Extended;

use 5.006;
use strict;
use warnings;

use Scalar::Util qw/ blessed /;

use vars qw(@EXPORT @EXPORT_OK $VERSION @ISA);

BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
}

@EXPORT = @EXPORT_OK = qw(try catch catch_all finally);

$Carp::Internal{+__PACKAGE__}++;

=head1 NAME

Try::Tiny::Extended - Try::Tiny with some additional features

=head1 VERSION

Version 0.1

=cut

$VERSION = '0.1';

=head1 SYNOPSIS

    use Try::Tiny::Extended;

    # call some code and just silence errors:
    try sub {
        # some code which my die
    };

    # call some code with expanded error handling
    try sub {
        # some code which throw exceptions
    },
    catch 'Exception1' => sub {
        # handle Exception1 exception
    },
    catch ['Exception2', 'Exception3'] => sub {
        # handle Exception2 or Exception3 exception
    },
    catch_all sub {
        # handle all other exceptions
    },
    finally sub {
        # and finally run some other code
    };

=head1 DESCRIPTION

C<Try::Tiny::Extended> is a simple way to handle exceptions. It's mostly a copy
of C<Try::Tiny> module by Yuval Kogman, but with some additional features I need.

Main goal for this changes is to add ability to catch B<only desired> exceptions.
Additionally, it uses B<no more anonymous subroutines> - there are public sub's definitions.
This gave you less chances to forgot that C<return> statement exits just from exception
handler, not surrounding function call.

If you want to read about other assumptions, read about our predecessor: L<Try::Tiny>.

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

    # we need to save this here, the eval block will be in scalar context due
    # to $failed
    my $wantarray = wantarray;

    my ( @catch, $catch_all, @finally );

    # find labeled blocks in the argument list.
    # catch and finally tag the blocks by blessing a scalar reference to them.
    foreach my $code_ref (@code_refs) {
        next if (!$code_ref);

        my $ref = ref ($code_ref);

        if ($ref eq 'Try::Tiny::Extended::Catch') {
            push (@catch, map { [ $_, $$code_ref{code}, ] } (@{$code_ref->get_types}));
        }
        elsif ($ref eq 'Try::Tiny::Extended::Catch::All') {
            $catch_all //= $$code_ref{code};
        }
        elsif ($ref eq 'Try::Tiny::Extended::Finally') {
            push (@finally, ${$code_ref});
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

            # evaluate the try block in the correct context
            if ( $wantarray ) {
                @ret = $try->();
            }
            elsif ( defined $wantarray ) {
                $ret[0] = $try->();
            }
            else {
                $try->();
            };

            return 1; # properly set $fail to false
        };

        # copy $@ to $error; when we leave this scope, local $@ will revert $@
        # back to its previous value
        $error = $@;
    }

    # set up a scope guard to invoke the finally block at the end
    my @guards =
        map { Try::Tiny::Extended::ScopeGuard->_new ($_, $failed ? $error : ()) }
        @finally;

    # at this point $failed contains a true value if the eval died, even if some
    # destructor overwrote $@ as the eval was unwinding.
    if ($failed) {
        # if we got an error, invoke the catch block.
        if (scalar (@catch) || $catch_all) {
            my ($catch_data, $catched, );

            # This works like given($error), but is backwards compatible and
            # sets $_ in the dynamic scope for the body of C<$catch>
            for ($error) {
                foreach $catch_data (@catch) {
                    if (
                        (blessed ($error) && $error->isa ($$catch_data[0])) ||
                        (!blessed ($error) && $error =~ /$$catch_data[0]/)
                    ) {
                        return &{$$catch_data[1]} ($error);
                    }
                }

                if ($catch_all) {
                    return &$catch_all ($error);
                }

                die ($error);
            }

            # in case when() was used without an explicit return, the C<for>
            # loop will be aborted and there's no useful return value
        }

        return;
    }
    else {
        # no failure, $@ is back to what it was, everything is fine
        return $wantarray ? @ret : $ret[0];
    }
}

=head2 catch ($$;@)

Intended to be used in the second argument position of C<try>.

Works similarly to L<Try::Tiny> C<catch> subroutine, but have a little different syntax:

    try sub {
        # some code
    },
    catch 'Exception1' => sub {
        # catch only Exception1 exception
    },
    catch ['Exception1', 'Exception2'] => sub {
        # catch Exception2 or Exception3 exceptions
    };

If raised exception is a blessed reference (or object), C<Exception1> means that exception
class has to be or inherits from C<Exception1> class. In other case, it search for given
string in exception message (using regular expressions). For example:

    try sub {
        die ('some exception message');
    },
    catch 'exception' => sub {
        say 'exception caught!';
    };

Other case:

    try sub {
        die ('some exception3 message');
    },
    catch 'exception\d' => sub {
        say 'exception caught!';
    };

Or:

    try sub {
        # ValueError extends RuntimeError
        die (ValueError->new ('Some error message'));
    },
    catch 'RuntimeError' => sub {
        say 'RuntimeError exception caught!';
    };

=cut

sub catch ($$;@) {
    my ($types, $block, ) = (shift (@_), shift (@_), );

    my $catch = Try::Tiny::Extended::Catch->new ($block, $types);
    return $catch, @_;
}

=head2 catch_all ($;@)

Works exactly like L<Try::Tiny> C<catch> function (OK, there is difference:
need to specify evident sub block instead of anonymous block):

    try sub {
        # some code
    },
    catch_all sub {
        say 'caught every exception';
    };

=cut

sub catch_all ($;@) {
    my ($block, ) = shift (@_);

    my $catch = Try::Tiny::Extended::Catch::All->new ($block);
    return $catch, @_;
}

=head2 finally ($;@)

Works exactly like L<Try::Tiny> C<finally> function (OK, again, evident sub
instead of anonymous):

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
        bless (\$block, 'Try::Tiny::Extended::Finally'),
        @rest,
    );
}

package # hide from PAUSE
    Try::Tiny::Extended::ScopeGuard;
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

package Try::Tiny::Extended::Catch::All;
{
    sub new {
        my $self = {};
        $self = bless ($self, $_[0]);
        $$self{code} = $_[1];
        return $self;
    }
}

package Try::Tiny::Extended::Catch;
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
        $$self{types} = ref ($types) ? $types : [$types, ];
    }

    sub get_types {
        my ($self, ) = @_;
        return wantarray ? @{$$self{types} // []} : $$self{types};
    }
}

=head1 SEE ALSO

=over 4

=item L<Try::Tiny>

Minimal try/catch with proper localization of $@, base of L<Try::Catch::Extended>

=item L<TryCatch>

First class try catch semantics for Perl, without source filters.

=back

=head1 AUTHOR

Marcin Sztolcman, C<< <marcin at urzenia.net> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/mysz/try-tiny-extended/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Try::Tiny::Extended

You can also look for information at:

=over 4

=item * Try::Tiny::Extended home & source code

L<https://github.com/mysz/try-tiny-extended>

=item * Issue tracker (report bugs here)

L<https://github.com/mysz/try-tiny-extended/issues>

=item * Search CPAN

L<http://search.cpan.org/dist/Try-Tiny-Extended/>

=back

=head1 ACKNOWLEDGEMENTS

Yuval Kogman for his L<Try::Tiny> module :)

=head1 LICENSE AND COPYRIGHT

	Copyright (c) 2012 Marcin Sztolcman. All rights reserved.

    Base code is borrowed from Yuval Kogman L<Try::Tiny> module,
    released under MIT License.

	This program is free software; you can redistribute
	it and/or modify it under the terms of the MIT license.

=cut

1;
