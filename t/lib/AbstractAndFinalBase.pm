package AbstractAndFinalBase;

use strict;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ABCMeta { "abstract" => [ "moo" ], "final" => [ qw(blah) ] };

sub blah {
    print "do the thing\n";
}

1;
