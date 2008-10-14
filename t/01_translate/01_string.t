#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Test::More qw( no_plan );  

use Hessian::Translator ':to_hessian';

my $hessian_string = write_string_chunks("hello");
like(
    $hessian_string,
    qr/ S \x{00}\x{05} hello /xms,
    'Simple translation of string.'
);

my $hessian_xml = write_xml_chunks("<top>hello</top>");
like(
    $hessian_xml,
    qr/ X \x{00}\x{10}<top> hello <\/top> /xms,
    'Simple translation of xml'
);
