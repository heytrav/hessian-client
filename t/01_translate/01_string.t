#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw( no_plan );

use Hessian::Translator::String qw/:to_hessian :from_hessian/;
my $hessian_string = write_string("hello");

like(
    $hessian_string,
    qr/ S \x{00}\x{05} hello /xms,
    'Simple translation of string.'
);




