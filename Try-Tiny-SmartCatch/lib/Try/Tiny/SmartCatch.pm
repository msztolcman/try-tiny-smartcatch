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

++$Carp::Internal{+__PACKAGE__};

$VERSION = '0.3';

sub try($;@) {
    my ($try, @code_refs) = @_;

    my ($catch_default, @catch_when, $code_ref, @finally, $ref_type, $then, $wantarray);

    $wantarray = wantarray;

    foreach $code_ref (@code_refs) {
        next if (!$code_ref);

        $ref_type = ref($code_ref);

        ## zero or more 'catch_when' blocks
        if ($ref_type eq 'Try::Tiny::SmartCatch::Catch::When') {
            ## we need to save same handler for many different exception types
            push(@catch_when, map { [$_, $$code_ref{code}] } ($code_ref->get_types()));
        }
        ## zero or one 'catch_default' blocks
        elsif ($ref_type eq 'Try::Tiny::SmartCatch::Catch::Default') {
            $catch_default = $$code_ref{code}
                if (!defined($catch_default));
        }
        ## zero or more 'finally' blocks
        elsif ($ref_type eq 'Try::Tiny::SmartCatch::Finally') {
            push(@finally, $$code_ref);
        }
        ## zero or one 'then' blocks
        elsif ($ref_type eq 'Try::Tiny::SmartCatch::Then') {
            $then = $$code_ref
                if (!defined($then));
        }
        ## unknown block type
        else {
            require Carp;
            Carp::confess("Unknown code ref type given '$ref_type'. Check your usage & try again");
        }
    }

    my ($error, $failed, $prev_error, @ret);

    # save the value of $@ so we can set $@ back to it in the beginning of the eval
    $prev_error = $@;

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

            ## call try block in list context if try subroutine is called in list context, or we have 'then' block
            ## result of 'try' block is passed as arguments to then block, so we need do that in that way
            if ($wantarray || $then) {
                @ret = &$try();
            }
            elsif (defined($wantarray)) {
                $ret[0] = &$try();
            }
            else {
                &$try();
            }

            return 1; # properly set $fail to false
        };

        # copy $@ to $error; when we leave this scope, local $@ will revert $@
        # back to its previous value
        $error = $@;
    }

    # set up a scope guard to invoke the finally block at the end
    my @guards =
        map {
            Try::Tiny::SmartCatch::ScopeGuard->_new($_, $failed ? $error : ())
        } @finally;

    # at this point $failed contains a true value if the eval died, even if some
    # destructor overwrote $@ as the eval was unwinding.
    if ($failed) {
        # if we got an error, invoke the catch block.
        if (scalar(@catch_when) || $catch_default) {
            my ($catch_data);

            # This works like given($error), but is backwards compatible and
            # sets $_ in the dynamic scope for the body of $catch
            for ($error) {
                foreach $catch_data (@catch_when) {
                    if (
                        (blessed($error) && $error->isa($$catch_data[0])) ||
                        (!blessed($error) && (
                            (ref($$catch_data[0]) eq 'Regexp' && $error =~ /$$catch_data[0]/) ||
                            (!ref($$catch_data[0]) && index($error, $$catch_data[0]) > -1)
                        ))
                    ) {
                        return &{$$catch_data[1]}($error);
                    }
                }

                return &$catch_default($error)
                    if ($catch_default);

                die($error);
            }
        }

        return;
    }

    ## no failure, $@ is back to what it was, everything is fine
    else {
        ## do we have then block? if we does, execute it in correct context
        if ($then) {
            if ($wantarray) {
                @ret = &$then(@ret);
            }
            elsif (defined($wantarray)) {
                $ret[0] = &$then(@ret);
            }
            else {
                &$then(@ret);
            }
        }

        return if (!defined($wantarray));
        return $wantarray ? @ret : $ret[0];
    }
}

sub catch_when ($$;@) {
    my ($types, $block) = (shift(@_), shift(@_), );

    my $catch = Try::Tiny::SmartCatch::Catch::When->new($block, $types);

    return ($catch, @_);
}

sub catch_default ($;@) {
    my $block = shift(@_);

    my $catch = Try::Tiny::SmartCatch::Catch::Default->new($block);

    return ($catch, @_);
}

sub then ($;@) {
    my $block = shift(@_);

    my $then = bless(\$block, 'Try::Tiny::SmartCatch::Then');

    return ($then, @_);
}

sub finally ($;@) {
    my $block = shift(@_);

    my $finally = bless(\$block, 'Try::Tiny::SmartCatch::Finally');

    return ($finally, @_);
}

package # hide from PAUSE
    Try::Tiny::SmartCatch::ScopeGuard;
{

    sub _new {
        shift(@_);
        return bless([ @_ ]);
    }

    sub DESTROY {
        my ($guts) = @_;

        my $code = shift(@$guts);
        return &$code(@$guts);
    }
}

package Try::Tiny::SmartCatch::Catch::Default;
{
    sub new {
        my ($class, $code) = @_;

        my $self = { code => $code };
        $self    = bless($self, $class);

        return $self;
    }
}

package Try::Tiny::SmartCatch::Catch::When;
{
    sub new {
        my ($class, $code, $types) = @_;

        my $self = { code => $code };
        $self    = bless($self, $class);
        $self->set_types($types) if (defined($types));

        return $self;
    }

    sub set_types {
        my ($self, $types) = @_;

        $$self{types} = ref($types) eq 'ARRAY' ? $types : [$types];

        return;
    }

    sub get_types {
        my ($self) = @_;

        my $types = defined($$self{types}) ? $$self{types} : [];

        return wantarray ? @$types : $types;
    }
}


1;
