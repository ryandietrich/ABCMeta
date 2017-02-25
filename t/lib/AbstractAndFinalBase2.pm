package AbstractAndFinalBase2;

use strict;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ABCMeta { "abstract" => [ "moo2" ], "final" => [ qw(blah2) ] };

sub blah2 {
    print "do the thing\n";
}

1;
