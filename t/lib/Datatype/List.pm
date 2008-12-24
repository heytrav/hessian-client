package Datatype::List;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype';

use Test::More;
use Test::Deep;
use YAML;
use Hessian::Translator::List qw/:input_handle/;

sub t010_read_fixed_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "V\x04[int\x92\x90\x91";
    my $ih           = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );
    cmp_deeply( $datastructure, [ 0, 1 ], "Received expected datastructure." );
}    #}}}

sub t011_read_variable_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x55\x04[int\x90\x91\xd7\xff\xffZ";
    my $ih           = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );
    cmp_deeply(
        $datastructure,
        [ 0, 1, 262143 ],
        "Received expected datastructure."
    );
}    #}}}

sub t012_read_fixed_length_type : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x73\x04[int\x90\x91\xd7\xff\xff";
    my $ih           = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );
    cmp_deeply(
        $datastructure,
        [ 0, 1, 262143 ],
        "Received expected datastructure."
    );
}    #}}}

sub t013_read_fixed_length_untyped : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x57\x90\x91D\x40\x28\x80\x00\x00\x00\x00\x00\xd7"
      . "\xff\xff\x52\x00\x07hello, T\x05worldZ";
    my $ih = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;

    my $datastructure = read_complex_datastructure( $first_bit, $ih );
    cmp_deeply(
        $datastructure,
        [ 0, 1, 12.25, 262143, 'hello, ', 1, 'world' ],
        "Received expected datastructure."
    );
}    #}}}

sub t020_read_typed_map : Test(3) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x4d\x08SomeType\x05color\x0aaquamarine"
      . "\x05model\x06Beetle\x07mileageI\x00\x01\x00\x00Z";
    my $ih = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );

    isa_ok( $datastructure, 'SomeType',
        'Data structure returned by deserializer' );
    is( $datastructure->{model},
        'Beetle', 'Model attribute has correct value.' );
    like( $datastructure->{mileage},
        qr/\d+/, 'Mileage attribute is an integer.' );

}    #}}}

sub  t023_read_untyped_map : Test(1){ #{{{
    my $self = shift;
    my $hessian_data = "\x48\x91\x05hello\x04word\x06BeetleZ";

    my $ih = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );
    cmp_deeply(
        $datastructure,
        {  1 => 'hello', word => 'Beetle'},
        "Correctly interpreted datastructure."
    );
} #}}}


"one, but we're not the same";

__END__


=head1 NAME

Datataype::List - Test various recursive datatypes into their components.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


