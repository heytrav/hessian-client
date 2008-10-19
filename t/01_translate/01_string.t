#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Test::More qw( no_plan );
use DateTime;
use DateTime::Format::Epoch::Unix;

use Hessian::Translator ':to_hessian';
use utf8;
my $hessian_string = write_string("hello");

like(
    $hessian_string,
    qr/ S \x{00}\x{05} hello /xms,
    'Simple translation of string.'
);




