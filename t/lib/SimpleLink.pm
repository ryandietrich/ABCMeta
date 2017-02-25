package SimpleLink;

our $state = [];

use strict;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Chain::Link;
use base 'Chain::Link';
use Chain::Enumerations::LinkResult;

sub new {
    my SimpleLink $self = shift;
    my $name = shift || int(rand(99999));
    unless ( ref($self) ) {
        $self = fields::new($self);
        $self->SUPER::new($name);
    }
    return $self;
}

sub does_dependency_exist {
    my SimpleLink $self = shift;
    return Chain::Enumerations::LinkResult->new("CONTINUE");
}

sub callback {
    my SimpleLink $self = shift;
    push(@{$SimpleLink::state}, "SimpleLink-$self->{'name'}");
}

sub cleanup { }

1;
