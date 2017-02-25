use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => "ABCMeta",
    VERSION_FROM => 'lib/ABCMeta.pm',
    PREREQ_PM => { 
        'Devel::Symdump' => '2.17', 
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    AUTHOR => 'Ryan Dietrich <ryan.dietrich[at]gmail.com>',
    ABSTRACT => 'Provides an abstract base class facility for Perl'
);
