package SimplePublish;

use strict;
use Data::Dumper;
use FindBin;
use Chain::Link;
use base 'Chain::Link';
use Chain::Enumerations::LinkResult;
use SimpleLink;

sub new {
    my SimplePublish $self = shift;
    my $name = shift || int(rand(99999));
    unless ( ref($self) ) {
        $self = fields::new($self);
        $self->SUPER::new($name);
    }
    return $self;
}

sub does_dependency_exist {
    my SimplePublish $self = shift;
    return Chain::Enumerations::LinkResult->new("CONTINUE");
}

sub callback {
    my SimplePublish $self = shift;
    push(@{$SimpleLink::state}, "SimplePublish-$self->{'name'}");
}

sub cleanup { }

1;
