# NAME

ABCMeta provide compile time enforcement of methods that must be implemented
by subclasses and more.

# SYNOPSIS

This package will provide Perl the ability to create "abstract" classes.  More importantly, it provides this capability while still providing polymorphic support.  One downside to this approach (allowing you to import an abstract class) is that you ARE able to instantiate one (for now), this tradeoff is acceptable given that the main errors we want to throw are the ones where a developer derives a class from one of our core types, but fails to implement all the required functionality.

So, with that, here are the core responsibilities of this package:

    1. Throw an exception for any class (that does not inherit from ABCMeta) that inherits from a class (or any class it inherts from) that uses ABCMeta.
    2. Handle multiple inheritance as well.
    3. Do not throw an except for any package imported that uses ABCMeta.
    4. Mark certain methods as "final", and throw if any class that attempts to override a final method in a subclass.
    5. Mark certain classes as "final", and throw if any class that attempts to override those classes that are marked in that way.

## Basic Example (abstract method enforcement)

    package Foo;
    use ABCMeta qw(moocow); # moocow is defined as an abstract method

    1;

    package Bar;
    use base 'Foo';

    # The code will fail to compile because "Bar" does not implement the "moocow" method.

## Another Example (final method enforcement)

    package Boo;
    use ABCMeta { "final" => [ 'cow' ] }; # 'foo' is final

    sub cow { }

    package Bop;
    use base 'Boo';

    sub cow { }

    # This code will fail to compile because the 'Bop' class implements the 'cow' method, which was marked as final in the parent class 'Boo'

## Yet another Example (final class)

    package Blah;
    use ABCMeta { "class" => 1 };

    package Wat;
    use base 'Blah';

    # This code will fail to compile because the 'Wat' class inherits from 'Blah', which was marked as a final class

## Add it all together example (final/abstract example)

    package Mop;
    use ABCMeta { "abstract" => [ "zip", "zap" ], "final" => [ "zoop", "zoot" ] };

    sub zoop { }
    sub zoot { }

    package Pop;
    use base 'Mop';

    sub zoop { }
    sub zoot { }

    # This will fail with four errors, the two abstract methods are not implemente, and both final methods are being overriden.

## import

This method will register the package the imports ABCMeta and will pull it's configuration into our package global abstract/final variables.

# Internal Methods

## does\_any\_class\_inherit\_from\_abcmeta

This method is a recursive accumulator that looks for methods that have to be implemented by virtue of being declared by ABCMeta.

## does\_base\_class\_have\_final\_methods

Iterate ONE layer deep for the superclass of our module, and look for any methods marked "final" for that superclass.

## enforce\_abstract\_and\_final\_methods

This method will ask SymDump to basically dump everything, and then request JUST the packages.

We'll iterate over every single package, and figure out if any of those classe are subclassing a class that is using ABCMeta.

## \_enforce\_abstract\_methods

This method will enforce abstract methods will implemented by derived classes.

## \_enforce\_final\_methods

This method will enforce final methods are not overriden by derived classes.

## \_enforce\_final\_classes {

This method will verify any class marked as "final" is not being derived by any other class, or this method will throw an exception.

# AUTHOR:

ABCMeta by Ryan Alan Dietrich <ryan.dietrich@gmail.com>
