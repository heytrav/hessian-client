#!/usr/bin/perl

use strict;
use warnings;


use Test::More qw( no_plan );
use Hessian::Translator qw/:to_hessian :from_hessian/;



my $hessian_integer = write_integer(300);
like(
    $hessian_integer,
    qr/
  I  \x{00} \x{00} \x{01} \x{2c}
/xms,
    'Simple translation of an integer'
);
