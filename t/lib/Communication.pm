package  Communication;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';
use Test::More;
use Hessian::Input;

sub string_handle : Test(setup) {    #{{{
    my $self = shift;

}    #}}}

sub t010_initialize_input : Test(1) {    #{{{
    my $self         = shift;
    my $input_reader = Hessian::Input->new();
    isa_ok( $input_reader, 'Hessian::Input', 'Successful object created' );
    my $object_type = ref $input_reader;
    $self->SKIP_ALL('Can not instantiate a Hessian::Input object')
      unless $object_type and $object_type eq 'Hessian::Input';
}    #}}}

sub  test020_read_simple { #{{{
    my $self = shift;
} #}}}


"one, but we're not the same";

__END__


=head1 NAME

Communication - tests for Hessian communication protocol

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


