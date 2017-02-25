package InheritsDumbo;

use Dumbo;
use base 'Dumbo';

use FindBin;
use lib "$FindBin::Bin/../lib";
use ABCMeta qw(bar);

sub moo {
    print "Cow!\n";
}

1;
