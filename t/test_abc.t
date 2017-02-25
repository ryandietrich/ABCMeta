use strict;
use Data::Dumper;
use FindBin;
use Test::Exception;
use Test::More tests => 15;

use lib "$FindBin::Bin/lib";

my $dir    = $FindBin::Bin . "/lib";
my $stdout = $FindBin::Bin . "/STDOUT.txt";
my $stderr = $FindBin::Bin . "/STDERR.txt";

sub find_string {
    my ( $file, $string, $debug ) = @_;
    open my $fh, '<', $file;
    while (<$fh>) {
        print "$_\n" if ( $debug );
        return 1 if /\Q$string/;
    }
    return;
}

sub verify_output {
    my ( $name, $value, $debug ) = @_;
    my %map = ( "stdout" => $stdout, "stderr" => $stderr );
    die("Could not find $value in '$name'") unless &find_string($map{$name}, $value, $debug);
}

sub verify_empty_files {
    die("STDERR/STDOUT Files are not empty!") if ( -s $stdout and -s $stderr );
}

my $res;
$res = system("perl -I $dir -MDumbo -e 'exit 0'");
ok($res == 0, "verify dumbo is ok");
&verify_empty_files();

$res = system("perl -I $dir -MInheritsDumbo -e 'exit 0' 1>$stdout 2>$stderr");
ok($res == 0, "verify basic inheritance (of class that uses ABC but also inherits) is ok");
&verify_empty_files();

# Abstract method not implemented should fail!
$res = system("perl -I $dir -MSubInheritsDumbo -e 'exit 0' 1>$stdout 2>$stderr");
ok($res != 0, "SubInheritsDumbo does not implement all the abstract methods, should fail!");
&verify_output("stderr", "SubInheritsDumbo does not implement bar");

# Final method only base should inherit just fine
$res = system("perl -I $dir -MFinalBase -e 'exit 0' 1>$stdout 2>$stderr");
ok($res == 0, "verify FinalBase import on it's own is ok");
&verify_empty_files();

# Verify a class that re-implements a a final method borks
$res = system("perl -I $dir -MInheritsBadFinal -e 'exit 0' 1>$stdout 2>$stderr");
ok($res != 0, "verify InheritsBadFinal import on it's own is ok");
&verify_output("stderr", "overrides final method blah");

# Final method not overriden
$res = system("perl -I $dir -MInheritsGoodFinal -e 'exit 0' 1>$stdout 2>$stderr");
ok($res == 0, "verify InheritsGoodFinal import on it's own is ok");
&verify_empty_files();

# abstract method not implemented
$res = system("perl -I $dir -MSubAbstractAndFinalnoAbstract -e 'exit 0' 1>$stdout 2>$stderr");
ok($res != 0, "verify abstract failed again.. SubAbstractAndFinalnoAbstract");
&verify_output("stderr", "does not implement moo");

# abstract method implemented, but so is the final method
$res = system("perl -I $dir -MSubAbstractAndFinalnoAbstract -e 'exit 0' 1>$stdout 2>$stderr");
ok($res != 0, "verify abstract failed again.. SubAbstractAndFinalnoAbstract");
&verify_output("stderr", "does not implement moo");

# Good multiple inheritance
$res = system("perl -I $dir -MMulti -e 'exit 0' 1>$stdout 2>$stderr");
ok($res == 0, "verify Multi implements both abstract methods from the two base classess");
&verify_empty_files();

# BadMulti tests
$res = system("perl -I $dir -MBadMultiOne -e 'exit 0' 1>$stdout 2>$stderr");
ok($res != 0, "verify half implemented abstracted fails");
&verify_output("stderr", "does not implement boo");
$res = system("perl -I $dir -MBadMultiTwo -e 'exit 0' 1>$stdout 2>$stderr");
ok($res != 0, "verify half implemented abstracted fails");
&verify_output("stderr", "does not implement bar");

# Multiple inheritance, abstract and final methods
$res = system("perl -I $dir -MMulti2 -e 'exit 0' 1>$stdout 2>$stderr");
ok($res == 0, "verify Multi2 implements both abstract methods from the two base classess");
&verify_empty_files();

# Multiple inheritance, abstract and final methods
$res = system("perl -I $dir -MBadMulti2 -e 'exit 0' 1>$stdout 2>$stderr");
ok($res != 0, "verify BadMulti2 fails when final methods are overriden");
&verify_output("stderr", "BadMulti2 does not implement moo");
&verify_output("stderr", "BadMulti2 does not implement moo2");

# verify final class logic
$res = system("perl -I $dir -MFCBase -e 'exit 0' 1>$stdout 2>$stderr");
ok($res == 0, "verify FCBase loads normally");
&verify_empty_files();

$res = system("perl -I $dir -MInheritsFC -e 'exit 0' 1>$stdout 2>$stderr");
ok($res != 0, "verify Final Classes are enforced");
&verify_output("stderr", "overrides final class");

#&verify_output("stderr", "test", 1);

unlink($stdout);
unlink($stderr);
