package FCBase;

# this is a final class

use strict;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ABCMeta { "class" => 1 };

sub blah {
    print "do the thing\n";
}

1;
