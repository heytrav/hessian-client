#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Test::More tests => 7; 

use Hessian::Translator::Numeric qw/:to_hessian :from_hessian/;
my $hessian_single_octet_long = write_long(0);

like(
    $hessian_single_octet_long,
    qr/ L \x{e0}/x,
    'Translate 0 into single octet'
);
$hessian_single_octet_long = write_long(15);

like(
    $hessian_single_octet_long,
    qr/ L \x{ef}/x,
    'Translate 15 into single octet'
);


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

my $hessian_single_octet_zero = "L\x{e0}";
my $value = read_long($hessian_single_octet_zero);
is($value, 0, 'Translated single octet 0');


my $hessian_double_octet_zero = "L\x{f8}\x{00}";
$value = read_long($hessian_double_octet_zero);
is($value, 0, 'Translated double octet 0');

$value = read_long("L\x{3c}\x{00}\x{00}");
is($value, 0, 'Translated triple octet 0');




