#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Test::More tests => 8;
use Hessian::Translator::Numeric qw/:from_hessian :to_hessian/;

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

my $hessian_double_octet_neg = "\x{5e}\x{80}\x{00}";
$value = read_double($hessian_double_octet_neg);
is( $value, -32768.0, "Read -32768.0" );

$hessian_string = write_double($value);
cmp_ok( $hessian_string, 'eq', $hessian_double_octet_neg,
    "Wrote -32768.0 back to the correct hessian code." );

my $hessian_real_double = "D\x40\x28\x80\x00\x00\x00\x00\x00";
$value = read_double($hessian_real_double);
is( $value, 12.25, "Read 12.25 in hessian" );

$hessian_string = write_double($value);
cmp_ok( $hessian_string, 'eq', $hessian_real_double,
    "Wrote -12.25 back to the correct hessian code." );

