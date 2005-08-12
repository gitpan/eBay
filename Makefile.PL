use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'eBay',
    AUTHOR              => 'Alan Young <alansyoungiii@gmail.com>',
    VERSION_FROM        => 'lib/eBay.pm',
    ABSTRACT_FROM       => 'lib/eBay.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'eBay-*' },
);
