use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Hessian',
    license             => 'perl',
    dist_author         => 'William Travis Holton <holton@ideegeo.com>',
    dist_version_from   => 'lib/Hessian.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Hessian-*' ],
);

$builder->create_build_script();
