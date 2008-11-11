#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');


use Test::More tests => 1;
use Test::Deep;


use Hessian::Translator::List qw/:to_hessian :from_hessian/;


my $hessian_untyped_list = qr/ \x57 \x90 \x91 Z/x;


my $untyped_list = read_list($hessian_untyped_list);


cmp_deeply(
    $untyped_list,
    [ 0, 1],
    "deserialized expected datastructure"
);

