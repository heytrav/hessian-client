#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Hessian::Translator qw/:to_hessian :from_hessian/;

my $hessian_integer = "I" . write_quadruple_octet(300);
like(
    $hessian_integer,
    qr/
  I  \x{00} \x{00} \x{01} \x{2c}
/xms,
    'Simple translation of an integer'
);

$hessian_integer = write_integer(0);
like( $hessian_integer, qr/ I \x{90} /x, 'Translation of 0 in single octet' );

$hessian_integer = write_integer(-1);
like( $hessian_integer, qr/  I \x{8f}/x, 'Translation of -1 in single octet' );

$hessian_integer = write_integer(17);
like( $hessian_integer, qr/  I \x{a1} /x, 'Translation of 17 in single octet' );

$hessian_integer = "I" . write_double_octet(0);
like(
    $hessian_integer,
    qr/ I \x{c8} \x{00} /x,
    'Translation of 0 in double octet'
);

$hessian_integer = write_integer(-256);
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


$hessian_integer = "I" . write_triple_octet(0);
like(
    $hessian_integer,
    qr/ I \x{d4} \x{00} \x{00} /x,
    'Translation of 0 in triple octet'
);

$hessian_integer = write_integer(-262144);
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
