package InheritsFinalBase;

use strict;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use base 'FinalBase';

sub blah { print "ruh roh\n"; }

1;
