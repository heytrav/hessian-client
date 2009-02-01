package  Datatype::Float;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype';
use Test::More;

use Hessian::Translator::Numeric qw/:from_hessian :to_hessian :input_handle/;

sub t010_simple_values : Test(4) {    #{{{
    my $hessian_zero = "\x{5b}";
    my $hessian_one  = "\x{5c}";

    my $value = read_double($hessian_zero);
    is( $value, 0.0, "Read 0.0 from hessian" );
    $value = read_double($hessian_one);
    is( $value, 1.0, "Read 1.0 from Hessian" );

    my $hessian_neg_128 = "\x{5d}\x{80}";
    $value = read_double($hessian_neg_128);
    is( $value, -128.0, "Read -128.0" );

    my $hessian_string = write_double($value);
    my @chars = unpack 'C*', $hessian_string;
    cmp_ok( $hessian_string, 'eq', $hessian_neg_128,
        "Wrote -128.0 back to the correct hessian code." );

}    #}}}

sub t020_double_octet : Test(2) {    #{{{
    my $hessian_double_octet_neg = "\x{5e}\x{80}\x{00}";
    my $value                    = read_double($hessian_double_octet_neg);
    is( $value, -32768.0, "Read -32768.0" );

    my $hessian_string = write_double($value);
    cmp_ok( $hessian_string, 'eq', $hessian_double_octet_neg,
        "Wrote -32768.0 back to the correct hessian code." );

}    #}}}

sub t030_double : Test(2) {    #{{{
    my $hessian_real_double = "D\x40\x28\x80\x00\x00\x00\x00\x00";
    my $value               = read_double($hessian_real_double);
    is( $value, 12.25, "Read 12.25 in hessian" );

    my $hessian_string = write_double($value);
    cmp_ok( $hessian_string, 'eq', $hessian_real_double,
        "Wrote -12.25 back to the correct hessian code." );

}    #}}}

sub t040_read_float_input_handle : Test(1) {    #{{{
    my $self = shift;
    my $ih   = $self->get_string_file_input_handle(
        "D\x40\x28\x80\x00\x00\x00\x00\x00 " );
    my $first_bit;
    read $ih, $first_bit, 1;
    my $double = read_double_handle_chunk( $first_bit, $ih );
    is( $double, 12.25, "Read 12.25 from string handle." );

}    #}}}

sub  t041_read_float_double_octet : Test(1){ #{{{
    my $self = shift;
    my $ih = $self->get_string_file_input_handle("\x5e\x80\x00" );
    my $first_bit;
    read $ih, $first_bit, 1;
    my $double = read_double_handle_chunk($first_bit, $ih);
    is( $double, -32768.0, "Read -32768.0 from file handle.");
} #}}}


"one, but we're not the same";

__END__


=head1 NAME

Datatype::Float - Test conversion of floating point numbers to and from
hessian

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


