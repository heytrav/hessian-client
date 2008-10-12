use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hessian',
    AUTHOR              => 'William Travis Holton <holton@ideegeo.com>',
    VERSION_FROM        => 'lib/Hessian.pm',
    ABSTRACT_FROM       => 'lib/Hessian.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hessian-*' },
);
