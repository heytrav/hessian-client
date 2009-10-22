#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't006.*|t007.*|t023.*';

use Test::Hessian::V2::Serializer;
Test::Hessian::V2::Serializer->runtests();
