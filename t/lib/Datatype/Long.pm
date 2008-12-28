package  Datatype::Long;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype';

use Test::More;
use Hessian::Translator::Numeric qw/:to_hessian :from_hessian :input_handle/;

sub t010_single_octet : Test(3) {    #{{{
    my $hessian_single_octet_long = write_long(0);

    like( $hessian_single_octet_long, qr/ L \x{e0}/x,
        'Translate 0 into single octet' );
    $hessian_single_octet_long = write_long(15);

    like( $hessian_single_octet_long, qr/ L \x{ef}/x,
        'Translate 15 into single octet' );
    my $hessian_single_octet_zero = "L\x{e0}";
    my $value                     = read_long($hessian_single_octet_zero);
    is( $value, 0, 'Translated single octet 0' );
}    #}}}

sub t020_double_octet : Test(3) {    #{{{

    my $hessian_double_octet_long = write_long(-256);
    like(
        $hessian_double_octet_long,
        qr/  L \x{f7} \x{00}/x,
        'Translate -256 into double octet'
    );

    $hessian_double_octet_long = write_long(2047);
    like(
        $hessian_double_octet_long,
        qr/  L \x{ff} \x{ff}/x,
        'Translate 2047 into double octet'
    );
    my $hessian_double_octet_zero = "L\x{f8}\x{00}";
    my $value                     = read_long($hessian_double_octet_zero);
    is( $value, 0, 'Translated double octet 0' );
}    #}}}

sub t030_long : Test(3) {    #{{{

    my $value = read_long("L\x{3c}\x{00}\x{00}");
    is( $value, 0, 'Translated triple octet 0' );

    $value = read_long("L\x{00}\x{00}\x{00}\x{01}\x{2c}");
    is( $value, 300, 'Translated length > 4 into   300' );

    my $big_positive_long = Math::BigInt->new('1_999_999_999_999_999_999');
    my $hessian_big_long  = write_long($big_positive_long);
    my $retranslated_long = read_long($hessian_big_long);

    is( $big_positive_long, $retranslated_long,
        'Correctly translated an arbitrary long value' );
}    #}}}

sub t040_read_long_input_handle : Test(1) {    #{{{
    my $self = shift;
    my $ih   = $self->get_string_file_input_handle("\xf0\x00");
    my $first_bit;
    read $ih, $first_bit, 1;
    my $long = read_long_handle_chunk( $first_bit, $ih );
    is( $long, -2048, "Correct long value from file handle." );
}    #}}}

sub t041_read_long_input_handle : Test(1) {    #{{{
    my $self = shift;
    my $ih =
      $self->get_string_file_input_handle("L\x00\x00\x00\x00\x00\x00\x01\x2c");
    my $first_bit;
    read $ih, $first_bit, 1;
    my $long = read_long_handle_chunk( $first_bit, $ih );
    is( $long, 300, "Correct 8 byte value from long handle." );
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::Long - Test hessian conversion of long numbers

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


