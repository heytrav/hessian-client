package  Datatype::Integer;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';

use Test::More;

use Hessian::Translator::Numeric qw/:to_hessian :from_hessian/;

sub t010_write_single_octet : Test(3) {    #{{{
    my $self = shift;

    my $hessian_integer = write_integer(0);
    like(
        $hessian_integer,
        qr/ I \x{90} /x,
        'Translation of 0 in single octet'
    );

    $hessian_integer = write_integer(-1);
    like(
        $hessian_integer,
        qr/  I \x{8f}/x,
        'Translation of -1 in single octet'
    );

    $hessian_integer = write_integer(17);
    like(
        $hessian_integer,
        qr/  I \x{a1} /x,
        'Translation of 17 in single octet'
    );
}    #}}}

sub t020_write_double_octet : Test(2) {    #{{{
    my $self = shift;

    my $hessian_integer = write_integer(-256);
    like(
        $hessian_integer,
        qr/ I \x{c7} \x{00} /x,
        'Translation of -256 in double octet'
    );

    $hessian_integer = write_integer(2047);
    like(
        $hessian_integer,
        qr/  I \x{cf} \x{ff}/x,
        'Translation of 2047 in double octet'
    );
}    #}}}

sub t030_write_triple_octet : Test(2) {    #{{{
    my $self = shift;

    my $hessian_integer = write_integer(-262144);
    like(
        $hessian_integer,
        qr/  I \x{d0} \x{00} \x{00} /x,
        'Translation of -262144 in triple octet'
    );

    $hessian_integer = write_integer(262143);
    like(
        $hessian_integer,
        qr/  I \x{d7} \x{ff} \x{ff} /x,
        'Translation of 262143 in triple octet'
    );
}    #}}}

sub t040_read_single_octet : Test(3) {    #{{{

    my $hessian_single_octet_zero = "I\x{90}";    # should be 0
    my $value = read_integer($hessian_single_octet_zero);
    is( $value, 0, 'Read single octet 0' );
    my $hessian_single_octet_data = "I\x{bf}";    # should be 0
    $value = read_integer($hessian_single_octet_data);
    is( $value, 47, 'Read single octet 47' );

    $hessian_single_octet_data = "I\x{80}";       # should be 0
    $value = read_integer($hessian_single_octet_data);
    is( $value, -16, 'Read single octet -16' );
}    #}}}

sub t050_read_double_octet : Test(2) {    #{{{

    my $hessian_double_octet_zero = "I\x{c8}\x{00}";    # should also be 0
    my $value = read_integer($hessian_double_octet_zero);
    is( $value, 0, 'Read double octet 0' );
    my $hessian_double_octet_data = "I\x{c7}\x{00}";    # should also be 0
    $value = read_integer($hessian_double_octet_data);
    is( $value, -256, 'Read double octet -256' );
}    #}}}

sub t060_read_triple_octet : Test(3) {    #{{{
    my $hessian_triple_octet_zero = "I\x{d4}\x{00}\x{00}";    # should also be 0
    my $value = read_integer($hessian_triple_octet_zero);
    is( $value, 0, 'Read double octet 0' );
    my $hessian_triple_octet_data = "I\x{d7}\x{ff}\x{ff}";    # should also be 0
    $value = read_integer($hessian_triple_octet_data);
    is( $value, 262143, 'Read double octet 262143 ' );

    $hessian_triple_octet_data = "I\x{d0}\x{00}\x{00}";       # should also be 0
    $value = read_integer($hessian_triple_octet_data);
    is( $value, -262144, 'Read double octet -262144 ' );
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::Integer - test for integer hessian conversion

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


