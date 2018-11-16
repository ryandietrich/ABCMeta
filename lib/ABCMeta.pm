package ABCMeta;

# XXX TODO : make methods that should be invalid to define in this class

=head1 NAME

ABCMeta provide compile time enforcement of methods that must be implemented
by subclasses and more.

=head1 SYNOPSIS

This package will provide Perl the ability to create "abstract" classes.  More importantly, it provides this capability while still providing polymorphic support.  One downside to this approach (allowing you to import an abstract class) is that you ARE able to instantiate one (for now), this tradeoff is acceptable given that the main errors we want to throw are the ones where a developer derives a class from one of our core types, but fails to implement all the required functionality.

So, with that, here are the core responsibilities of this package:

  1. Throw an exception for any class (that does not inherit from ABCMeta) that inherits from a class (or any class it inherts from) that uses ABCMeta.
  2. Handle multiple inheritance as well.
  3. Do not throw an except for any package imported that uses ABCMeta.
  4. Mark certain methods as "final", and throw if any class that attempts to override a final method in a subclass.
  5. Mark certain classes as "final", and throw if any class that attempts to override those classes that are marked in that way.

=head2 Basic Example (abstract method enforcement)

    package Foo;
    use ABCMeta qw(moocow); # moocow is defined as an abstract method

    1;

    package Bar:
    use base 'Foo';

    # The code will fail to compile because "Bar" does not implement the "moocow" method.

=head2 Another Example (final method enforcement)

    package Boo:
    use ABCMeta { "final" => [ 'cow' ] }; # 'foo' is final

    sub cow { }

    package Bop;
    use base 'Boo';

    sub cow { }

    # This code will fail to compile because the 'Bop' class implements the 'cow' method, which was marked as final in the parent class 'Boo'

=head2 Yet another Example (final class)

    package Blah;
    use ABCMeta { "class" => 1 };

    package Wat;
    use base 'Blah';

    # This code will fail to compile because the 'Wat' class inherits from 'Blah', which was marked as a final class

=head2 Add it all together example (final/abstract example)

    package Mop;
    use ABCMeta { "abstract" => [ "zip", "zap" ], "final" => [ "zoop", "zoot" ] };

    sub zoop { }
    sub zoot { }

    package Pop;
    use base 'Mop';

    sub zoop { }
    sub zoot { }

    # This will fail with four errors, the two abstract methods are not implemente, and both final methods are being overriden.
=cut

use strict;
use mro;
use B;
use Carp qw(croak);
use Devel::Symdump;
use Data::Dumper;

use vars qw( $VERSION $abstract $final $final_class );

BEGIN {
    $VERSION     = '1.0';
    $abstract    = {};
    $final       = {};
    $final_class = {};
}

=head2 import

This method will register the package the imports ABCMeta and will pull it's configuration into our package global abstract/final variables.

=head1 Internal Methods

=cut

sub import {
    my $class = shift;
    my $clr   = (caller)[0];
    if ( ref($_[0]) eq 'HASH' ) {
        $abstract->{$clr} = $_[0]->{'abstract'};
        $final->{$clr} = $_[0]->{'final'};
        $final_class->{$clr} = 1 if ( $_[0]->{'class'} );
    } elsif ( ref($_[0]) eq 'ARRAY' ) {
        $abstract->{$clr} = @{$_[0]};
    } else {
        $abstract->{$clr} = \@_;
    }
}

=head2 does_any_class_inherit_from_abcmeta

This method is a recursive accumulator that looks for methods that have to be implemented by virtue of being declared by ABCMeta.

=cut

sub does_any_class_inherit_from_abcmeta {
    my $superclasses     = shift;
    my $abstract_methods = shift;
    foreach my $sc ( @{$superclasses} ) {
        if ( ref($sc) eq 'ARRAY' ) {
            return &does_any_class_inherit_from_abcmeta($sc, $abstract_methods);
        } else {
            if ( exists($abstract->{$sc}) and ref($abstract->{$sc}) eq 'ARRAY' ) {
                push(@{$abstract_methods}, @{$abstract->{$sc}});
            }
        }
    }
}

=head2 does_base_class_have_final_methods

Iterate ONE layer deep for the superclass of our module, and look for any methods marked "final" for that superclass.

=cut

sub does_base_class_have_final_methods {
    my $module        = shift;
    my $superclasses  = shift;
    my $final_methods = shift;

    foreach my $sc ( @{$superclasses} ) {
        foreach my $ssc ( @{$sc} ) {
            next if ( $ssc eq $module );
            if ( exists($final->{$ssc}) and ref($final->{$ssc}) eq 'ARRAY' ) {
                #print "Module = $module, sc = $ssc\n";
                push(@{$final_methods}, @{$final->{$ssc}});
            }
        }
    }
}

=head2 enforce_abstract_and_final_methods

This method will ask SymDump to basically dump everything, and then request JUST the packages.

We'll iterate over every single package, and figure out if any of those classe are subclassing a class that is using ABCMeta.

=cut

sub enforce_abstract_and_final {
    my $res  = Devel::Symdump->rnew("main");
    my @pkgs = $res->packages();

    foreach my $module ( @pkgs ) {
        my @superclasses = mro::get_linear_isa($module);
        my $abstract_methods = [];
        my $final_methods = [];
        &does_any_class_inherit_from_abcmeta(\@superclasses, $abstract_methods);
        &does_base_class_have_final_methods($module, \@superclasses, $final_methods);

        my @errors;
        &_enforce_abstract_methods($abstract_methods, $module, \@errors);
        &_enforce_final_methods($final_methods, $module, \@errors);
        &_enforce_final_classes($module, \@errors);

        if ( @errors ) {
            croak join("\n", @errors) . "\n";
        }
    }
}

=head2 _enforce_abstract_methods

This method will enforce abstract methods will implemented by derived classes.

=cut
sub _enforce_abstract_methods {
    my ( $abstract_methods, $module, $errors ) = @_;
    if ( scalar(@{$abstract_methods}) and ! exists($abstract->{$module}) ) {
        foreach my $req ( @{$abstract_methods} ) {
            push(@{$errors}, "    $module does not implement $req") unless ( ($module)->can($req) );
        }
    }
}

=head2 _enforce_final_methods

This method will enforce final methods are not overriden by derived classes.

=cut
sub _enforce_final_methods {
    my ( $final_methods, $module, $errors ) = @_;
    for my $fm ( @{$final_methods} ) {
        my $path = $module . "::" . $fm;

        no strict;
        my $str = $module . '::';
        next unless ( %$str{$fm} );

        my $subr = \&$path;
        my $cv = B::svref_2object($subr);

        next unless ( $cv->isa('B::CV') && $cv->START->isa('B::COP') );

        next if $cv->GV->isa('B::SPECIAL');

        push(@{$errors}, "$module overrides final method $fm (" . $cv->START->file . ' : ' .  $cv->START->line . ")") if ( $module eq $cv->GV->STASH->NAME );

        #no strict;
        #my $str = $module . '::';
        #die("$module overrides final method $fm") if ( %$str{$fm} );
    }
}

=head2 _enforce_final_classes {

This method will verify any class marked as "final" is not being derived by any other class, or this method will throw an exception.

=cut
sub _enforce_final_classes {
    my $module       = shift;
    my @superclasses = mro::get_linear_isa($module);
    my $errors       = shift;

    foreach my $ssc ( @superclasses ) {
        next unless ( ref($ssc) eq 'ARRAY' );
        foreach my $sc ( @{$ssc} ) {
            next if ( $module eq $sc );
            push(@{$errors}, "Module $module overrides final class $sc!") if ( $final_class->{$sc} );
        }
    }
}

CHECK {
    &enforce_abstract_and_final();
}

=head1 AUTHOR:

ABCMeta by Ryan Alan Dietrich <ryan.dietrich@gmail.com>

=cut

1;
