package  Datatype::Integer;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype';
use Test::More;

use Hessian::Translator::Numeric qw/:to_hessian :from_hessian :input_handle/;

sub t010_write_single_octet : Test(3) {    #{{{
    my $self = shift;

    my $hessian_integer = write_integer(0);
    like(
        $hessian_integer,
        qr/  \x{90} /x,
        'Translation of 0 in single octet'
    );

    $hessian_integer = write_integer(-1);
    like(
        $hessian_integer,
        qr/   \x{8f}/x,
        'Translation of -1 in single octet'
    );

    $hessian_integer = write_integer(17);
    like(
        $hessian_integer,
        qr/   \x{a1} /x,
        'Translation of 17 in single octet'
    );
}    #}}}

sub t020_write_double_octet : Test(2) {    #{{{
    my $self = shift;

    my $hessian_integer = write_integer(-256);
    like(
        $hessian_integer,
        qr/  \x{c7} \x{00} /x,
        'Translation of -256 in double octet'
    );

    $hessian_integer = write_integer(2047);
    like(
        $hessian_integer,
        qr/   \x{cf} \x{ff}/x,
        'Translation of 2047 in double octet'
    );
}    #}}}

sub t030_write_triple_octet : Test(2) {    #{{{
    my $self = shift;

    my $hessian_integer = write_integer(-262144);
    like(
        $hessian_integer,
        qr/   \x{d0} \x{00} \x{00} /x,
        'Translation of -262144 in triple octet'
    );

    $hessian_integer = write_integer(262143);
    like(
        $hessian_integer,
        qr/   \x{d7} \x{ff} \x{ff} /x,
        'Translation of 262143 in triple octet'
    );
}    #}}}

sub t040_read_single_octet : Test(3) {    #{{{

    my $hessian_single_octet_zero = "\x{90}";    # should be 0
    my $value = read_integer($hessian_single_octet_zero);
    is( $value, 0, 'Read single octet 0' );
    my $hessian_single_octet_data = "\x{bf}";    # should be 0
    $value = read_integer($hessian_single_octet_data);
    is( $value, 47, 'Read single octet 47' );

    $hessian_single_octet_data = "\x{80}";       # should be 0
    $value = read_integer($hessian_single_octet_data);
    is( $value, -16, 'Read single octet -16' );
}    #}}}

sub t050_read_double_octet : Test(2) {    #{{{

    my $hessian_double_octet_zero = "\x{c8}\x{00}";    # should also be 0
    my $value = read_integer($hessian_double_octet_zero);
    is( $value, 0, 'Read double octet 0' );
    my $hessian_double_octet_data = "\x{c7}\x{00}";    # should also be 0
    $value = read_integer($hessian_double_octet_data);
    is( $value, -256, 'Read double octet -256' );
}    #}}}

sub t060_read_triple_octet : Test(3) {    #{{{
    my $hessian_triple_octet_zero = "\x{d4}\x{00}\x{00}";    # should also be 0
    my $value = read_integer($hessian_triple_octet_zero);
    is( $value, 0, 'Read double octet 0' );
    my $hessian_triple_octet_data = "\x{d7}\x{ff}\x{ff}";    # should also be 0
    $value = read_integer($hessian_triple_octet_data);
    is( $value, 262143, 'Read double octet 262143 ' );

    $hessian_triple_octet_data = "\x{d0}\x{00}\x{00}";       # should also be 0
    $value = read_integer($hessian_triple_octet_data);
    is( $value, -262144, 'Read double octet -262144 ' );
}    #}}}

sub t070_read_input_handle : Test(1) {    #{{{
    my $self           = shift;
    my $hessian_string = "I\x00\x00\x01\x2c";
    my $first_bit;
    my $ih = $self->get_string_file_input_handle($hessian_string);
    read $ih, $first_bit, 1;
    my $number = read_integer_handle_chunk( $first_bit, $ih );
    is( $number, 300, "Correct value for hessian integer." );

}    #}}}

sub t071_read_input_handle_simple_integer : Test(1) {    #{{{
    my $self           = shift;
    my $hessian_string = "\x90";
    my $ih             = $self->get_string_file_input_handle($hessian_string);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $number = read_integer_handle_chunk( $first_bit, $ih );
    is( $number, 0, "Correct value for hessian integer." );

}    #}}}

sub  t072_read_input_handle_simple_integer : Test(1) { #{{{
    my $self = shift;
    my $hessian_double_octet_zero = "\x{c8}\x{00}";    # should also be 0
    my $ih = $self->get_string_file_input_handle($hessian_double_octet_zero);
    my $first_bit;
    read $ih, $first_bit,1;
    my $number = read_integer_handle_chunk( $first_bit, $ih );
    is( $number, 0, "Correct value for hessian integer." );
} #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::Integer - test for integer hessian conversion

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


