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

sub  t012_read_fixed_length_type : Test(1){ #{{{
    my $self = shift;
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
} #}}}

sub  t013_read_fixed_length_untyped : Test(1) { #{{{
    my $self = shift;
    my $hessian_data = "\x57\x90\x91\xd7\xff\xff\x52\x00\x07hello, \x05worldZ";
    my $ih           = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;

    my $datastructure = read_complex_datastructure($first_bit, $ih);
    cmp_deeply(
    $datastructure,
        [ 0, 1, 262143,'hello, ', 'world' ],
        "Received expected datastructure."
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


