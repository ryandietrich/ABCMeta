package SubAbstractAndFinalnoAbstract;

use strict;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use base 'AbstractAndFinalBase';

sub moo { } # good, implements abstract

sub blah { } # bad, do not re-implement final method!

1;
