#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't005_.*|t006_.*|t007_.*|t011_.*';

use Test::Hessian::V1::Serializer;
Test::Hessian::V1::Serializer->runtests();
