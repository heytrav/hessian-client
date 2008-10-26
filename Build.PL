use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'Module::Build::Custom',
    code  => q{
sub  run_tap_harness { #{{{
  my ($self, $tests) = @_;
  require TAP::Harness::JUnit;

  # TODO allow the test @INC to be set via our API?
  TAP::Harness::JUnit->new({
    lib => [@INC],
    verbosity => $self->{properties}{verbose},
    switches  => [ $self->harness_switches ],
    %{ $self->tap_harness_args },
  })->runtests(@$tests);

  } #}}}
}
);

my $builder = $class->new(
    module_name       => 'Hessian',
    license           => 'perl',
    dist_author       => 'William Travis Holton <holton@ideegeo.com>',
    dist_version_from => 'lib/Hessian.pm',
    tap_harness_args  => { xmlfile => 'output.xml' },
    requires          => {
        'Test::More'         => 0,
        'version'            => 0,
        'Contextual::Return' => 0,

    },
    add_to_cleanup => ['Hessian-*'],
);

$builder->create_build_script();
